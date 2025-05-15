//
//  User.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//

import Foundation
import FirebaseFirestore
import UIKit

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var username: String
    var profileImagePath: String? 
    var bio: String?
    var isVerified: Bool = false
    var rating: Double = 0.0
    var reviewCount: Int = 0
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case username
        case profileImagePath
        case bio
        case isVerified
        case rating
        case reviewCount
        case createdAt
    }
    
    // Helper computed property to get profile image (not stored in Firestore)
    var profileImage: UIImage? {
        get {
            if let path = profileImagePath {
                return ImageManager.shared.loadImage(fromPath: path)
            }
            // Return default image if no custom image is set
            return UIImage(systemName: "person.circle.fill")
        }
    }
    
    // Helper to get user's formatted rating string
    var ratingDisplay: String {
        if reviewCount == 0 {
            return "Not rated yet"
        } else {
            return String(format: "%.1f", rating)
        }
    }
}
