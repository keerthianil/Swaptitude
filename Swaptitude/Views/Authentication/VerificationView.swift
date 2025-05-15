//
//  VerificationView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import SwiftUI

struct VerificationView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var onVerificationComplete: () -> Void
    @Binding var isNewUser: Bool
    @State private var emailSent = false
    @State private var isVerified = false
    @State private var animateCheckmark = false
    @State private var isCheckingVerification = false
    @State private var localErrorMessage = ""
    @State private var showLocalError = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    if isVerified {
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                            .opacity(animateCheckmark ? 1.0 : 0.0)
                            .onAppear {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                                    animateCheckmark = true
                                }
                            }
                    } else {
                        Image(systemName: "envelope.badge.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                
                Text(isVerified ? "Verification Complete!" : "Verify Your Account")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                
                Text(isVerified ?
                     "Your account has been verified" :
                     (emailSent ? "Check your email to complete verification" : "For your security, let's verify your email address"))
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Error message
            if showLocalError && !localErrorMessage.isEmpty {
                Text(localErrorMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal, 30)
                    .transition(.opacity)
                    .onAppear {
                        // Auto-clear after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                showLocalError = false
                                localErrorMessage = ""
                            }
                        }
                    }
            }
            
            if !emailSent && !isVerified {
                // Info card explaining verification
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(AppColors.primary)
                        
                        Text("Why Verify?")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    Text("Verification helps us ensure that you're really you. It also provides an extra layer of security for your account and all users on Swaptitude.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(AppColors.primary)
                        
                        Text("Creates trust in the community")
                            .font(.system(.caption, design: .rounded))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundColor(AppColors.primary)
                        
                        Text("Protects your personal information")
                            .font(.system(.caption, design: .rounded))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(AppColors.primary)
                        
                        Text("Shows your commitment to safe exchanges")
                            .font(.system(.caption, design: .rounded))
                        
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 30)
                
                // Send verification button
                PrimaryButton(
                    title: "Send Verification Email",
                    action: {
                        sendVerificationEmail()
                    },
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, 30)
                .padding(.top, 10)
            } else if emailSent && !isVerified {
                // Waiting for verification
                VStack(spacing: 15) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                        .padding(.bottom, 10)
                    
                    Text("Verification Email Sent!")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("We've sent a verification email to your inbox. Please check your email and click the verification link.")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("After clicking the verification link, click the refresh button below to check your verification status.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 30)
                
                // Buttons
                VStack(spacing: 15) {
                    PrimaryButton(
                        title: isCheckingVerification ? "Checking..." : "Refresh Verification Status",
                        action: {
                            checkVerificationStatus()
                        },
                        isLoading: isCheckingVerification
                    )
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        sendVerificationEmail()
                    }) {
                        Text("Resend Verification Email")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.top, 20)
            }
            
            if isVerified {
                PrimaryButton(
                    title: "Continue to App",
                    action: {
                        onVerificationComplete()
                    }
                )
                .padding(.horizontal, 30)
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .navigationTitle("Account Verification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.clearErrors()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Demo Verify") {
                    simulateSuccessfulVerification()
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
    }
    
    func sendVerificationEmail() {
        guard let email = viewModel.currentUser?.email else {
            showError("Email not found")
            return
        }
        
        viewModel.sendEmailVerification { success, errorMessage in
            if success {
                emailSent = true
                clearLocalError()
            } else if let errorMessage = errorMessage {
                showError(errorMessage)
            }
        }
    }
    
    func checkVerificationStatus() {
        isCheckingVerification = true
        
        viewModel.checkIfEmailVerified { success in
            isCheckingVerification = false
            
            if success {
                simulateSuccessfulVerification()
            } else {
                showError("Email not yet verified. Please check your email and click the verification link.")
            }
        }
    }
    
    func simulateSuccessfulVerification() {
        withAnimation {
            isVerified = true
            viewModel.currentUser?.isVerified = true
            clearLocalError()
        }
    }
    
    func showError(_ message: String) {
        withAnimation {
            localErrorMessage = message
            showLocalError = true
        }
    }
    
    func clearLocalError() {
        withAnimation {
            localErrorMessage = ""
            showLocalError = false
        }
    }
}
