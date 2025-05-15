//
//  MatchModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import Foundation
import FirebaseFirestore

struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var user1Id: String
    var user2Id: String
    var user1Name: String
    var user2Name: String
    var user1ProfileImageUrl: String?
    var user2ProfileImageUrl: String?
    var user1Teach: String
    var user1Learn: String
    var user2Teach: String
    var user2Learn: String
    var createdAt: Date
    var lastMessage: String?
    var lastMessageDate: Date?
    var unreadCount: Int = 0
    var user1PostId: String?
    var user2PostId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id
        case user2Id
        case user1Name
        case user2Name
        case user1ProfileImageUrl
        case user2ProfileImageUrl
        case user1Teach
        case user1Learn
        case user2Teach
        case user2Learn
        case createdAt
        case lastMessage
        case lastMessageDate
        case unreadCount
        case user1PostId
        case user2PostId  
    }
}

extension Match {
    func otherUserId(currentUserId: String) -> String {
        return currentUserId == user1Id ? user2Id : user1Id
    }
    
    func otherUserName(currentUserId: String) -> String {
        return currentUserId == user1Id ? user2Name : user1Name
    }
    
    func otherUserProfileImageUrl(currentUserId: String) -> String? {
        return currentUserId == user1Id ? user2ProfileImageUrl : user1ProfileImageUrl
    }
    
    func otherUserTeach(currentUserId: String) -> String {
        return currentUserId == user1Id ? user2Teach : user1Teach
    }
    
    func otherUserLearn(currentUserId: String) -> String {
        return currentUserId == user1Id ? user2Learn : user1Learn
    }
    
    func myTeach(currentUserId: String) -> String {
        return currentUserId == user1Id ? user1Teach : user2Teach
    }
    
    func myLearn(currentUserId: String) -> String {
        return currentUserId == user1Id ? user1Learn : user2Learn
    }
}
extension Match {
    func otherUserProfileImage(currentUserId: String) -> UIImage? {
        guard let imagePath = otherUserProfileImageUrl(currentUserId: currentUserId) else {
            return UIImage(systemName: "person.circle.fill")
        }
        
        return ImageManager.shared.loadImage(fromPath: imagePath) ?? UIImage(systemName: "person.circle.fill")
    }
}
