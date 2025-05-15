//
//  ColorExtension.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//

import SwiftUI

struct AppColors {
    static let primary = Color("Primary") 
    static let primaryDark = Color(red: 0.85, green: 0.65, blue: 0.0) // Darker yellow
    
    // Gradient colors
    static let gradientStart = Color(red: 0.95, green: 0.75, blue: 0.1)
    static let gradientEnd = Color(red: 0.85, green: 0.65, blue: 0.0)
    
    // Text colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // UI colors
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    
    // Gradient
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [gradientStart, gradientEnd]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
