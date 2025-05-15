//
//  EditProfileView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: ProfileViewModel
    @State private var showImagePicker = false
    @State private var showRemoveConfirmation = false
    @State private var showSuccessAlert = false
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile image selector
                VStack {
                    ZStack {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else if let profileImagePath = viewModel.currentUser?.profileImagePath,
                                  let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 110, height: 110)
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .offset(x: 40, y: 40)
                        
                        if (viewModel.selectedImage != nil) ||
                            (viewModel.currentUser?.profileImagePath != nil &&
                             ImageManager.shared.loadImage(fromPath: viewModel.currentUser?.profileImagePath ?? "") != nil) {
                            Button(action: {
                                showRemoveConfirmation = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "trash")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 40, y: 80)
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Form fields
                VStack(spacing: 20) {
                    FormField(title: "Full Name", text: $viewModel.userName, icon: "person")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $viewModel.userBio)
                            .frame(height: 150)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.secondaryBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                            )
                    }
                    
                    if viewModel.showError && !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Save Changes button
                Button(action: {
                    // Set loading state to prevent double clicks
                    viewModel.isLoading = true
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Save changes
                    viewModel.updateProfile { success in
                        viewModel.isLoading = false
                        
                        if success {
                            // Show success feedback
                            let successGenerator = UINotificationFeedbackGenerator()
                            successGenerator.notificationOccurred(.success)
                            
                            // Show success alert - IMPORTANT: Set this to true
                            withAnimation {
                                showSuccessAlert = true
                            }
                        }
                    }
                }) {
                    ZStack {
                        // Button background
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.primaryGradient)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        // Show either loading indicator or text
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Text("Save Changes")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        // Move the alert to here for better visibility
        .alert("Profile Updated", isPresented: $showSuccessAlert) {
            Button("OK") {
                // Only dismiss after user acknowledges the alert
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully!")
        }
        .alert(isPresented: $showRemoveConfirmation) {
            Alert(
                title: Text("Remove Profile Picture"),
                message: Text("Are you sure you want to remove your profile picture?"),
                primaryButton: .destructive(Text("Remove")) {
                    viewModel.removeProfileImage()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            // Load existing profile image if not already loaded
            if viewModel.selectedImage == nil,
               let imagePath = viewModel.currentUser?.profileImagePath,
               let image = ImageManager.shared.loadImage(fromPath: imagePath) {
                viewModel.selectedImage = image
            }
        }
    }
}
