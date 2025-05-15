//
//  AddReviewView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct AddReviewView: View {
    let recipientId: String
    let recipientName: String
    let skillTaught: String
    let matchId: String
    
    @StateObject private var viewModel = ReviewViewModel()
    @State private var rating: Double = 3.0
    @State private var comment: String = ""
    @State private var showSuccessAlert = false
    @State private var isEditMode = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.primaryGradient)
                        .frame(height: 120)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text(isEditMode ? "Edit Review" : "Rate \(recipientName)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("for teaching you \(skillTaught)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal)
                
                // Rating stars
                VStack(spacing: 15) {
                    Text("How would you rate the experience?")
                        .font(.system(.headline, design: .rounded))
                    
                    // Animated star rating
                    RatingView(rating: $rating, starSize: 40, isEditable: true)
                        .padding(.vertical, 10)
                    
                    // Rating text feedback
                    Text(ratingFeedback(rating: rating))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(AppColors.primary)
                        .padding(.bottom, 10)
                }
                
                // Review comment
                VStack(alignment: .leading, spacing: 10) {
                    Text("Share your experience (optional)")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                    
                    ZStack(alignment: .topLeading) {
                        if comment.isEmpty {
                            Text("What did you learn? How was the teaching?")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.horizontal, 5)
                                .padding(.top, 8)
                        }
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 120)
                            .font(.system(.body, design: .rounded))
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.secondaryBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .frame(height: 120)
                    .padding(.horizontal)
                }
                
                if viewModel.showError {
                    Text(viewModel.errorMessage)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                
                // Submit button
                PrimaryButton(
                    title: isEditMode ? "Update Review" : "Submit Review",
                    action: submitReview,
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, 30)
                .padding(.top, 20)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(isEditMode ? "Edit Review" : "Leave a Review")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Review Submitted", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your feedback!")
        }
        .onAppear {
            // Check if the user has already reviewed
            if let currentUserId = Auth.auth().currentUser?.uid {
                viewModel.checkIfUserHasReviewed(authorId: currentUserId, recipientId: recipientId) { hasReviewed, reviewId in
                    if hasReviewed, let reviewId = reviewId {
                        // User has already reviewed, fetch the review
                        isEditMode = true
                        viewModel.fetchReview(reviewId: reviewId) { review in
                            if let review = review {
                                // Set the values from the existing review
                                rating = review.rating
                                comment = review.comment
                            }
                        }
                    }
                }
            }
        }
    }
    

    private func submitReview() {
        guard let currentUser = Auth.auth().currentUser else {
            viewModel.errorMessage = "You must be signed in to leave a review"
            viewModel.showError = true
            return
        }
        
        // First fetch the current user's full name from Firestore
        Firestore.firestore().collection("users").document(currentUser.uid).getDocument { snapshot, error in
            // Removed weak self since we're in a struct not a class
            
            if let error = error {
                self.viewModel.errorMessage = error.localizedDescription
                self.viewModel.showError = true
                return
            }
            
            // Get the author's full name
            let authorName: String
            if let userData = try? snapshot?.data(as: User.self) {
                authorName = userData.fullName // Use the actual full name
            } else {
                // Fallback to email or UID if needed
                authorName = currentUser.displayName ?? currentUser.email?.components(separatedBy: "@").first ?? "User"
            }
            
            let review = Review(
                authorId: currentUser.uid,
                authorName: authorName,
                recipientId: self.recipientId,
                recipientName: self.recipientName,
                matchId: self.matchId,
                rating: self.rating,
                comment: self.comment,
                createdAt: Date()
            )
            
            self.viewModel.submitReview(review: review) { success in
                if success {
                    // Review saved successfully
                    self.showSuccessAlert = true
                }
            }
        }
    }
    
    private func ratingFeedback(rating: Double) -> String {
        switch rating {
        case 1:
            return "Poor - Did not meet expectations"
        case 2:
            return "Fair - Below average experience"
        case 3:
            return "Good - Average experience"
        case 4:
            return "Great - Above average experience"
        case 5:
            return "Excellent - Exceeded expectations"
        default:
            return "Select your rating"
        }
    }
}
