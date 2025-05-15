//
//  MatchesView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MatchesView: View {
    @StateObject private var viewModel = MatchViewModel()
    @StateObject private var chatViewModel = ChatListViewModel()
    @State private var selectedTab: Int = 0
    
    var body: some View {
           ZStack {
               VStack {
                   // Tab selector - "Your Matches" and "Messages"
                   HStack {
                       TabButtonView(
                           title: "Your Matches",
                           isSelected: selectedTab == 0,
                           action: { selectedTab = 0 }
                       )
                       
                       TabButtonView(
                           title: "Messages",
                           isSelected: selectedTab == 1,
                           action: { selectedTab = 1 }
                       )
                   }
                   .padding(.horizontal)
                   .padding(.top, 10)
                   
                   if viewModel.isLoading || chatViewModel.isLoading {
                       Spacer()
                       ProgressView()
                           .scaleEffect(1.5)
                           .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                       Spacer()
                   } else {
                       if selectedTab == 0 {
                        // Your matches
                        if viewModel.matches.isEmpty {
                            EmptyStateView(
                                icon: "person.2.slash",
                                title: "No Matches Yet",
                                message: "When you connect with someone, they'll appear here."
                            )
                        } else {
                            ScrollView {
                                VStack(spacing: 15) {
                                    HStack {
                                        Text("Your matches are waiting to connect!")
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.fetchMatches()
                                        }) {
                                            Image(systemName: "arrow.clockwise")
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                    
                                    ForEach(viewModel.matches) { match in
                                        NavigationLink(destination: MatchDetailView(match: match, viewModel: viewModel)) {
                                            MatchCardView(match: match)
                                                .padding(.horizontal)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        }
                    } else {
                        // Messages tab
                        if chatViewModel.messages.isEmpty {
                                                   EmptyStateView(
                                                       icon: "message.fill",
                                                       title: "No Messages Yet",
                                                       message: "Start chatting with your matches to see messages here."
                                                   )
                                               } else {
                                                   ScrollView {
                                                       VStack(spacing: 15) {
                                                           HStack {
                                                               Text("Recent conversations")
                                                                   .font(.system(.headline, design: .rounded))
                                                                   .foregroundColor(.secondary)
                                                               
                                                               Spacer()
                                                               
                                                               Button(action: {
                                                                   chatViewModel.fetchMessages()
                                                               }) {
                                                                   Image(systemName: "arrow.clockwise")
                                                                       .foregroundColor(AppColors.primary)
                                                               }
                                                           }
                                                           .padding(.horizontal)
                                                           .padding(.top, 10)
                                                           
                                                           ForEach(chatViewModel.messages) { message in
                                                               NavigationLink(destination: ChatView(match: message.match)) {
                                                                   MessageRow(message: message)
                                                                       .padding(.horizontal)
                                                               }
                                                               .buttonStyle(PlainButtonStyle())
                                                           }
                                                       }
                                                       .padding(.bottom, 20)
                                                   }
                                               }
                                           }
                                       }
                                   }
                                   
                                   // Match success overlay (keep this)
                                   if viewModel.showMatchSuccess, let newMatch = viewModel.newMatch {
                                       MatchNotificationView(
                                           match: newMatch,
                                           showMatchSuccess: $viewModel.showMatchSuccess
                                       )
                                   }
                               }
                               .navigationTitle("Matches")
                               .onAppear {
                                   viewModel.fetchValidUsers()
                                   viewModel.fetchMatches()
                                   chatViewModel.fetchMessages()
                               }
                               .refreshable {
                                   viewModel.fetchValidUsers()
                                   viewModel.fetchMatches()
                                   chatViewModel.fetchMessages()
                               }
                               .alert(isPresented: $viewModel.showError) {
                                   Alert(
                                       title: Text("Error"),
                                       message: Text(viewModel.errorMessage),
                                       dismissButton: .default(Text("OK"))
                                   )
                               }
                           }
}

// Conversation row for the messages tab
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 15) {
            // User image
            if let profileImagePath = conversation.otherUserProfileImageUrl,
               let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 50, height: 50)
            }
            
            // Message preview
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName)
                    .font(.system(.headline, design: .rounded))
                
                Text(conversation.lastMessage ?? "No messages yet")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Timestamp
            if let date = conversation.lastMessageDate {
                Text(timeAgoShort(from: date))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    func timeAgoShort(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


struct Conversation: Identifiable {
    var id: String { return match.id ?? UUID().uuidString }
    let match: Match
    let otherUserName: String
    let otherUserProfileImageUrl: String?
    let lastMessage: String?
    let lastMessageDate: Date?
    let unreadCount: Int
}
