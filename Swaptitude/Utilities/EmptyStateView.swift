//
//  EmptyStateView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(AppColors.primary.opacity(0.7))
            
            Text(title)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
