//
//  SignUpView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var showPasswordMismatch = false
    @State private var animateGradient = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("Create Account")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Join Swaptitude today!")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Animated gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: animateGradient ?
                                        [AppColors.gradientStart, AppColors.gradientEnd, AppColors.gradientStart] :
                                        [AppColors.gradientEnd, AppColors.gradientStart, AppColors.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Swapping Skills")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Connect with others and learn while teaching!")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.trailing, 20)
                    }
                }
                .padding(.horizontal, 30)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                // Form fields
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Full Name", text: $fullName, icon: "person")
                        .onChange(of: fullName) { _ in
                            viewModel.clearErrors()
                            showPasswordMismatch = false
                        }
                    
                    CustomTextField(placeholder: "Username", text: $username, icon: "at")
                        .onChange(of: username) { _ in
                            viewModel.clearErrors()
                            showPasswordMismatch = false
                        }
                    
                    CustomTextField(placeholder: "Email", text: $email, icon: "envelope")
                        .onChange(of: email) { _ in
                            viewModel.clearErrors()
                            showPasswordMismatch = false
                        }
                    
                    CustomTextField(placeholder: "Password", text: $password, icon: "lock", isSecure: true)
                        .onChange(of: password) { _ in
                            viewModel.clearErrors()
                            showPasswordMismatch = false
                        }
                    
                    CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, icon: "lock.shield", isSecure: true)
                        .onChange(of: confirmPassword) { _ in
                            viewModel.clearErrors()
                            showPasswordMismatch = false
                        }
                    
                    // Password mismatch error
                    if showPasswordMismatch {
                        Text("Passwords do not match")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .onAppear {
                                // Auto-clear after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation {
                                        showPasswordMismatch = false
                                    }
                                }
                            }
                    }
                    
                    // Error message
                    if viewModel.showError && !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .onAppear {
                                // Auto-clear after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    viewModel.clearErrors()
                                }
                            }
                    }
                    
                    // Sign up button
                    PrimaryButton(
                        title: "Sign Up",
                        action: {
                            if password != confirmPassword {
                                showPasswordMismatch = true
                                return
                            }
                            showPasswordMismatch = false
                            viewModel.clearErrors()
                            viewModel.signUp(withEmail: email, password: password, fullName: fullName, username: username)
                        },
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                // Sign in link
                HStack {
                    Text("Already have an account?")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // Clear errors when going back to sign in
                        viewModel.clearErrors()
                        dismiss()
                    }) {
                        Text("Sign In")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.top, 10)
                
                // Terms and conditions
                Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.clearErrors()
        }
    }
}

