//
//  PostViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class PostViewModel: ObservableObject {
    @Published var userPosts: [SkillPost] = []
    @Published var allPosts: [SkillPost] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    // Keep track of valid users
    private var validUserIds = Set<String>()
    private let db = Firestore.firestore()
    
    init() {
        // Fetch valid users first
        fetchValidUsers()
    }
    
    // MARK: - User Management
    
    func fetchValidUsers() {
        print("Fetching valid users from Firestore...")
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching users from Firestore: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.validUserIds = Set(documents.compactMap { $0.documentID })
                print("Found \(self.validUserIds.count) valid users in Firestore")
                
                // Now fetch posts with valid users
                self.fetchAllPosts()
                self.cleanUpDeletedUserPosts()
            }
        }
    }
    
    // MARK: - Create Posts
    
    func createPostWithCategory(
        teach: String,
        teachCategory: String,
        teachProficiency: String,
        learn: String,
        learnCategory: String,
        description: String,
        location: String?,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "You must be logged in to create a post"
            self.showError = true
            completion(false)
            return
        }
        
        print("Creating post with category for user: \(userId)")
        isLoading = true
        errorMessage = ""
        
        // Normalize skills to lowercase
        let normalizedTeach = teach.lowercased()
        let normalizedLearn = learn.lowercased()
        
        // Get user info
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                }
                return
            }
            
            guard let snapshot = snapshot, let userData = try? snapshot.data(as: User.self) else {
                print("Could not parse user data")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Could not get user data"
                    self.showError = true
                    completion(false)
                }
                return
            }
            
            print("Creating new post for user: \(userData.fullName)")
            
            // Create a dictionary for the post
            let postData: [String: Any] = [
                "userId": userId,
                "userName": userData.fullName,
                "userProfileImagePath": userData.profileImagePath as Any,
                "teach": normalizedTeach,
                "teachCategory": teachCategory,
                "teachProficiency": teachProficiency,
                "learn": normalizedLearn,
                "learnCategory": learnCategory,
                "description": description,
                "location": location as Any,
                "createdAt": Timestamp(date: Date()),
                "isActive": true
            ]
            
            print("Attempting to add post to Firestore")
            self.db.collection("posts").addDocument(data: postData) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error creating post: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        completion(false)
                        return
                    }
                    
                    print("Post created successfully!")
                    self.successMessage = "Post created successfully! Note: Posts cannot be edited after creation."
                    self.showSuccess = true
                    
                    // Refresh posts data
                    self.fetchUserPosts()
                    self.fetchAllPosts()
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Fetch Posts
    
    func fetchUserPosts(completion: ((Bool) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Cannot fetch user posts: No user logged in")
            completion?(false)
            return
        }
        
        isLoading = true
        print("Fetching posts for user: \(userId)")
        
        // Get all posts for the current user
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    print("Self is nil in fetchUserPosts completion")
                    completion?(false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error fetching user posts: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        completion?(false)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found for user posts")
                        self.userPosts = []
                        completion?(true)
                        return
                    }
                    
                    print("Found \(documents.count) user posts")
                    
                    // Parse posts
                    var posts: [SkillPost] = []
                    for document in documents {
                        do {
                            var post = try document.data(as: SkillPost.self)
                            post.id = document.documentID // Ensure ID is set
                            posts.append(post)
                            print("Successfully parsed post: \(post.id ?? "unknown")")
                        } catch {
                            print("Error parsing post: \(error)")
                        }
                    }
                    
                    self.userPosts = posts
                    print("Successfully processed \(self.userPosts.count) user posts")
                    completion?(true)
                }
            }
    }
    
    func fetchAllPosts() {
        isLoading = true
        print("Fetching all posts from Firestore")
        
        // Get all posts, we'll filter later
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error fetching all posts: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found for all posts")
                        self.allPosts = []
                        return
                    }
                    
                    print("Found \(documents.count) total posts")
                    
                    // Parse posts and filter out posts from deleted users
                    var posts: [SkillPost] = []
                    for document in documents {
                        do {
                            var post = try document.data(as: SkillPost.self)
                            post.id = document.documentID
                            
                            // Check if user exists before including the post
                            if self.validUserIds.contains(post.userId) {
                                posts.append(post)
                            } else {
                                print("Filtering out post from deleted user: \(post.userId)")
                                // Automatically delete posts from deleted users
                                self.db.collection("posts").document(document.documentID).delete { error in
                                    if let error = error {
                                        print("Error cleaning up deleted user post: \(error.localizedDescription)")
                                    } else {
                                        print("Successfully removed post from deleted user")
                                    }
                                }
                            }
                        } catch {
                            print("Error parsing post in fetchAllPosts: \(error)")
                        }
                    }
                    
                    self.allPosts = posts
                    print("Displaying \(self.allPosts.count) posts after filtering deleted users")
                }
            }
    }
    
    // MARK: - Delete Posts
    func deletePost(postId: String?) {
          print("Starting post deletion for ID: \(postId ?? "unknown")")
          guard let postId = postId else {
              self.errorMessage = "Invalid post ID"
              self.showError = true
              return
          }
          
          isLoading = true
          
          // First, get the post to determine the user ID
          db.collection("posts").document(postId).getDocument { [weak self] document, error in
              guard let self = self else { return }
              
              if let error = error {
                  self.isLoading = false
                  self.errorMessage = "Error retrieving post: \(error.localizedDescription)"
                  self.showError = true
                  return
              }
              
              // Safely unwrap the document
              guard let document = document, document.exists else {
                  self.isLoading = false
                  self.errorMessage = "Post not found"
                  self.showError = true
                  return
              }
              
              // Extract the userId directly from the document data
              guard let userId = document.data()?["userId"] as? String else {
                  self.isLoading = false
                  self.errorMessage = "Invalid post data"
                  self.showError = true
                  return
              }
              
              // Now find all matches where this user is involved
              let dispatchGroup = DispatchGroup()
              var matchesToDelete: [String] = []
              
              // Use your existing indexes for user1Id and user2Id
              dispatchGroup.enter()
              self.db.collection("matches")
                  .whereField("user1Id", isEqualTo: userId)
                  .getDocuments { snapshot, error in
                      defer { dispatchGroup.leave() }
                      
                      if let documents = snapshot?.documents {
                          for doc in documents {
                              matchesToDelete.append(doc.documentID)
                              print("Found match to delete (user1Id): \(doc.documentID)")
                          }
                      }
                  }
              
              dispatchGroup.enter()
              self.db.collection("matches")
                  .whereField("user2Id", isEqualTo: userId)
                  .getDocuments { snapshot, error in
                      defer { dispatchGroup.leave() }
                      
                      if let documents = snapshot?.documents {
                          for doc in documents {
                              matchesToDelete.append(doc.documentID)
                              print("Found match to delete (user2Id): \(doc.documentID)")
                          }
                      }
                  }
              
              // After finding all matches, delete them first, then delete the post
              dispatchGroup.notify(queue: .main) { [weak self] in
                  guard let self = self else { return }
                  
                  if matchesToDelete.isEmpty {
                      print("No matches found to delete with post: \(postId)")
                      // No matches found, just delete the post
                      self.performPostDeletion(postId: postId)
                  } else {
                      print("Found \(matchesToDelete.count) matches to delete with post: \(postId)")
                      // Delete all matches first
                      self.batchDeleteMatches(matchIds: matchesToDelete) { success in
                          if success {
                              print("Successfully deleted \(matchesToDelete.count) matches")
                              // Now delete the post
                              self.performPostDeletion(postId: postId)
                          } else {
                              self.isLoading = false
                              self.errorMessage = "Failed to delete related matches"
                              self.showError = true
                          }
                      }
                  }
              }
          }
      }
    // Helper method to batch delete matches
    private func batchDeleteMatches(matchIds: [String], completion: @escaping (Bool) -> Void) {
        if matchIds.isEmpty {
            completion(true)
            return
        }
        
        let batch = db.batch()
        
        for matchId in matchIds {
            let matchRef = db.collection("matches").document(matchId)
            batch.deleteDocument(matchRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error batch deleting matches: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Successfully batch deleted matches")
                completion(true)
            }
        }
    }
   

    private func performPostDeletion(postId: String) {
        // First find all matches related to this post
        print("Looking for matches associated with post: \(postId)")
        var matchesToDelete: [String] = []
        let dispatchGroup = DispatchGroup()
        
        // Search for matches where this post is user1PostId
        dispatchGroup.enter()
        db.collection("matches")
            .whereField("user1PostId", isEqualTo: postId)
            .getDocuments { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if let documents = snapshot?.documents {
                    for doc in documents {
                        print("Found match to delete (user1PostId): \(doc.documentID)")
                        matchesToDelete.append(doc.documentID)
                    }
                }
            }
        
        // Search for matches where this post is user2PostId
        dispatchGroup.enter()
        db.collection("matches")
            .whereField("user2PostId", isEqualTo: postId)
            .getDocuments { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if let documents = snapshot?.documents {
                    for doc in documents {
                        print("Found match to delete (user2PostId): \(doc.documentID)")
                        matchesToDelete.append(doc.documentID)
                    }
                }
            }
        
        // After finding all affected matches
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if !matchesToDelete.isEmpty {
                // Create alert to notify user
                let alert = UIAlertController(
                    title: "Delete Post",
                    message: "This will also delete \(matchesToDelete.count) related match(es) and all associated messages. Continue?",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    self.isLoading = false
                })
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    self.deleteMatchesAndMessages(matchIds: matchesToDelete, postId: postId)
                })
                
                // Present the alert
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(alert, animated: true)
                }
            } else {
                // No matches to delete, just delete the post
                self.finalizePostDeletion(postId: postId)
            }
        }
    }

    private func deleteMatchesAndMessages(matchIds: [String], postId: String) {
        let totalToDelete = matchIds.count
        var completedDeletions = 0
        
        for matchId in matchIds {
            // First delete all chat messages for this match
            print("Deleting messages for match: \(matchId)")
            ChatService.shared.deleteAllMessages(for: matchId) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error deleting messages for match: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted messages for match \(matchId)")
                }
                
                // Now delete the match
                self.db.collection("matches").document(matchId).delete { error in
                    completedDeletions += 1
                    
                    if let error = error {
                        print("Error deleting match: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted match: \(matchId)")
                    }
                    
                    // If all matches have been processed, delete the post
                    if completedDeletions == totalToDelete {
                        self.finalizePostDeletion(postId: postId)
                    }
                }
            }
        }
    }
    // Add this helper function to PostViewModel.swift
    private func finalizePostDeletion(postId: String) {
        // Finally delete the post itself
        self.db.collection("posts").document(postId).delete { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error deleting post: \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                print("Post successfully deleted!")
                
                // Remove from local arrays
                self.userPosts.removeAll { $0.id == postId }
                self.allPosts.removeAll { $0.id == postId }
                
                // Show success message
                self.successMessage = "Post deleted successfully!"
                self.showSuccess = true
            }
        }
    }
    // MARK: - Post Cleanup and Filtering
    
    // Function to clean up posts from deleted users
    func cleanUpDeletedUserPosts() {
        print("Starting cleanup of posts from deleted users")
        
        // Make sure we have valid users
        if validUserIds.isEmpty {
            fetchValidUsers()
            return
        }
        
        // Get all posts
        db.collection("posts").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching posts for cleanup: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let batch = self.db.batch()
            var postsToDelete = 0
            
            for document in documents {
                if let userId = document.data()["userId"] as? String,
                   !self.validUserIds.contains(userId) {
                    // This post belongs to a deleted user - delete it
                    batch.deleteDocument(document.reference)
                    postsToDelete += 1
                }
            }
            
            if postsToDelete > 0 {
                batch.commit { error in
                    if let error = error {
                        print("Error deleting posts from deleted users: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted \(postsToDelete) posts from deleted users")
                        // Refresh posts
                        self.fetchAllPosts()
                    }
                }
            } else {
                print("No posts from deleted users found to clean up")
            }
        }
    }
    
    // Function to check if a post matches a current user's post based on CATEGORY ONLY
    func isPostCategoryMatchingUserPosts(post: SkillPost) -> Bool {
        // First check if user still exists
        if !validUserIds.contains(post.userId) {
            return false
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
}
