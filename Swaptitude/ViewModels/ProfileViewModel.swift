//
//  ProfileViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import Firebase

class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var selectedImage: UIImage?
    @Published var userBio = ""
    @Published var userName = ""
    @Published var profileImageUpdated = false
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    
    init(user: User? = nil) {
        self.currentUser = user
        
        if let user = user {
            self.userBio = user.bio ?? ""
            self.userName = user.fullName
            
            // Load existing profile image
            if let imagePath = user.profileImagePath,
               let image = ImageManager.shared.loadImage(fromPath: imagePath) {
                self.selectedImage = image
            }
        }
    }
    
    func updateProfile(completion: @escaping (Bool) -> Void) {
        guard let userId = currentUser?.id else {
            errorMessage = "User not logged in"
            showError = true
            completion(false)
            return
        }
        
        isLoading = true
        
        var updates: [String: Any] = [
            "fullName": userName,
            "bio": userBio
        ]
        
        // Handle image update
        if let newImage = selectedImage {
            if let imagePath = ImageManager.shared.saveImage(newImage, userId: userId) {
                // Delete old image if it exists
                if let oldPath = currentUser?.profileImagePath {
                    _ = ImageManager.shared.deleteImage(atPath: oldPath)
                }
                
                updates["profileImagePath"] = imagePath
                profileImageUpdated = true
            }
        } else if profileImageUpdated {
            // If image was removed
            updates["profileImagePath"] = nil
        }
        
        db.collection("users").document(userId).updateData(updates) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.showError = true
                completion(false)
            } else {
                // Update local user
                if let imagePath = updates["profileImagePath"] as? String {
                    self.currentUser?.profileImagePath = imagePath
                } else if updates["profileImagePath"] == nil {
                    self.currentUser?.profileImagePath = nil
                }
                self.currentUser?.fullName = self.userName
                self.currentUser?.bio = self.userBio
                
                // Notify that profile was updated
                NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
                
                completion(true)
            }
        }
    }
    
    func removeProfileImage() {
        // Delete the image from storage if it exists
        if let oldPath = currentUser?.profileImagePath {
            _ = ImageManager.shared.deleteImage(atPath: oldPath)
        }
        
        // Clear the selected image
        selectedImage = nil
        profileImageUpdated = true
    }
    
    func clearErrors() {
        errorMessage = ""
        showError = false
    }
}
