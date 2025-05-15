//
//  SkillBeeChatView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//
import SwiftUI

struct SkillBeeChatView: View {
    @StateObject var viewModel = SkillBeeModel()
    @State private var userInput: String = ""
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            // Header with improved styling
            HStack {
                // More vibrant bee icon
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 40, height: 40)
                    
                    Text("🐝")
                        .font(.system(size: 25))
                }
                
                Text("SkillBee Assistant")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.yellow.opacity(0.2))
            )
            .padding(.horizontal)
            
            // Chat messages with improved styling
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.isFromBot {
                                    // Bot messages aligned left
                                    ZStack {
                                        Circle()
                                            .fill(Color.yellow.opacity(0.7))
                                            .frame(width: 36, height: 36)
                                        
                                        Text("🐝")
                                            .font(.system(size: 20))
                                    }
                                    .padding(.trailing, 8)
                                    
                                    Text(message.content)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.yellow.opacity(0.4))
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        )
                                        .foregroundColor(.primary) // Better for dark mode
                                    
                                    Spacer()
                                } else {
                                    // User messages aligned right
                                    Spacer()
                                    
                                    Text(message.content)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(AppColors.primary.opacity(0.5))
                                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                        )
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id(message.id)
                        }
                        
                        // Add loading indicator when waiting for response
                        if viewModel.isLoading {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.7))
                                        .frame(width: 36, height: 36)
                                    
                                    Text("🐝")
                                        .font(.system(size: 20))
                                }
                                .padding(.trailing, 8)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.yellow.opacity(0.2))
                                    )
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id("loading") // ID for loading indicator
                        }
                        
                        // Empty view at the bottom for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomID")
                    }
                    .padding(.vertical)
                }
                // Scroll to bottom when messages change
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        scrollView.scrollTo("bottomID", anchor: .bottom)
                    }
                }
                // Scroll when loading state changes
                .onChange(of: viewModel.isLoading) { isLoading in
                    if isLoading {
                        withAnimation {
                            scrollView.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
                // Initial scroll to bottom
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            scrollView.scrollTo("bottomID", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Enhanced suggestions
            if !viewModel.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button(action: {
                                sendMessage(suggestion)
                            }) {
                                Text(suggestion)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.yellow.opacity(0.5))
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                                    .foregroundColor(.primary) // Better for dark mode
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
            }
            
            HStack(alignment: .center, spacing: 10) {
                // Use a ZStack with fixed size to prevent collapsing issues
                ZStack(alignment: .leading) {
                    if userInput.isEmpty {
                        Text("Ask SkillBee...")
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.leading, 15)
                    }
                    
                    TextField("", text: $userInput)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .submitLabel(.send) // Enable send on keyboard
                        .onSubmit {
                            if !userInput.isEmpty {
                                sendMessage(userInput)
                            }
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.15))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .frame(height: 44)
                Button(action: {
                    if !userInput.isEmpty {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        sendMessage(userInput)
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        // Use a color visible in both modes
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(AppColors.primary)
                                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                        )
                }
                .disabled(userInput.isEmpty)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(UIColor.systemBackground).opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding()
        .onAppear {
            // Show welcome message on first appearance
            if viewModel.messages.isEmpty {
                // First send a random quote
                let quoteMessage = SkillBeeMessage(
                    content: viewModel.getRandomQuote(),
                    isFromBot: true
                )
                viewModel.messages.append(quoteMessage)
                
                // Then after a short delay, send welcome message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let welcomeMessage = SkillBeeMessage(
                        content: "Hi there! I'm SkillBee, your skill-swapping assistant. How can I help you today? 🐝",
                        isFromBot: true
                    )
                    viewModel.messages.append(welcomeMessage)
                    
                    // Add some default suggestions
                    viewModel.suggestions = [
                        "How do I find a good match?",
                        "Tips for teaching beginners",
                        "How to prepare for my first swap"
                    ]
                }
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        // Only proceed if there's actual text
        guard !text.isEmpty else { return }
        
        // Add user message immediately for responsive UI
        let userMessage = SkillBeeMessage(content: text, isFromBot: false)
        viewModel.messages.append(userMessage)
        
        // Clear input field after adding the message
        DispatchQueue.main.async {
            userInput = ""
        }
        
        // Show loading indicator by setting loading state
        viewModel.isLoading = true
        
        // Simulate network delay for natural feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Get response from local logic
            let response = viewModel.getResponseForQuery(text)
            
            // Add response to messages
            let botMessage = SkillBeeMessage(content: response, isFromBot: true)
            self.viewModel.messages.append(botMessage)
            
            // Stop loading
            self.viewModel.isLoading = false
            
            // Update suggestions based on the message content
            self.viewModel.updateSuggestions()
        }
    }
}
