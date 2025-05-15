//
//  MatchCardView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct MatchCardView: View {
    let match: Match
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image and skill
            ZStack(alignment: .bottomLeading) {
                // Profile image or placeholder
                if let profileImagePath = match.otherUserProfileImageUrl(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                   let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.primaryGradient)
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                
                // User info overlay
                VStack(alignment: .leading, spacing: 5) {
                    Text(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppColors.primary)
                        
                        Text("Verified User")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Match details
            VStack(alignment: .leading, spacing: 15) {
                // Skills exchange
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Teaches")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(match.otherUserTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.arrow.left.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Learns")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(match.otherUserLearn(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                // Match date and action hint
                HStack {
                    Text("Matched \(timeAgoString(from: match.createdAt))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Tap to view details")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(20)
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
        .scaleEffect(isPressed ? 0.97 : 1.0)
              .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
