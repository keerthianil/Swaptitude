//
//  SkillBeeMessage.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//

import Foundation

struct SkillBeeMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromBot: Bool
    let timestamp = Date()
}
