//
//  ChatService.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    

    func sendMessage(matchId: String, receiverId: String, content: String, completion: @escaping (Error?) -> Void) {
        guard let senderId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let message = [
            "matchId": matchId,
            "senderId": senderId,
            "receiverId": receiverId,
            "content": content,
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false
        ] as [String: Any]
        
        // Save to chatMessages collection
        db.collection("chatMessages").addDocument(data: message) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            // Update the match with last message info
            self.db.collection("matches").document(matchId).updateData([
                "lastMessage": content,
                "lastMessageDate": FieldValue.serverTimestamp(),
                "unreadCount": FieldValue.increment(Int64(1))
            ]) { error in
                if error == nil {
                    // Get sender name for the notification
                    self.db.collection("users").document(senderId).getDocument { snapshot, error in
                        if let document = snapshot, let userData = try? document.data(as: User.self) {
                            // Create a notification for the message recipient
                            let notification = [
                                "userId": receiverId,
                                "type": "newMessage",
                                "title": "New Message",
                                "message": "\(userData.fullName): \(content.prefix(30))\(content.count > 30 ? "..." : "")",
                                "relatedId": matchId,
                                "isRead": false,
                                "timestamp": FieldValue.serverTimestamp()
                            ] as [String: Any]
                            
                            self.db.collection("notifications").addDocument(data: notification)
                        }
                    }
                }
                
                completion(error)
            }
        }
    }
    
    // Delete all messages for a match
    func deleteAllMessages(for matchId: String, completion: @escaping (Error?) -> Void) {
        print("Starting deletion of messages for match ID: \(matchId)")
        
        // Create a query to find all messages for this match
        let query = db.collection("chatMessages").whereField("matchId", isEqualTo: matchId)
        
        // Get all matching documents
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error finding messages to delete: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No messages found to delete for match: \(matchId)")
                completion(nil)
                return
            }
            
            print("Found \(documents.count) messages to delete for match: \(matchId)")
            
            // Create a batch operation for efficiency
            let batch = self.db.batch()
            
            // Add all message documents to the batch
            for document in documents {
                print("Adding document \(document.documentID) to delete batch")
                batch.deleteDocument(document.reference)
            }
            
            // Execute the batch
            batch.commit { error in
                if let error = error {
                    print("Error batch deleting messages: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("Successfully deleted all \(documents.count) messages for match: \(matchId)")
                    completion(nil)
                }
            }
        }
    }
    
    // Delete messages by specific users
    func deleteMessagesByUser(userId: String, completion: @escaping (Error?) -> Void) {
        print("Deleting all messages for user: \(userId)")
        
        let senderQuery = db.collection("chatMessages").whereField("senderId", isEqualTo: userId)
        let receiverQuery = db.collection("chatMessages").whereField("receiverId", isEqualTo: userId)
        
        let group = DispatchGroup()
        group.enter()
        
        // Delete messages where user is sender
        senderQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error finding sent messages: \(error.localizedDescription)")
                group.leave()
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                let batch = self.db.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting sent messages: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted sent messages")
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        group.enter()
        // Delete messages where user is receiver
        receiverQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error finding received messages: \(error.localizedDescription)")
                group.leave()
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                let batch = self.db.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting received messages: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted received messages")
                    }
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(nil)
        }
    }
}
