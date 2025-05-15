//
//  PotentialMatchCardView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import SwiftUI

struct PotentialMatchCardView: View {
    let post: SkillPost
    let onConnect: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image and skill
            ZStack(alignment: .bottomLeading) {
                // Profile image or placeholder
                if let profileImagePath = post.userProfileImagePath,
                   let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.primary, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                
                // User info
                VStack(alignment: .leading, spacing: 5) {
                    Text(post.userName)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let location = post.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(AppColors.primary)
                            
                            Text(location)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Post details
            VStack(alignment: .leading, spacing: 15) {
                // Skills exchange
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Teaches")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.teach)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.arrow.left.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Wants to Learn")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.learn)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 5)
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                // Connect button
                Button {
                    print("Connect button tapped for post: \(post.id ?? "")")
                    onConnect()
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Connect")
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.primaryGradient)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle()) 
            }
            .padding(20)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
    }
}
