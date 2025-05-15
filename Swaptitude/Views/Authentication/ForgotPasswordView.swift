//
//  ForgotPasswordView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var emailSent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 30)
                
                if emailSent {
                    // Success state
                    VStack(spacing: 20) {
                        Text("Email Sent!")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("We've sent password reset instructions to your email address.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        PrimaryButton(title: "Back to Login", action: {
                            dismiss()
                        })
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }
                } else {
                    // Form state
                    VStack(spacing: 20) {
                        Text("Reset Password")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you instructions to reset your password.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        CustomTextField(placeholder: "Email", text: $email, icon: "envelope")
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
                        
                        // Error message
                        if !viewModel.errorMessage.isEmpty && viewModel.showError {
                            Text(viewModel.errorMessage)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                        
                        PrimaryButton(
                            title: "Send Reset Link",
                            action: {
                                viewModel.resetPassword(withEmail: email)
                                if viewModel.errorMessage.isEmpty {
                                    emailSent = true
                                }
                            },
                            isLoading: viewModel.isLoading
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

