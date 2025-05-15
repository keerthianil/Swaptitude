//
//  TabButtonView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import SwiftUI

struct TabButtonView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? AppColors.primary : .gray)
                
                Rectangle()
                    .fill(isSelected ? AppColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
