//
//  SkillCardView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/9/25.
//

import SwiftUI
import FirebaseAuth

struct SkillCardView: View {
    let post: SkillPost
    let onConnect: (() -> Void)?
    let showConnectButton: Bool
    let isAlreadyMatched: Bool
    @State private var showProfileDetail = false
    
    init(post: SkillPost,
         onConnect: (() -> Void)? = nil,
         showConnectButton: Bool = true,
         isAlreadyMatched: Bool = false) {
        self.post = post
        self.onConnect = onConnect
        self.showConnectButton = showConnectButton
        self.isAlreadyMatched = isAlreadyMatched
    }
    
    var body: some View {
        Button(action: {
            showProfileDetail = true
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // User info
                HStack {
                    if let profileImagePath = post.userProfileImagePath,
                       let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.userName)
                            .font(.system(.headline, design: .rounded))
                        
                        Text(timeAgoString(from: post.createdAt))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                // Skills
                VStack(alignment: .leading, spacing: 10) {
                    // Teach skill with category and proficiency
                    VStack(alignment: .leading, spacing: 5) {
                        Text("I'll Teach:")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(post.teach)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Category badge
                            if let category = SkillCategories.getCategory(byId: post.teachCategory) {
                                Text("\(category.emoji) \(category.name)")
                                    .font(.system(.caption, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                    )
                            }
                            
                            // Proficiency badge - if available
                            Text(post.teachProficiency)
                                .font(.system(.caption, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(proficiencyColor(post.teachProficiency))
                                )
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Learn skill with category
                    VStack(alignment: .leading, spacing: 5) {
                        Text("I Want to Learn:")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(post.learn)
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Category badge
                            if let category = SkillCategories.getCategory(byId: post.learnCategory) {
                                Text("\(category.emoji) \(category.name)")
                                    .font(.system(.caption, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.gray.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                
                // Description if not empty
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding(.top, 5)
                }
                
                if onConnect != nil && post.userId != Auth.auth().currentUser?.uid {
                    Group {
                        if isAlreadyMatched {
                            Text("Already Matched")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.green)
                                        .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                                )
                        } else if showConnectButton {
                            Button(action: {
                                onConnect?()
                            }) {
                                Text("Connect")
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
                        } else {
                            Text("Skills don't match")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.gray.opacity(0.3))
                                )
                        }
                    }
                    .padding(.top, 10) // Apply padding to the Group
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showProfileDetail) {
            NavigationView {
                UserProfileDetailView(userId: post.userId, userName: post.userName, post: post)
            }
        }
    }
    
    // Color based on proficiency level
    func proficiencyColor(_ proficiency: String) -> Color {
        switch proficiency.lowercased() {
        case "beginner":
            return .blue
        case "intermediate":
            return .green
        case "expert":
            return .orange
        default:
            return .gray
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
