//
//  Message.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation

struct Message: Identifiable {
    var id: String { return match.id ?? UUID().uuidString }
    let match: Match
    let otherUserName: String
    let otherUserProfileImageUrl: String?
    let lastMessage: String?
    let lastMessageDate: Date?
    let unreadCount: Int
}
