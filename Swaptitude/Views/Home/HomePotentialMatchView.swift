//
//  HomePotentialMatchView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/9/25.
//

import SwiftUI
struct HomePotentialMatchView: View {
    let post: SkillPost
    let onTap: () -> Void
    let onConnect: () -> Void
    @State private var showProfileDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                showProfileDetail = true
            }) {
                HStack(spacing: 15) {
                    // Your skill
                    VStack(alignment: .leading, spacing: 5) {
                        Text("You Teach")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.learn)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(width: 110, alignment: .leading)
                    
                    Image(systemName: "arrow.right.arrow.left")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                    
                    // Their skill
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(post.userName) Teaches")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.teach)
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(width: 110, alignment: .leading)
                }
                .padding()
                .frame(height: 80)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add Connect button
            Button(action: onConnect) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Connect")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.primaryGradient)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .frame(width: 320)
        .sheet(isPresented: $showProfileDetail) {
            NavigationView {
                UserProfileDetailView(userId: post.userId, userName: post.userName, post: post)
            }
        }
    }
}
