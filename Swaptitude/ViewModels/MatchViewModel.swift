//
//  MatchViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct MatchWithPostIds: Identifiable, Codable {
    @DocumentID var id: String?
    var user1Id: String
    var user2Id: String
    var user1Name: String
    var user2Name: String
    var user1ProfileImageUrl: String?
    var user2ProfileImageUrl: String?
    var user1Teach: String
    var user1Learn: String
    var user2Teach: String
    var user2Learn: String
    var createdAt: Date
    var lastMessage: String?
    var lastMessageDate: Date?
    var unreadCount: Int = 0
    var user1PostId: String
    var user2PostId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id
        case user2Id
        case user1Name
        case user2Name
        case user1ProfileImageUrl
        case user2ProfileImageUrl
        case user1Teach
        case user1Learn
        case user2Teach
        case user2Learn
        case createdAt
        case lastMessage
        case lastMessageDate
        case unreadCount
        case user1PostId
        case user2PostId
    }
    
    // Convert to standard Match object
    func toMatch() -> Match {
        return Match(
            id: id,
            user1Id: user1Id,
            user2Id: user2Id,
            user1Name: user1Name,
            user2Name: user2Name,
            user1ProfileImageUrl: user1ProfileImageUrl,
            user2ProfileImageUrl: user2ProfileImageUrl,
            user1Teach: user1Teach,
            user1Learn: user1Learn,
            user2Teach: user2Teach,
            user2Learn: user2Learn,
            createdAt: createdAt,
            lastMessage: lastMessage,
            lastMessageDate: lastMessageDate,
            unreadCount: unreadCount
        )
    }
}

class MatchViewModel: ObservableObject {
    @Published var potentialMatches: [SkillPost] = []
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showMatchSuccess = false
    @Published var newMatch: Match?

    
    // Keep track of valid users
    private var validUserIds = Set<String>()
    private let matchingService = MatchingService.shared
    private let db = Firestore.firestore()
    
    init() {
        fetchValidUsers()
    }
    
