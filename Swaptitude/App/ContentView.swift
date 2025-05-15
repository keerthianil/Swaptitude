//
//  ContentView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import SwiftUI

enum AuthState {
    case login
    case loading
    case needsVerification
    case onboarding
    case main
}

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var authState: AuthState = .login
    @State private var showOnboarding = true
    @State private var isNewUser = false
    @State private var loadingTimeout = false
    
    var body: some View {
        Group {
            switch authState {
            case .login:
                LoginView()
                    .environmentObject(viewModel)
            case .loading:
                VStack {
                    ProgressView("Loading profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    if loadingTimeout {
                        Button("Return to Login") {
                            // Force sign out and return to login
                            viewModel.signOut()
                            authState = .login
                        }
                        .padding(.top, 20)
                    }
                }
                .onAppear {
                    // Set a timeout to show the button after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if authState == .loading {
                            loadingTimeout = true
                        }
                    }
                    
                    // Force transition to login if loading takes too long
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if authState == .loading {
                            // Clear auth state and go to login
                            viewModel.signOut()
                            authState = .login
                        }
                    }
                }
            case .needsVerification:
                NavigationStack {
                    VerificationView(
                        onVerificationComplete: {
                            // After verification, go to onboarding for new users
                            if isNewUser {
                                authState = .onboarding
                            } else {
                                authState = .main
                            }
                        },
                        isNewUser: $isNewUser
                    )
                    .environmentObject(viewModel)
                }
            case .onboarding:
                OnboardingView(showOnboarding: $showOnboarding)
                    .onChange(of: showOnboarding) { newValue in
                        print("showOnboarding changed to: \(newValue)")
                        if !newValue {
                            authState = .main
                        }
                    }
            case .main:
                MainTabView()
                    .environmentObject(viewModel)
            }
        }
        .animation(.easeInOut, value: authState)
        .onChange(of: viewModel.userSession) { _ in
            print("userSession changed")
            updateAuthState()
        }
        .onChange(of: viewModel.currentUser?.id) { _ in
            print("currentUser changed")
            updateAuthState()
        }
        .alert(isPresented: $viewModel.showSuccess) {
            Alert(
                title: Text("Success"),
                message: Text(viewModel.successMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            print("ContentView appeared")
            
            // Check if we need to force logout due to deleted account
            if viewModel.userSession != nil && viewModel.currentUser == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if viewModel.currentUser == nil {
                        print("User document not found, forcing logout")
                        viewModel.signOut()
                        authState = .login
                    }
                }
            }
            
            updateAuthState()
        }
    }
    
    func updateAuthState() {
        print("Updating auth state")
        if viewModel.userSession == nil {
            print("→ login state")
            authState = .login
            loadingTimeout = false
        } else if viewModel.currentUser == nil {
            print("→ loading state")
            authState = .loading
            // Trigger user fetch
            viewModel.fetchUser()
        } else if viewModel.currentUser?.isVerified == false {
            print("→ needs verification")
            authState = .needsVerification
            loadingTimeout = false
            checkIfNewUser()
        } else if checkIfNewUser() && showOnboarding {
            print("→ onboarding (new user)")
            authState = .onboarding
            loadingTimeout = false
        } else {
            print("→ main")
            authState = .main
            loadingTimeout = false
        }
    }
    
    @discardableResult
    func checkIfNewUser() -> Bool {
        guard let createdAt = viewModel.currentUser?.createdAt else {
            isNewUser = false
            return false
        }
        
        // If user was created less than 5 minutes ago, consider them new
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        isNewUser = createdAt > fiveMinutesAgo
        print("Is new user: \(isNewUser)")
        return isNewUser
    }
}
