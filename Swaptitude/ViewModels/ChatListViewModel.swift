//
//  ChatListViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

class ChatListViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var unreadMessagesCount: Int = 0
    
    private let db = Firestore.firestore()
    private var listeners = [ListenerRegistration]()
    
    deinit {
        for listener in listeners {
            listener.remove()
        }
    }
    
    init() {
        fetchMessages()
    }
    
    func fetchMessages() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        isLoading = true
        
        // Clear previous listeners
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        
        // Add a real-time listener to the matches collection
        let matchesListener = db.collection("matches")
            .whereField("user1Id", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                // Check for deleted documents
                let deletedDocs = snapshot.documentChanges.filter({ $0.type == .removed }).map({ $0.document })
                if !deletedDocs.isEmpty {
                    // When a match is deleted, refresh the messages
                    self.refreshMessages()
                }
            }
        listeners.append(matchesListener)
        
        // Also listen for matches where user is user2
        let matchesListener2 = db.collection("matches")
            .whereField("user2Id", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                
                // Check for deleted documents
                let deletedDocs = snapshot.documentChanges.filter({ $0.type == .removed }).map({ $0.document })
                if !deletedDocs.isEmpty {
                    // When a match is deleted, refresh the messages
                    self.refreshMessages()
                    
                }
            }
        listeners.append(matchesListener2)
        
        let matchesQuery1 = db.collection("matches").whereField("user1Id", isEqualTo: userId)
        let matchesQuery2 = db.collection("matches").whereField("user2Id", isEqualTo: userId)
        
        // Add listener for user1 matches
        let listener1 = matchesQuery1.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.handleMatchesSnapshot(snapshot: snapshot, error: error, userId: userId)
        }
        listeners.append(listener1)
        
        // Add listener for user2 matches
        let listener2 = matchesQuery2.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.handleMatchesSnapshot(snapshot: snapshot, error: error, userId: userId)
        }
        listeners.append(listener2)
        
        // Update unread count
        let unreadCount = self.messages.reduce(0) { count, message in
            count + message.match.unreadCount
        }
        self.unreadMessagesCount = unreadCount
    }

    // Add a helper method to refresh messages
    private func refreshMessages() {
        // Clear messages that no longer have a match
        DispatchQueue.main.async {
            // Fetch active matches
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let group = DispatchGroup()
            var validMatchIds = Set<String>()
            
            group.enter()
            self.db.collection("matches")
                .whereField("user1Id", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    defer { group.leave() }
                    if let documents = snapshot?.documents {
                        for doc in documents {
                            validMatchIds.insert(doc.documentID)
                        }
                    }
                }
            
            group.enter()
            self.db.collection("matches")
                .whereField("user2Id", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    defer { group.leave() }
                    if let documents = snapshot?.documents {
                        for doc in documents {
                            validMatchIds.insert(doc.documentID)
                        }
                    }
                }
            
            group.notify(queue: .main) {
                // Remove messages for deleted matches
                self.messages = self.messages.filter { message in
                    guard let matchId = message.match.id else { return false }
                    return validMatchIds.contains(matchId)
                }
            }
        }
    }
    
    private func handleMatchesSnapshot(snapshot: QuerySnapshot?, error: Error?, userId: String) {
        if let error = error {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError = true
            return
        }
        
        guard let documents = snapshot?.documents else {
            self.isLoading = false
            return
        }
        
        let newMatches = documents.compactMap { try? $0.data(as: Match.self) }
        var newMessages: [Message] = []
        
        for match in newMatches {
            // Only add if it has a message
            if match.lastMessage != nil {
                let otherUserName = match.otherUserName(currentUserId: userId)
                let otherUserProfileUrl = match.otherUserProfileImageUrl(currentUserId: userId)
                
                newMessages.append(Message(
                    match: match,
                    otherUserName: otherUserName,
                    otherUserProfileImageUrl: otherUserProfileUrl,
                    lastMessage: match.lastMessage,
                    lastMessageDate: match.lastMessageDate,
                    unreadCount: match.unreadCount
                ))
            }
        }
        
        // Combine with existing messages, remove duplicates, and sort
        var allMessages = self.messages
        
        // Add new messages, avoiding duplicates based on match ID
        for newMessage in newMessages {
            if !allMessages.contains(where: { $0.match.id == newMessage.match.id }) {
                allMessages.append(newMessage)
            } else if let index = allMessages.firstIndex(where: { $0.match.id == newMessage.match.id }) {
                // Update existing message with latest info
                allMessages[index] = newMessage
            }
        }
        
        // Sort by last message date
        self.messages = allMessages.sorted {
            ($0.lastMessageDate ?? $0.match.createdAt) > ($1.lastMessageDate ?? $1.match.createdAt)
        }
        
        self.isLoading = false
    }
}
