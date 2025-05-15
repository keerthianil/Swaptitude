//
//  NotificationView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/18/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                } else if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Notifications",
                        message: "New matches, messages, and reviews will appear here."
                    )
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationItemView(notification: notification)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.deleteNotification(notificationId: notification.id ?? "")
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    if !notification.isRead {
                                        Button {
                                            viewModel.markAsRead(notificationId: notification.id ?? "")
                                        } label: {
                                            Label("Mark as read", systemImage: "checkmark")
                                        }
                                        .tint(.blue)
                                    }
                                }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Button("Clear All") {
                            viewModel.clearAllNotifications()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchNotifications()
            }
        }
    }
}

struct NotificationItemView: View {
    let notification: UserNotification
    @State private var navigateToDetail = false
    
    var body: some View {
        Button(action: {
            // Mark notification as read
            if let id = notification.id {
                let db = Firestore.firestore()
                db.collection("notifications").document(id).updateData(["isRead": true])
            }
            
            // Navigate
            navigateToDetail = true
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Icon based on notification type
                ZStack {
                    Circle()
                        .fill(notificationColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: notificationIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(notification.isRead ? .regular : .bold)
                    
                    Text(notification.message)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(timeAgoString(from: notification.timestamp))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(destination: detailDestination, isActive: $navigateToDetail) {
                EmptyView()
            }
        )
    }
    
    // Destination based on notification type
    @ViewBuilder
    private var detailDestination: some View {
        switch notification.type {
        case "newMatch", "newMessage":
            if let matchId = notification.relatedId {
                NotificationDetailLoaderView(matchId: matchId)
            } else {
                EmptyView()
            }
        case "newReview":
            if let userId = Auth.auth().currentUser?.uid {
                ReviewsListView(userId: userId, userName: "Your Reviews")
            } else {
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case "newMatch":
            return "person.2.fill"
        case "newMessage":
            return "message.fill"
        case "newReview":
            return "star.fill"
        default:
            return "bell.fill"
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case "newMatch":
            return .blue
        case "newMessage":
            return AppColors.primary
        case "newReview":
            return .orange
        default:
            return .gray
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// This intermediate view loads the match data and then navigates to ChatView

struct NotificationDetailLoaderView: View {
    let matchId: String
    @State private var match: Match?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
            } else if let match = match {
                ChatView(match: match)
            } else {
                Text("Could not load conversation")
            }
        }
        .onAppear {
            loadMatchData()
        }
    }
    
    private func loadMatchData() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("matches").document(matchId).getDocument { snapshot, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                errorMessage = "Match not found"
                return
            }
            
            do {
                self.match = try snapshot.data(as: Match.self)
            } catch {
                errorMessage = "Failed to decode match data"
            }
        }
    }
}
