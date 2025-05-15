//
//  Notification.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/18/25.
//

import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case newMatch
    case newMessage
    case newReview
}

struct UserNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var type: String
    var title: String
    var message: String
    var relatedId: String?
    var isRead: Bool = false
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case title
        case message
        case relatedId
        case isRead
        case timestamp
    }
}
