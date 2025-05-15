//
//  ProfileSideDrawerView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileSideDrawerView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isShowing: Bool
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showPasswordPrompt = false
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    // For animation
    @State private var offset: CGFloat = -280
    
    var body: some View {
        ZStack {
            // Transparent overlay to detect taps outside drawer
            if offset == 0 {
                Color.black.opacity(0.001)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        closeDrawer()
                    }
            }
            
            // The actual drawer
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    // Header with profile info
                   
                    VStack(alignment: .leading, spacing: 15) {
                        // Profile image
                        if let profileImagePath = authViewModel.currentUser?.profileImagePath,
                           let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 80, height: 80)
                        }
                        
                        // User info
                        Text(authViewModel.currentUser?.fullName ?? "User Name")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text(authViewModel.currentUser?.username ?? "@username")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                            
                        if let isVerified = authViewModel.currentUser?.isVerified, isVerified {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppColors.primary)
                                
                                Text("Verified")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Menu options
                    VStack(spacing: 0) {
                        
                        
                        // Sign Out button
                        Button(action: {
                            showSignOutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .frame(width: 24, height: 24)
                                Text("Sign Out")
                                    .font(.system(.body, design: .rounded))
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                        }
                        
                        Divider()
                        
                        // Delete Account button
                        Button(action: {
                            showDeleteAccountConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.red)
                                Text("Delete Account")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 15)
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // App info
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Swaptitude")
                            .font(.system(.headline, design: .rounded))
                        Text("Version 1.0")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                .frame(width: 280)
                .background(Color(UIColor.systemBackground))
                .offset(x: offset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
                .edgesIgnoringSafeArea(.vertical)
                
                Spacer()
            }
        }
        .onAppear {
            offset = 0
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                showPasswordPrompt = true
            }
        } message: {
            Text("This will permanently delete your account and all your data. This action cannot be undone. Are you sure?")
        }
        .alert("Confirm Password", isPresented: $showPasswordPrompt) {
            SecureField("Enter your password", text: $password)
            Button("Cancel", role: .cancel) {
                password = ""
            }
            Button("Delete Account", role: .destructive) {
                print("Password entered, attempting account deletion")
                authViewModel.deleteAccountWithReauth(password: password) { error in
                    if let error = error {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    password = ""
                }
            }
        } message: {
            Text("For security, please enter your password to confirm account deletion")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // Function to close drawer
    private func closeDrawer() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -280
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}
