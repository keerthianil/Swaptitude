//
//  UserProfileDetailView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/17/25.
//

import Foundation
import SwiftUI
import Firebase

struct UserProfileDetailView: View {
    let userId: String
    let userName: String
    let post: SkillPost?
    
    @StateObject private var reviewViewModel = ReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAllReviews = false
    
    init(userId: String, userName: String, post: SkillPost? = nil) {
        self.userId = userId
        self.userName = userName
        self.post = post
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile header
                ZStack(alignment: .bottom) {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.primaryGradient)
                        .frame(height: 150)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    // Profile image
                    if let profileImagePath = post?.userProfileImagePath,
                       let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .background(Circle().fill(.white).frame(width: 124, height: 124))
                            .shadow(radius: 5)
                            .offset(y: 40)
                    } else {
                        // Modified placeholder to work in both light and dark mode
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemBackground))
                                .frame(width: 124, height: 124)
                                .shadow(radius: 5)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 90))
                                .foregroundColor(AppColors.primary)
                        }
                        .offset(y: 40)
                    }
                }
                .padding(.horizontal)
                
                // User info
                VStack(spacing: 5) {
                    Text(userName)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.top, 45)
                    
                    // Rating
                    HStack {
                        RatingView(rating: .constant(reviewViewModel.userRating), starSize: 20, isEditable: false)
                        
                        Text("(\(reviewViewModel.reviewCount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
                
                // Post details if available
                if let post = post {
                    VStack(spacing: 20) {
                        Text("Skills Offered")
                            .font(.system(.headline, design: .rounded))
                            .padding(.top, 5)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Teaches:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(post.teach)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                
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
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Wants to Learn:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(post.learn)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                
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
                            
                            if !post.description.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Description:")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.gray)
                                    
                                    Text(post.description)
                                        .font(.system(.body, design: .rounded))
                                }
                                .padding(.top, 10)
                            }
                            
                            if let location = post.location, !location.isEmpty {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                    
                                    Text(location)
                                        .font(.system(.subheadline, design: .rounded))
                                }
                                .padding(.top, 10)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.secondaryBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                
                // Reviews section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Reviews")
                            .font(.system(.headline, design: .rounded))
                        
                        Spacer()
                        
                        NavigationLink(destination: ReviewsListView(userId: userId, userName: userName)) {
                            Text("See All")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    if reviewViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .padding()
                    } else if reviewViewModel.reviews.isEmpty {
                        Text("No reviews yet")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Show 2-3 most recent reviews
                        ForEach(reviewViewModel.reviews.prefix(3)) { review in
                            ReviewCardView(review: review)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showAllReviews) {
                ReviewsListView(userId: userId, userName: userName)
            }
            .onAppear {
                reviewViewModel.fetchReviews(forUserId: userId)
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
    }

