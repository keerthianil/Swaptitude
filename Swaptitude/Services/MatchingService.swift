//
//  MatchingService.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class MatchingService {
    static let shared = MatchingService()
    
    private let db = Firestore.firestore()
    
    func findPotentialMatches(
        forUserId userId: String,
        completion: @escaping ([SkillPost], Error?) -> Void
    ) {
        print("Finding potential matches for user: \(userId)")
        
        // First get the user's posts
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching user posts: \(error.localizedDescription)")
                    completion([], error)
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No posts found for user")
                    completion([], nil)
                    return
                }
                
                // Get the user's teach and learn skills
                let userPosts = documents.compactMap { try? $0.data(as: SkillPost.self) }
                print("User has \(userPosts.count) posts")
                
                // If no user posts, return empty
                if userPosts.isEmpty {
                    completion([], nil)
                    return
                }
                
                // Query all active posts
                self.db.collection("posts")
                    .whereField("isActive", isEqualTo: true)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error finding potential matches: \(error.localizedDescription)")
                            completion([], error)
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion([], nil)
                            return
                        }
                        
                        let allPosts = documents.compactMap { try? $0.data(as: SkillPost.self) }
                        // Filter out current user's posts
                        let otherUserPosts = allPosts.filter { $0.userId != userId }
                        
                        var potentialMatches: [SkillPost] = []
                        
                        // For each user post, find matching posts
                        for userPost in userPosts {
                            for otherPost in otherUserPosts {
                                // Check for both exact and category matches
                                let userTeach = userPost.teach.lowercased()
                                let userLearn = userPost.learn.lowercased()
                                let otherTeach = otherPost.teach.lowercased()
                                let otherLearn = otherPost.learn.lowercased()
                                
                                let exactMatch = userTeach == otherLearn && userLearn == otherTeach
                                let categoryMatch = userPost.teachCategory == otherPost.learnCategory &&
                                                  userPost.learnCategory == otherPost.teachCategory
                                
                                if exactMatch || categoryMatch {
                                    potentialMatches.append(otherPost)
                                }
                            }
                        }
                        
                        print("Found \(potentialMatches.count) potential matches before deduplication")
                        
                        // Remove duplicates based on post ID only, not user ID
                        var uniqueMatches: [SkillPost] = []
                        var uniquePostIds = Set<String>()
                        
                        for match in potentialMatches {
                            if let id = match.id, !uniquePostIds.contains(id) {
                                uniquePostIds.insert(id)
                                uniqueMatches.append(match)
                            }
                        }
                        
                        print("Found \(uniqueMatches.count) unique potential matches")
                        completion(uniqueMatches, nil)
                    }
            }
    }
   
    func createMatch(
        userPost: SkillPost,
        matchPost: SkillPost,
        completion: @escaping (Match?, Error?) -> Void
    ) {
        // Check if match already exists for these specific posts
        self.checkExistingMatchForPosts(userPostId: userPost.id ?? "", matchPostId: matchPost.id ?? "") { [weak self] exists, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            if exists {
                completion(nil, NSError(domain: "MatchService", code: 1, userInfo: [NSLocalizedDescriptionKey: "You already have a match for these specific skills"]))
                return
            }
            
            // Create new match
            let newMatch = Match(
                user1Id: userPost.userId,
                user2Id: matchPost.userId,
                user1Name: userPost.userName,
                user2Name: matchPost.userName,
                user1ProfileImageUrl: userPost.userProfileImagePath,
                user2ProfileImageUrl: matchPost.userProfileImagePath,
                user1Teach: userPost.teach,
                user1Learn: userPost.learn,
                user2Teach: matchPost.teach,
                user2Learn: matchPost.learn,
                createdAt: Date()
            )
            
            do {
                let reference = try self.db.collection("matches").addDocument(from: newMatch)
                
                // Get the created match with ID
                reference.getDocument { document, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let document = document else {
                        completion(nil, NSError(domain: "MatchService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get created match"]))
                        return
                    }
                    
                    do {
                        var match = try document.data(as: Match.self)
                        match.id = document.documentID
                        completion(match, nil)
                    } catch {
                        completion(nil, error)
                    }
                }
            } catch {
                completion(nil, error)
            }
        }
    }

    // helper method to check matches based on post IDs instead of user IDs
    private func checkExistingMatchForPosts(
        userPostId: String,
        matchPostId: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        completion(false, nil)  // Default to allowing the match
    }
    func unmatchUsers(matchId: String, completion: @escaping (Error?) -> Void) {
        // First delete all messages for this match
        print("Deleting messages for match: \(matchId)")
        ChatService.shared.deleteAllMessages(for: matchId) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error deleting messages: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            print("Successfully deleted messages for match: \(matchId)")
            
            // Now delete the match document
            self.db.collection("matches").document(matchId).delete { error in
                if let error = error {
                    print("Error deleting match: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                print("Successfully deleted match: \(matchId)")
                completion(nil)
            }
        }
    }
    // Check if a match already exists between two users
    private func checkExistingMatch(
        user1Id: String,
        user2Id: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        db.collection("matches")
            .whereField("user1Id", isEqualTo: user1Id)
            .whereField("user2Id", isEqualTo: user2Id)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false, error)
                    return
                }
                
                if let count = snapshot?.documents.count, count > 0 {
                    completion(true, nil)
                    return
                }
                
                // Check the reverse direction too
                self.db.collection("matches")
                    .whereField("user1Id", isEqualTo: user2Id)
                    .whereField("user2Id", isEqualTo: user1Id)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(false, error)
                            return
                        }
                        
                        if let count = snapshot?.documents.count, count > 0 {
                            completion(true, nil)
                            return
                        }
                        
                        completion(false, nil)
                    }
            }
    }
    
    // Get all matches for a user
    func getMatches(
        forUserId userId: String,
        completion: @escaping ([Match], Error?) -> Void
    ) {
        // Get matches where user is user1
        let query1 = db.collection("matches")
            .whereField("user1Id", isEqualTo: userId)
        
        // Get matches where user is user2
        let query2 = db.collection("matches")
            .whereField("user2Id", isEqualTo: userId)
        
        var allMatches: [Match] = []
        var completedQueries = 0
        
        // Execute the first query
        query1.getDocuments { snapshot, error in
            completedQueries += 1
            
            if let error = error {
                if completedQueries == 2 {
                    completion(allMatches, error)
                }
                return
            }
            
            if let documents = snapshot?.documents {
                let matches = documents.compactMap { try? $0.data(as: Match.self) }
                allMatches.append(contentsOf: matches)
            }
            
            if completedQueries == 2 {
                completion(allMatches, nil)
            }
        }
        
        // Execute the second query
        query2.getDocuments { snapshot, error in
            completedQueries += 1
            
            if let error = error {
                if completedQueries == 2 {
                    completion(allMatches, error)
                }
                return
            }
            
            if let documents = snapshot?.documents {
                let matches = documents.compactMap { try? $0.data(as: Match.self) }
                allMatches.append(contentsOf: matches)
            }
            
            if completedQueries == 2 {
                completion(allMatches, nil)
            }
        }
    }
}
