//
//  Message.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var matchId: String
    var senderId: String
    var receiverId: String
    var content: String
    var timestamp: Date
    var isRead: Bool = false
    
    // Computed property to determine if message is from current user
    var isFromCurrentUser: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return senderId == currentUserId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId
        case senderId
        case receiverId
        case content
        case timestamp
        case isRead
    }
}
