//
//  Review.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var recipientId: String
    var recipientName: String
    var matchId: String
    var rating: Double
    var comment: String
    var createdAt: Date
    var isAuthorDeleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case authorName
        case recipientId
        case recipientName
        case matchId
        case rating
        case comment
        case createdAt
        case isAuthorDeleted
    }
}
