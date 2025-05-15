//
//  LoginView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App logo and name
                VStack(spacing: 15) {
                    Image("swaptitudeicon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(25)
                    
                    Text("SWAPTITUDE")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Swap skills, sharpen aptitudes")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Login form
                VStack(spacing: 20) {
                    CustomTextField(placeholder: "Email", text: $email, icon: "envelope")
                        .onChange(of: email) { _ in
                            viewModel.clearErrors()
                        }
                    
                    CustomTextField(placeholder: "Password", text: $password, icon: "lock", isSecure: true)
                        .onChange(of: password) { _ in
                            viewModel.clearErrors()
                        }
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showForgotPassword.toggle()
                        }) {
                            Text("Forgot Password?")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.top, -10)
                    
                    // Error message
                    if viewModel.showError && !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .transition(.opacity)
                            .onAppear {
                                // Auto-clear errors after 5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    viewModel.clearErrors()
                                }
                            }
                    }
                    
                    // Sign in button
                    PrimaryButton(
                        title: "Sign In",
                        action: {
                            viewModel.clearErrors() // Clear any existing errors
                            viewModel.signIn(withEmail: email, password: password)
                        },
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    
                    NavigationLink {
                        SignUpView()
                            .environmentObject(viewModel)
                            .onAppear {
                                viewModel.clearErrors()
                            }
                    } label: {
                        Text("Sign Up")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                
                // Animated wave footer
                ZStack {
                    WaveShape()
                        .fill(AppColors.primaryGradient)
                        .frame(height: 150)
                    
                    WaveShape(offset: 180, percent: 0.5)
                        .fill(AppColors.primary.opacity(0.3))
                        .frame(height: 150)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(viewModel)
            }
            .onAppear {
                // Clear errors when view appears
                viewModel.clearErrors()
            }
        }
    }
}
