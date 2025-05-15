//
//  ChatView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//


import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    let match: Match
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSkillBeeSuggestions = false
    @State private var isFirstLoad = true
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showScheduleMeeting = false
    
    var body: some View {
        VStack {
            // Check if match has been deleted
            if viewModel.matchDeleted {
                VStack {
                    Spacer()
                    Text("This conversation is no longer available")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    
                    PrimaryButton(
                        title: "Go Back",
                        action: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    .padding()
                    
                    Spacer()
                }
            } else {
                // Messages list
                messagesContent
            }
        }
        .navigationTitle(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModelSetup()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            errorMessageChanged(newValue: newValue)
        }
        // Add overlay for suggestions
        .overlay {
            suggestionOverlay
        }
    }
    
    private func viewModelSetup() {
        print("ChatView appeared for match ID: \(match.id ?? "nil")")
        viewModel.loadMessages(for: match)
        viewModel.markMessagesAsRead(for: match)
        
        // Show suggestions if first load and no messages
        if isFirstLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.messages.isEmpty {
                    showSkillBeeSuggestions = true
                }
                isFirstLoad = false
            }
        }
    }
    
    private func errorMessageChanged(newValue: String) {
        if !newValue.isEmpty {
            alertMessage = newValue
            showAlert = true
        }
    }
    
    private var messagesContent: some View {
        ZStack {
            ScrollViewReader { scrollView in
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.messages.isEmpty {
                    emptyMessagesView
                } else {
                    messagesScrollView(scrollView: scrollView)
                }
            }
            
            // Message input view at the bottom
            VStack {
                Spacer()
                messageInputView
            }
        }
    }
    
    private var emptyMessagesView: some View {
        VStack {
            Spacer()
            Text("No messages yet")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)
            Text("Start the conversation!")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(AppColors.primary)
                .padding(.top, 5)
                
            // Add SkillBee suggestion button
            Button(action: {
                showSkillBeeSuggestions = true
            }) {
                HStack {
                    Text("🐝")
                        .font(.system(size: 20))
                    
                    Text("Need help starting the conversation?")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow.opacity(0.2))
                )
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
    
    private func messagesScrollView(scrollView: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.messages) { message in
                    MessageBubbleView(message: message)
                        .id(message.id)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(scrollView: scrollView)
            }
        }
    }
    
    private func scrollToBottom(scrollView: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last, let id = lastMessage.id {
            withAnimation {
                scrollView.scrollTo(id, anchor: .bottom)
            }
        }
    }
    
    private var messageInputView: some View {
        HStack {
            TextField("Type a message...", text: $newMessage)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(20)
                .focused($isTextFieldFocused)
            
            Button(action: {
                showScheduleMeeting = true
            }) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(AppColors.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primary, lineWidth: 1.5)
                )
            }
            .padding(.horizontal)
            .sheet(isPresented: $showScheduleMeeting) {
                ScheduleMeetingView(match: match)
            }
            
            Button(action: {
                sendMessage()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(newMessage.isEmpty ? .gray : AppColors.primary)
            }
            .disabled(newMessage.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var suggestionOverlay: some View {
        Group {
            if showSkillBeeSuggestions {
                ZStack {
                    // Translucent background
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showSkillBeeSuggestions = false
                        }
                    
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("🐝")
                                .font(.system(size: 24))
                            
                            Text("Conversation Starters")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showSkillBeeSuggestions = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            .padding(10)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        
                        Divider()
                        
                        // Fixed content container with scrollable area
                        VStack(spacing: 0) {
                            // Scrollable content with wider margins
                            ScrollView {
                                VStack(spacing: 10) {
                                    // Get suggestions from MatchViewModel
                                    let matchViewModel = MatchViewModel()
                                    let suggestions = matchViewModel.getConversationStarters(for: match)
                                    
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        // Narrower button with more horizontal space
                                        Button(action: {
                                            // Set the suggestion as message text
                                            newMessage = suggestion
                                            showSkillBeeSuggestions = false
                                        }) {
                                            Text(suggestion)
                                                .font(.system(.body, design: .rounded))
                                                .multilineTextAlignment(.leading)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .frame(width: UIScreen.main.bounds.width * 0.6) // Make buttons narrower (reduced from 0.7)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(UIColor.systemGray5))
                                                )
                                                // Add distinct visual feedback for button press
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 50) // Increased horizontal padding for more free space
                                    }
                                }
                                .padding(.vertical)
                            }
                            .frame(maxHeight: 350)
                        }
                        .background(Color(UIColor.systemBackground))
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showSkillBeeSuggestions = false
                            }) {
                                Text("Maybe Later")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                        .background(Color(UIColor.systemGray6))
                    }
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 500)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showSkillBeeSuggestions)
            }
        }
    }
    
    private func sendMessage() {
        if !newMessage.isEmpty {
            guard let matchId = match.id else {
                alertMessage = "Invalid match ID"
                showAlert = true
                return
            }
            
            let receiverId = match.otherUserId(currentUserId: Auth.auth().currentUser?.uid ?? "")
            
            viewModel.sendMessage(
                matchId: matchId,
                content: newMessage,
                receiverId: receiverId
            )
            newMessage = ""
        }
    }

    func presentChatView() {
        // Dismiss the match animation
        showSkillBeeSuggestions = false
        
        // Create chat view
        let chatView = ChatView(match: match)
        
        // Present using UIKit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // Remove [weak self] here since it's causing the error
                let hostingController = UIHostingController(rootView:
                    NavigationView {
                        chatView
                    }
                )
                rootViewController.present(hostingController, animated: true)
            }
        }
    }
}
