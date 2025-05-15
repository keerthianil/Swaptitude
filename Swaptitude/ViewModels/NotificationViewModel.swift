//
//  NotificationViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/18/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class NotificationViewModel: ObservableObject {
    @Published var notifications: [UserNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        // Remove existing listener
        listener?.remove()
        
        // Set up real-time listener
        listener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.notifications = []
                    self.unreadCount = 0
                    return
                }
                
                self.notifications = documents.compactMap { try? $0.data(as: UserNotification.self) }
                self.unreadCount = self.notifications.filter { !$0.isRead }.count
            }
    }
    
    func markAsRead(notificationId: String) {
        db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            }
        }
    }
    
    func markAllAsRead() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get all unread notifications
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                let batch = self?.db.batch()
                
                for document in documents {
                    batch?.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("Error marking all notifications as read: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    func deleteNotification(notificationId: String) {
        db.collection("notifications").document(notificationId).delete { error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
            }
        }
    }
    
    func clearAllNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                let batch = self?.db.batch()
                
                for document in documents {
                    batch?.deleteDocument(document.reference)
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("Error clearing all notifications: \(error.localizedDescription)")
                    }
                }
            }
    }
}
