//
//  PrimaryButton.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var isLoading: Bool = false
    var fullWidth: Bool = true
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, fullWidth ? 0 : 30)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.primaryGradient)
                    
                    // 3D effect
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.primaryGradient)
                        .opacity(0.4)
                        .blur(radius: 3)
                        .offset(x: 0, y: 4)
                        .mask(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        )
                }
            )
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}
