//
//  MatchDetailView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct MatchDetailView: View {
    let match: Match
    @StateObject private var reviewViewModel = ReviewViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @ObservedObject var viewModel: MatchViewModel
    @State private var showAddReview = false
    @State private var showUnmatchConfirmation = false
    @State private var hasReviewedUser = false
    @State private var showReviews = false
    @Environment(\.dismiss) var dismiss
    
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
                    if let profileImagePath = match.otherUserProfileImageUrl(currentUserId: Auth.auth().currentUser?.uid ?? ""),
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
                        // Updated placeholder for better visibility in dark mode
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
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
                    Text(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.top, 45)
                    
                    Text(timeAgoString(from: match.createdAt))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                        
                    // Rating
                    Button(action: {
                        showReviews = true
                    }) {
                        HStack {
                            RatingView(rating: .constant(reviewViewModel.userRating), starSize: 20, isEditable: false)
                            
                            Text("(\(reviewViewModel.reviewCount))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 5)
                }
                
                // Skills exchange card
                VStack(spacing: 20) {
                    Text("Skill Exchange")
                        .font(.system(.headline, design: .rounded))
                        .padding(.top, 5)
                    
                    HStack(spacing: 20) {
                        // Your skills
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("You Teach:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(match.myTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("You Learn:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(match.myLearn(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 70)
                        
                        // Their skills
                        VStack(alignment: .leading, spacing: 15) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("They Teach:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(match.otherUserTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("They Learn:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.gray)
                                
                                Text(match.otherUserLearn(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 15) {
                    // Message button
                        NavigationLink(destination: ChatView(match: match)) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Send Message")
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
                        .padding(.horizontal)
                    
                    // Leave a review button - updated for better visibility in dark mode
                        Button(action: {
                            showAddReview = true
                        }) {
                            HStack {
                                Image(systemName: hasReviewedUser ? "pencil" : "star.fill")
                                Text(hasReviewedUser ? "Edit Review" : "Leave a Review")
                            }
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(LinearGradient(
                                        colors: [Color.orange.opacity(0.8), Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Unmatch button
                        Button(action: {
                            showUnmatchConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.minus")
                                Text("Unmatch")
                            }
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.red.opacity(0.8))
                                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal)
                  
                    // Reviews section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Reviews")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                showReviews = true
                            }) {
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
                        } else {
                            // Show 2 most recent reviews
                            ForEach(reviewViewModel.reviews.prefix(2)) { review in
                                ReviewCardView(review: review)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
        .alert("Unmatch", isPresented: $showUnmatchConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Unmatch", role: .destructive) {
                if let matchId = match.id {
                    viewModel.unmatchUsers(matchId: matchId) { success in
                        if success {
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to unmatch with \(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))?")
        }
        .sheet(isPresented: $showAddReview) {
            NavigationView {
                AddReviewView(
                    recipientId: match.otherUserId(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                    recipientName: match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                    skillTaught: match.otherUserTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                    matchId: match.id ?? ""
                )
            }
        }
        .navigationDestination(isPresented: $showReviews) {
            ReviewsListView(
                userId: match.otherUserId(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                userName: match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? "")
            )
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func loadUserData() {
        let otherUserId = match.otherUserId(currentUserId: Auth.auth().currentUser?.uid ?? "")
        
        // Check if user has already reviewed
        if let currentUserId = Auth.auth().currentUser?.uid {
            reviewViewModel.checkIfUserHasReviewed(authorId: currentUserId, recipientId: otherUserId) { hasReviewed, _ in
                hasReviewedUser = hasReviewed
            }
        }
        
        // Fetch reviews to get rating
        reviewViewModel.fetchReviews(forUserId: otherUserId)
    }
}