    // Fetch valid users from Firestore
    func fetchValidUsers() {
        print("Fetching valid users from Firestore...")
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.validUserIds = Set(documents.compactMap { $0.documentID })
                print("Found \(self.validUserIds.count) valid users")
            }
        }
    }
    

    func findPotentialMatches(highlightPostId: String? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            self.showError = true
            return
        }
        
        isLoading = true
        print("Finding potential matches for user: \(userId)")
        
        // Use existing index on userId + isActive
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    print("Error fetching user posts: \(error.localizedDescription)")
                    return
                }
                
                let userPosts = snapshot?.documents.compactMap { try? $0.data(as: SkillPost.self) } ?? []
                print("Found \(userPosts.count) user posts")
                
                if userPosts.isEmpty {
                    self.isLoading = false
                    self.potentialMatches = []
                    return
                }
                
                // Collect user's teach and learn categories
                var userTeachCategories = [String]()
                var userLearnCategories = [String]()
                
                for post in userPosts {
                    userTeachCategories.append(post.teachCategory)
                    userLearnCategories.append(post.learnCategory)
                }
                
                print("User teach categories: \(userTeachCategories)")
                print("User learn categories: \(userLearnCategories)")
                
                // Get all active posts from other users
                self.db.collection("posts")
                    .whereField("isActive", isEqualTo: true)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self else { return }
                        
                        if let error = error {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                            print("Error fetching all posts: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            self.isLoading = false
                            self.potentialMatches = []
                            return
                        }
                        
                        print("Found \(documents.count) total posts")
                        
                        // Filter out current user's posts and deleted users
                        var otherUserPosts = documents.compactMap { try? $0.data(as: SkillPost.self) }
                            .filter { post in
                                post.userId != userId && // Not current user
                                self.validUserIds.contains(post.userId) // User still exists
                            }
                        
                        print("Found \(otherUserPosts.count) posts from other users")
                        
                        // Filter out posts that are already matched
                        self.fetchMatches { matches in
                            // Get the post IDs from matches
                            var matchedPostIds = Set<String>()
                            for match in matches {
                                if let user1PostId = match.user1PostId, !user1PostId.isEmpty {
                                    matchedPostIds.insert(user1PostId)
                                }
                                if let user2PostId = match.user2PostId, !user2PostId.isEmpty {
                                    matchedPostIds.insert(user2PostId)
                                }
                            }
                            
                            // Filter out matched posts
                            otherUserPosts = otherUserPosts.filter { post in
                                guard let postId = post.id else { return true }
                                return !matchedPostIds.contains(postId)
                            }
                            
                            // Find matches based on category
                            var potentialMatches: [SkillPost] = []
                            
                            for userPost in userPosts {
                                for otherPost in otherUserPosts {
                                    // Match by category
                                    if userPost.teachCategory == otherPost.learnCategory &&
                                       userPost.learnCategory == otherPost.teachCategory {
                                        potentialMatches.append(otherPost)
                                    }
                                }
                            }
                            
                            print("Found \(potentialMatches.count) potential matches before deduplication")
                            
                            // Remove duplicates
                            var uniquePostIds = Set<String>()
                            self.potentialMatches = potentialMatches.filter { post in
                                guard let id = post.id else { return false }
                                if uniquePostIds.contains(id) {
                                    return false
                                }
                                uniquePostIds.insert(id)
                                return true
                            }
                            
                            // If we have a highlighted post ID, make sure it's at the top of the list
                            if let highlightId = highlightPostId, !highlightId.isEmpty {
                                if let index = self.potentialMatches.firstIndex(where: { $0.id == highlightId }) {
                                    let highlightedPost = self.potentialMatches.remove(at: index)
                                    self.potentialMatches.insert(highlightedPost, at: 0)
                                }
                            }
                            
                            self.isLoading = false
                            print("Final potential matches count: \(self.potentialMatches.count)")
                        }
                    }
            }
    }

    // function to fetch matches to check for already matched posts
    func fetchMatches(completion: @escaping ([Match]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var allMatches: [Match] = []
        
        // Get matches where user is user1
        group.enter()
        db.collection("matches")
            .whereField("user1Id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let documents = snapshot?.documents {
                    let matches = documents.compactMap { try? $0.data(as: Match.self) }
                    allMatches.append(contentsOf: matches)
                }
            }
        
        // Get matches where user is user2
        group.enter()
        db.collection("matches")
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let documents = snapshot?.documents {
                    let matches = documents.compactMap { try? $0.data(as: Match.self) }
                    allMatches.append(contentsOf: matches)
                }
            }
        
        group.notify(queue: .main) {
            completion(allMatches)
        }
    }
   
    func createMatch(with post: SkillPost) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            self.showError = true
            return
        }
        
        isLoading = true
        
        // Find a matching user post
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                let userPosts = snapshot?.documents.compactMap { try? $0.data(as: SkillPost.self) } ?? []
                
                // Find a matching post based on categories
                let matchingPosts = userPosts.filter { userPost in
                    userPost.teachCategory == post.learnCategory &&
                    userPost.learnCategory == post.teachCategory
                }
                
                guard let userPost = matchingPosts.first else {
                    self.isLoading = false
                    self.errorMessage = "No matching post found"
                    self.showError = true
                    return
                }
                
                // Create match
                let match = Match(
                    user1Id: userId,
                    user2Id: post.userId,
                    user1Name: userPost.userName,
                    user2Name: post.userName,
                    user1ProfileImageUrl: userPost.userProfileImagePath,
                    user2ProfileImageUrl: post.userProfileImagePath,
                    user1Teach: userPost.teach,
                    user1Learn: userPost.learn,
                    user2Teach: post.teach,
                    user2Learn: post.learn,
                    createdAt: Date(),
                    user1PostId: userPost.id,
                    user2PostId: post.id
                )
                
                // Store in Firestore
                do {
                    let docRef = try self.db.collection("matches").addDocument(from: match)
                    
                    docRef.getDocument { document, error in
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                            return
                        }
                        
                        if let document = document,
                           let match = try? document.data(as: Match.self) {
                            // Create notification for both users
                            self.createMatchNotifications(
                                matchId: document.documentID,
                                currentUserId: userId,
                                currentUserName: userPost.userName,
                                otherUserId: post.userId,
                                otherUserName: post.userName
                            )
                            
                            // Show match notification
                            self.newMatch = match
                            self.showMatchSuccess = true
                            
                            // Add local notification
                            NotificationManager.shared.scheduleMatchNotification(matchName: post.userName)
                            
                            // Remove from potential matches list
                            if let index = self.potentialMatches.firstIndex(where: { $0.id == post.id }) {
                                self.potentialMatches.remove(at: index)
                            }
                            
                            // Refresh matches
                            self.fetchMatches()
                        }
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
    }

    // Add this helper method
    private func createMatchNotifications(matchId: String, currentUserId: String, currentUserName: String, otherUserId: String, otherUserName: String) {
        // Create notification for the current user
        let notification1 = [
            "userId": currentUserId,
            "type": "newMatch",
            "title": "New Match!",
            "message": "You matched with \(otherUserName). Start a conversation!",
            "relatedId": matchId,
            "isRead": false,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        // Create notification for the other user
        let notification2 = [
            "userId": otherUserId,
            "type": "newMatch",
            "title": "New Match!",
            "message": "You matched with \(currentUserName). Start a conversation!",
            "relatedId": matchId,
            "isRead": false,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        // Add both notifications
        db.collection("notifications").addDocument(data: notification1)
        db.collection("notifications").addDocument(data: notification2)
    }
    
    func unmatchUsers(matchId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        print("Starting unmatch process for matchId: \(matchId)")
        
        MatchingService.shared.unmatchUsers(matchId: matchId) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                completion(false)
                return
            }
            
            // Remove the match from local array
            if let index = self.matches.firstIndex(where: { $0.id == matchId }) {
                self.matches.remove(at: index)
            }
            
            print("Match successfully deleted: \(matchId)")
            completion(true)
        }
    }
    private func deleteMessagesForMatch(matchId: String, completion: @escaping (Bool) -> Void) {
        print("Deleting messages for match ID: \(matchId)")
        
        db.collection("chatMessages")
            .whereField("matchId", isEqualTo: matchId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("Error getting messages to delete: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No messages found to delete")
                    completion(true)
                    return
                }
                
                print("Found \(documents.count) messages to delete")
                
                if documents.isEmpty {
                    completion(true)
                    return
                }
                
                let batch = self.db.batch()
                
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting messages: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Successfully deleted \(documents.count) messages")
                        completion(true)
                    }
                }
            }
    }
    
    func fetchMatches() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            self.showError = true
            return
        }
        
        isLoading = true
        
        // Get matches where user is user1 or user2
        let group = DispatchGroup()
        var allMatches: [Match] = []
        
        // First query - user as user1
        group.enter()
        db.collection("matches")
            .whereField("user1Id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                if let documents = snapshot?.documents {
                    // Try first to parse with post IDs
                    let matchesWithPostIds = documents.compactMap { try? $0.data(as: MatchWithPostIds.self) }
                    let convertedMatches = matchesWithPostIds.map { $0.toMatch() }
                    
                    // If no matches with post IDs, try regular Match
                    if matchesWithPostIds.isEmpty {
                        let regularMatches = documents.compactMap { try? $0.data(as: Match.self) }
                        allMatches.append(contentsOf: regularMatches)
                    } else {
                        allMatches.append(contentsOf: convertedMatches)
                    }
                }
            }
        
        // Second query - user as user2
        group.enter()
        db.collection("matches")
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                if let documents = snapshot?.documents {
                    // Try first to parse with post IDs
                    let matchesWithPostIds = documents.compactMap { try? $0.data(as: MatchWithPostIds.self) }
                    let convertedMatches = matchesWithPostIds.map { $0.toMatch() }
                    
                    // If no matches with post IDs, try regular Match
                    if matchesWithPostIds.isEmpty {
                        let regularMatches = documents.compactMap { try? $0.data(as: Match.self) }
                        allMatches.append(contentsOf: regularMatches)
                    } else {
                        allMatches.append(contentsOf: convertedMatches)
                    }
                }
            }
        
        // Process results when both queries complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // Filter out matches with deleted users
            let validMatches = allMatches.filter { match in
                self.validUserIds.contains(match.user1Id) &&
                self.validUserIds.contains(match.user2Id)
            }
            
            // Sort by creation date (newest first)
            self.matches = validMatches.sorted(by: { $0.createdAt > $1.createdAt })
            
            // Clean up any invalid matches
            self.cleanUpInvalidMatches(validMatches: validMatches, allMatches: allMatches)
        }
    }
    
    // Clean up matches with deleted users or posts
    private func cleanUpInvalidMatches(validMatches: [Match], allMatches: [Match]) {
        let invalidMatches = allMatches.filter { match in
            !validMatches.contains { $0.id == match.id }
        }
        
        if invalidMatches.isEmpty { return }
        
        let batch = db.batch()
        
        for match in invalidMatches {
            if let id = match.id {
                batch.deleteDocument(db.collection("matches").document(id))
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error cleaning up invalid matches: \(error.localizedDescription)")
            } else {
                print("Successfully cleaned up \(invalidMatches.count) invalid matches")
            }
        }
    }
    
    // Function to check if a post matches a current user's post based on CATEGORY ONLY
    func isPostCategoryMatchingUserPosts(post: SkillPost) -> Bool {
        // Fetch user posts first to compare
        var userPosts: [SkillPost] = []
        
        db.collection("posts")
            .whereField("userId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    userPosts = documents.compactMap { try? $0.data(as: SkillPost.self) }
                }
            }
        
        for userPost in userPosts {
            // Only check category match, not skill name
            let categoryMatch =
                userPost.teachCategory == post.learnCategory &&
                userPost.learnCategory == post.teachCategory
            
            if categoryMatch {
                return true
            }
        }
        return false
    }
    
    func isAlreadyMatched(with post: SkillPost) -> Bool {
        guard let userId = Auth.auth().currentUser?.uid,
              let postId = post.id else {
            return false
        }
        
        // Check if there's already a match between these users
        for match in matches {
            // Check user IDs
            if (match.user1Id == userId && match.user2Id == post.userId) ||
               (match.user1Id == post.userId && match.user2Id == userId) {
                // This is a match between these users
                return true
            }
            
            // Check post IDs if available
            if let user1PostId = match.user1PostId,
               let user2PostId = match.user2PostId,
               (user1PostId == postId || user2PostId == postId) {
                return true
            }
        }
        
        return false
    }
   
    func getMatchById(matchId: String, completion: @escaping (Match?) -> Void) {
        db.collection("matches").document(matchId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching match: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = snapshot, document.exists else {
                completion(nil)
                return
            }
            
            do {
                let match = try document.data(as: Match.self)
                completion(match)
            } catch {
                print("Error decoding match: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
  
    func getSkillBeeMatchSuggestions(match: Match) -> [String] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        let teachSkill = match.otherUserTeach(currentUserId: currentUserId)
        
        // Get appropriate category
        var category = "default"
        if let post = getMatchPost(match: match), !post.teachCategory.isEmpty {
            category = post.teachCategory
        }
        
        // Get suggestions from SkillBee model
        let skillBeeModel = SkillBeeModel()
        var starters = skillBeeModel.getConversationStarters(for: category)
        
        // Add personalized messages
        starters.append("I'm excited to learn \(teachSkill) from you!")
        starters.append("Have you been teaching \(teachSkill) for long?")
        
        return starters
    }

    // Helper to get the skill post related to the match
    private func getMatchPost(match: Match) -> SkillPost? {
        // This function would retrieve the post related to this match
        // For now, just return nil as placeholder
        return nil
    }
   
    func getConversationStarters(for match: Match) -> [String] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        let teachSkill = match.otherUserTeach(currentUserId: currentUserId)
        let learnSkill = match.otherUserLearn(currentUserId: currentUserId)
        let otherUserName = match.otherUserName(currentUserId: currentUserId)
        
        // Determine the skill category for more targeted suggestions
        var category = "default"
        if let teachCategory = SkillCategories.categories.first(where: { $0.name.lowercased().contains(teachSkill.lowercased()) })?.id {
            category = teachCategory
        }
        
        // Get general suggestions from SkillBee model
        let skillBeeModel = SkillBeeModel()
        var starters = skillBeeModel.getConversationStarters(for: category)
        
        // Add personalized messages based on the match context
        starters.append("Hi \(otherUserName), I'm excited to learn \(teachSkill) from you!")
        starters.append("Have you been teaching \(teachSkill) for long?")
        starters.append("I can help you learn \(learnSkill). What aspects are you most interested in?")
        starters.append("Would you prefer to meet in person or online for our skill exchange?")
        starters.append("What days/times work best for you to exchange skills?")
        starters.append("Do you have any specific goals you want to achieve with \(learnSkill)?")
        starters.append("I'm curious what got you interested in learning \(learnSkill)?")
        
        return starters
    }
   
}
