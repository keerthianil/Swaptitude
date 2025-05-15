//
//  ChatListView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI
import Firebase

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
            } else if viewModel.messages.isEmpty {
                EmptyStateView(
                    icon: "message.fill",
                    title: "No Messages Yet",
                    message: "Start chatting with your matches to see messages here."
                )
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.messages) { message in
                            NavigationLink(destination: ChatView(match: message.match)) {
                                MessageRow(message: message)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Messages")
        .refreshable {
            viewModel.fetchMessages()
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

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 15) {
            // User image
            if let profileImagePath = message.otherUserProfileImageUrl,
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
                Text(message.otherUserName)
                    .font(.system(.headline, design: .rounded))
                
                Text(message.lastMessage ?? "No messages yet")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Timestamp
            if let date = message.lastMessageDate {
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
