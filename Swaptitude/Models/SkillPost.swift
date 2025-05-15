//
//  SkillPostModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import Foundation
import FirebaseFirestore


struct SkillPost: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userProfileImagePath: String?
    var teach: String
    var teachCategory: String
    var teachProficiency: String
    var learn: String
    var learnCategory: String
    var description: String
    var location: String?
    var createdAt: Date
    var isActive: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case userProfileImagePath
        case teach
        case teachCategory
        case teachProficiency
        case learn
        case learnCategory
        case description
        case location
        case createdAt
        case isActive
    }
    
    //the init from decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        userProfileImagePath = try container.decodeIfPresent(String.self, forKey: .userProfileImagePath)
        teach = try container.decode(String.self, forKey: .teach)
        teachCategory = try container.decodeIfPresent(String.self, forKey: .teachCategory) ?? "other"
        teachProficiency = try container.decodeIfPresent(String.self, forKey: .teachProficiency) ?? "Intermediate"
        learn = try container.decode(String.self, forKey: .learn)
        learnCategory = try container.decodeIfPresent(String.self, forKey: .learnCategory) ?? "other"
        description = try container.decode(String.self, forKey: .description)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }
    
    init(
        id: String? = nil,
        userId: String,
        userName: String,
        userProfileImagePath: String? = nil,
        teach: String,
        teachCategory: String = "other",
        teachProficiency: String = "Intermediate",
        learn: String,
        learnCategory: String = "other",
        description: String,
        location: String? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userProfileImagePath = userProfileImagePath
        self.teach = teach
        self.teachCategory = teachCategory
        self.teachProficiency = teachProficiency
        self.learn = learn
        self.learnCategory = learnCategory
        self.description = description
        self.location = location
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
