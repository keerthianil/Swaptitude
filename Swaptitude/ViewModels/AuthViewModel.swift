//
//  AuthViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showSignOutAlert = false
    @Published var successMessage = ""
    @Published var showSuccess = false
    
    init() {
        self.userSession = Auth.auth().currentUser
        self.fetchUser()
        self.setupProfileUpdateListener()
    }
    
    func signIn(withEmail email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }
            
            self.userSession = result?.user
            self.fetchUser()
        }
    }
    
    func signUp(withEmail email: String, password: String, fullName: String, username: String) {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }
            
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "An unknown error occurred"
                self.showError = true
                return
            }
            
            self.userSession = user
            
            let newUser = User(
                id: user.uid,
                email: email,
                fullName: fullName,
                username: username.lowercased(),
                isVerified: false,
                createdAt: Date()
            )
            
            let encodedUser = try? Firestore.Encoder().encode(newUser)
            
            // Create the user document with retry logic
            self.createUserWithRetry(user: user, userData: encodedUser ?? [:], retryCount: 3)
        }
    }

    private func createUserWithRetry(user: FirebaseAuth.User, userData: [String: Any], retryCount: Int) {
        Firestore.firestore().collection("users").document(user.uid).setData(userData) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                if retryCount > 0 {
                    print("Error creating user document, retrying (\(retryCount) attempts left): \(error.localizedDescription)")
                    // Wait a bit before retrying
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.createUserWithRetry(user: user, userData: userData, retryCount: retryCount - 1)
                    }
                } else {
                    self.errorMessage = "Failed to create user after multiple attempts: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
            } else {
                // Success! Update the local currentUser
                if let encodedUser = userData as? [String: Any],
                   let newUser = try? Firestore.Decoder().decode(User.self, from: encodedUser) {
                    self.currentUser = newUser
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.successMessage = "Signed out successfully!"
            self.showSuccess = true
            // Clear any error messages
            self.errorMessage = ""
            self.showError = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }

    
  
    func fetchUser() {
        guard let uid = userSession?.uid else { return }
        
        ensureUserExists { exists in
            if !exists {
                print("Warning: User exists in Auth but not in Firestore")
                // Handle this case - perhaps recreate the Firestore document?
                return
            }
            
            Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                if let user = try? snapshot.data(as: User.self) {
                    self.currentUser = user
                }
            }
        }
    }
    
    func sendEmailVerification(completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        clearErrors()
        guard let user = Auth.auth().currentUser else {
            completion(false, "No user logged in")
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            completion(true, nil)
        }
    }
    
    func checkIfEmailVerified(completion: @escaping (Bool) -> Void) {
        isLoading = true
        clearErrors()
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // Reload user to get the latest verification status
        user.reload { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                completion(false)
                return
            }
            
            if user.isEmailVerified {
                // Update Firestore as well
                Firestore.firestore().collection("users").document(user.uid).updateData([
                    "isVerified": true
                ]) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        completion(false)
                        return
                    }
                    
                    // Update local user
                    self.currentUser?.isVerified = true
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func resetPassword(withEmail email: String) {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                return
            }
        }
    }
    
    func updateUserProfile(fullName: String, bio: String, profileImage: UIImage?, completion: @escaping (Bool) -> Void) {
        guard let userId = userSession?.uid else {
            errorMessage = "User not logged in"
            showError = true
            completion(false)
            return
        }
        
        isLoading = true
        
        var updates: [String: Any] = [
            "fullName": fullName,
            "bio": bio
        ]
        
        // Handle image update
        if let newImage = profileImage {
            if let imagePath = ImageManager.shared.saveImage(newImage, userId: userId) {
                // Delete old image if it exists
                if let oldPath = currentUser?.profileImagePath {
                    _ = ImageManager.shared.deleteImage(atPath: oldPath)
                }
                
                updates["profileImagePath"] = imagePath
            }
        }
        
        Firestore.firestore().collection("users").document(userId).updateData(updates) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                completion(false)
                return
            }
            
            // Update local user
            self.currentUser?.fullName = fullName
            self.currentUser?.bio = bio
            if let imagePath = updates["profileImagePath"] as? String {
                self.currentUser?.profileImagePath = imagePath
            }
            
            completion(true)
        }
    }
    
    func setupProfileUpdateListener() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ProfileUpdated"), object: nil, queue: .main) { [weak self] _ in
            self?.fetchUser()
        }
    }
    
    func clearErrors() {
        self.errorMessage = ""
        self.showError = false
    }
    
    // MARK: - Account Deletion

    func deleteAccountWithReauth(password: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email, let userId = user.uid as String? else {
            completion(NSError(domain: "AuthViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in or no email found"]))
            return
        }
        
        print("Starting complete account deletion for user: \(userId)")
        self.isLoading = true
        
        // 1. Re-authenticate user first
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reauthentication failed: \(error.localizedDescription)")
                self.isLoading = false
                completion(error)
                return
            }
            
            print("Reauthentication successful, proceeding with deletion")
            
            // 2. First delete all the user's posts
            self.deleteAllUserPosts(userId: userId) {
                // 3. Then delete all matches involving this user
                self.deleteAllUserMatches(userId: userId) {
                    // 4. Mark reviews as from deleted user instead of deleting them
                    self.markUserReviewsAsDeleted(userId: userId) {
                        // 5. Delete user document from Firestore
                        self.deleteUserDocument(userId: userId) {
                            // 6. Finally delete the user from Firebase Auth
                            self.deleteUserFromAuth(user: user) { error in
                                self.isLoading = false
                                
                                if let error = error {
                                    completion(error)
                                } else {
                                    // Clear local session
                                    self.userSession = nil
                                    self.currentUser = nil
                                    
                                    // Set success message
                                    self.successMessage = "Account successfully deleted"
                                    self.showSuccess = true
                                    
                                    completion(nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func markUserReviewsAsDeleted(userId: String, completion: @escaping () -> Void) {
        print("Marking reviews from user \(userId) as deleted")
        let db = Firestore.firestore()
        
        // Get reviews authored by this user
        db.collection("reviews").whereField("authorId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding authored reviews: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No authored reviews found")
                completion()
                return
            }
            
            print("Found \(documents.count) authored reviews to mark as deleted")
            
            // Create a batch update
            let batch = db.batch()
            
            for document in documents {
                batch.updateData([
                    "isAuthorDeleted": true,
                    "authorName": "Deleted User"
                ], forDocument: document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error updating reviews: \(error.localizedDescription)")
                } else {
                    print("Successfully marked all authored reviews as deleted")
                }
                completion()
            }
        }
    }
    // Helper to delete all user's posts
    private func deleteAllUserPosts(userId: String, completion: @escaping () -> Void) {
        print("Deleting all posts for user: \(userId)")
        let db = Firestore.firestore()
        
        db.collection("posts").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                print("Error finding user posts: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No posts found for user")
                completion()
                return
            }
            
            print("Found \(documents.count) posts to delete")
            let batch = db.batch()
            
            for document in documents {
                print("Adding post \(document.documentID) to deletion batch")
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error deleting user posts: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted all user posts")
                }
                completion()
            }
        }
    }
    
    // Helper to delete all user's matches
    private func deleteAllUserMatches(userId: String, completion: @escaping () -> Void) {
        print("Deleting all matches for user: \(userId)")
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        // Delete matches where user is user1
        group.enter()
        db.collection("matches").whereField("user1Id", isEqualTo: userId).getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error finding user1 matches: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No user1 matches found")
                return
            }
            
            print("Found \(documents.count) user1 matches to delete")
            let batch = db.batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error deleting user1 matches: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted all user1 matches")
                }
            }
        }
        
        // Delete matches where user is user2
        group.enter()
        db.collection("matches").whereField("user2Id", isEqualTo: userId).getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                print("Error finding user2 matches: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No user2 matches found")
                return
            }
            
            print("Found \(documents.count) user2 matches to delete")
            let batch = db.batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error deleting user2 matches: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted all user2 matches")
                }
            }
        }
        
        // When all match deletions are complete
        group.notify(queue: .main) {
            print("All match deletion operations complete")
            completion()
        }
    }
    
   
    
    // Helper to delete the user document
    private func deleteUserDocument(userId: String, completion: @escaping () -> Void) {
        print("Deleting user document: \(userId)")
        
        Firestore.firestore().collection("users").document(userId).delete { error in
            if let error = error {
                print("Error deleting user document: \(error.localizedDescription)")
            } else {
                print("Successfully deleted user document")
                
                // Also delete user profile image if exists
                if let profileImagePath = self.currentUser?.profileImagePath {
                    _ = ImageManager.shared.deleteImage(atPath: profileImagePath)
                    print("Deleted user profile image")
                }
            }
            
            completion()
        }
    }
    
    // Helper to delete the user from Firebase Auth
        private func deleteUserFromAuth(user: FirebaseAuth.User, completion: @escaping (Error?) -> Void) {
            print("Deleting user from Firebase Auth")
            
            user.delete { error in
                if let error = error {
                    print("Error deleting user from Auth: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("Successfully deleted user from Firebase Auth")
                    completion(nil)
                }
            }
        }
   
    func ensureUserExists(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        // Reload the user to ensure we have the latest data
        user.reload { error in
            if let error = error {
                print("Error reloading user: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Check if the user exists in Firestore
            Firestore.firestore().collection("users").document(user.uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error checking user existence: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                completion(snapshot?.exists ?? false)
            }
        }
    }
}
