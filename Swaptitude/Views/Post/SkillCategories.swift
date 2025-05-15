//
//  SkillCategories.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/10/25.
//

import Foundation

enum ProficiencyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case expert = "Expert"
}

struct SkillCategory: Identifiable, Hashable {
    let id: String
    let name: String
    var emoji: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SkillCategory, rhs: SkillCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SkillCategories {
    static let categories: [SkillCategory] = [
        SkillCategory(id: "music", name: "Music", emoji: "🎵"),
        SkillCategory(id: "languages", name: "Languages", emoji: "🗣️"),
        SkillCategory(id: "technology", name: "Technology", emoji: "💻"),
        SkillCategory(id: "cooking", name: "Cooking", emoji: "🍳"),
        SkillCategory(id: "art", name: "Art & Crafts", emoji: "🎨"),
        SkillCategory(id: "sports", name: "Sports & Fitness", emoji: "🏋️"),
        SkillCategory(id: "dance", name: "Dance", emoji: "💃"),
        SkillCategory(id: "academics", name: "Academics", emoji: "📚"),
        SkillCategory(id: "business", name: "Business & Finance", emoji: "💼"),
        SkillCategory(id: "photography", name: "Photography", emoji: "📷"),
        SkillCategory(id: "gaming", name: "Gaming", emoji: "🎮"),
        SkillCategory(id: "gardening", name: "Gardening", emoji: "🌱"),
        SkillCategory(id: "diy", name: "DIY & Home", emoji: "🔨"),
        SkillCategory(id: "writing", name: "Writing", emoji: "✍️"),
        SkillCategory(id: "other", name: "Other", emoji: "🔄")
    ]
    
    static func getCategory(byId id: String) -> SkillCategory? {
        return categories.first { $0.id == id }
    }
    
    static func getCategory(byName name: String) -> SkillCategory? {
        return categories.first { $0.name.lowercased() == name.lowercased() }
    }
}
