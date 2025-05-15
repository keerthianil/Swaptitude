//
//  RatingView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Double
    var starSize: CGFloat = 24
    var maxRating: Int = 5
    var isEditable: Bool = true
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: "star.fill")
                    .foregroundColor(star <= Int(rating.rounded()) ? AppColors.primary : Color.gray.opacity(0.3))
                    .font(.system(size: starSize))
                    .onTapGesture {
                        if isEditable {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                rating = Double(star)
                            }
                        }
                    }
                    .scaleEffect(isEditable && star == Int(rating.rounded()) ? 1.1 : 1.0)
                    .animation(.spring(response: 0.1, dampingFraction: 0.7), value: rating)
            }
        }
    }
}
