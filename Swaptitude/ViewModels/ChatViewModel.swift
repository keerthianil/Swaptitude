//
//  ChatViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var matchDeleted = false
    
    private var match: Match?
    private let db = Firestore.firestore()
    private var messageListener: ListenerRegistration?
    private var matchListener: ListenerRegistration?
    
    deinit {
        messageListener?.remove()
        matchListener?.remove()
    }
    
    func loadMessages(for match: Match) {
        self.match = match
        isLoading = true
        errorMessage = ""
        
        guard let matchId = match.id else {
            errorMessage = "Invalid match ID"
            return
        }
        
        // Remove any existing listeners
        messageListener?.remove()
        matchListener?.remove()
        
        print("Setting up listeners for matchId: \(matchId)")
        
        // First check if match still exists
        db.collection("matches").document(matchId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Error checking match: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // If match doesn't exist, set deleted flag
            if document == nil || !document!.exists {
                print("Match no longer exists: \(matchId)")
                DispatchQueue.main.async {
                    self.matchDeleted = true
                    self.messages = []
                    self.isLoading = false
                }
                return
            }
            
            // Set up real-time listener for match document with an immediate callback
            self.matchListener = self.db.collection("matches").document(matchId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error listening to match: \(error.localizedDescription)")
                        return
                    }
                    
                    // Check if document has been deleted
                    if snapshot == nil || !snapshot!.exists {
                        print("Match deleted in real-time: \(matchId)")
                        DispatchQueue.main.async {
                            self.matchDeleted = true
                            self.messages = []
                        }
                        return
                    }
                }
            
            // Listen for messages with immediate callback
            self.messageListener = self.db.collection("chatMessages")
                .whereField("matchId", isEqualTo: matchId)
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error listening for messages: \(error.localizedDescription)")
                        self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                        return
                    }
                    
                    // If there's a snapshot but it's empty, clear messages
                    if let snapshot = snapshot, snapshot.documents.isEmpty {
                        print("No messages found for matchId: \(matchId)")
                        DispatchQueue.main.async {
                            self.messages = []
                        }
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents in snapshot for matchId: \(matchId)")
                        DispatchQueue.main.async {
                            self.messages = []
                        }
                        return
                    }
                    
                    print("Found \(documents.count) messages for matchId: \(matchId)")
                    
                    // Process messages
                    let newMessages = documents.compactMap { document -> ChatMessage? in
                        do {
                            return try document.data(as: ChatMessage.self)
                        } catch {
                            print("Error decoding message: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    // Sort by timestamp
                    let sortedMessages = newMessages.sorted { $0.timestamp < $1.timestamp }
                    
                    DispatchQueue.main.async {
                        self.messages = sortedMessages
                        
                        // Mark messages as read if received
                        if !sortedMessages.isEmpty, let match = self.match {
                            self.markMessagesAsRead(for: match)
                        }
                    }
                }
        }
    }
    
    private func setupMessageListener(matchId: String) {
        // Listen for messages
        messageListener = db.collection("chatMessages")
            .whereField("matchId", isEqualTo: matchId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error listening for messages: \(error.localizedDescription)")
                    self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found for matchId: \(matchId)")
                    self.messages = []
                    return
                }
                
                print("Found \(documents.count) messages for matchId: \(matchId)")
                
                // Process messages
                let newMessages = documents.compactMap { document -> ChatMessage? in
                    do {
                        return try document.data(as: ChatMessage.self)
                    } catch {
                        print("Error decoding message: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                // Sort by timestamp
                let sortedMessages = newMessages.sorted { $0.timestamp < $1.timestamp }
                
                DispatchQueue.main.async {
                    self.messages = sortedMessages
                    
                    // Mark messages as read if received
                    if !sortedMessages.isEmpty, let match = self.match {
                        self.markMessagesAsRead(for: match)
                    }
                }
            }
    }
    
    // Add a helper function to refresh match data
    private func refreshMatchData(matchId: String, completion: @escaping (Bool) -> Void) {
        db.collection("matches").document(matchId).getDocument { [weak self] document, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Error refreshing match data: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, let updatedMatch = try? document.data(as: Match.self) else {
                print("Match no longer exists or is inaccessible")
                completion(false)
                return
            }
            
            // Update the local match
            self.match = updatedMatch
            
            // Try loading messages again
            self.loadMessages(for: updatedMatch)
            completion(true)
        }
    }
    
    func sendMessage(matchId: String, content: String, receiverId: String) {
        guard let senderId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            return
        }
        
        let message = ChatMessage(
            matchId: matchId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: Date(),
            isRead: false
        )
        
        do {
            print("Sending message to matchId: \(matchId)")
            // Add to Firestore
            try db.collection("chatMessages").addDocument(from: message) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    self.errorMessage = "Failed to send message: \(error.localizedDescription)"
                } else {
                    print("Message sent successfully")
                    
                    // We don't need to add local notification here as it will be handled by the receiver
                }
            }
            
            // Update the match with last message
            db.collection("matches").document(matchId).updateData([
                "lastMessage": content,
                "lastMessageDate": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error updating match: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error encoding message: \(error.localizedDescription)")
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
    }
    
    func markMessagesAsRead(for match: Match) {
        guard let matchId = match.id,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find unread messages where current user is the receiver
        db.collection("chatMessages")
            .whereField("matchId", isEqualTo: matchId)
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                // Use a batch to update all messages
                let batch = self.db.batch()
                
                for document in documents {
                    batch.updateData(["isRead": true], forDocument: document.reference)
                }
                
                // Reset unread count on the match
                if let matchId = match.id {
                    batch.updateData(["unreadCount": 0], forDocument: self.db.collection("matches").document(matchId))
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error marking messages as read: \(error.localizedDescription)")
                    }
                }
            }
    }
}
