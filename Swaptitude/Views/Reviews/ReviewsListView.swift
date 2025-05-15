//
//  ReviewsListView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI
import FirebaseAuth

struct ReviewsListView: View {
    let userId: String
    let userName: String
    
    @StateObject private var viewModel = ReviewViewModel()
    
    var body: some View {
        VStack {
            // Header with rating summary
            VStack(spacing: 8) {
                Text(userName)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                
                HStack {
                    RatingView(rating: .constant(viewModel.userRating), isEditable: false)
                    
                    Text(String(format: "%.1f", viewModel.userRating))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                    
                    Text("(\(viewModel.reviewCount))")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Text("\(viewModel.reviewCount) \(viewModel.reviewCount == 1 ? "Review" : "Reviews")")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
            )
            .padding()
            
            // Reviews list
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .padding()
            } else if viewModel.reviews.isEmpty {
                Text("No reviews yet")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.reviews.sorted(by: { $0.createdAt > $1.createdAt })) { review in
                            ReviewCardView(review: review)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchReviews(forUserId: userId)
        }
    }
}

struct ReviewCardView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // User and rating
            HStack {
                Text(review.isAuthorDeleted ? "Deleted User" : review.authorName)
                    .font(.system(.headline, design: .rounded))
                
                Spacer()
                
                RatingView(rating: .constant(review.rating), starSize: 16, isEditable: false)
            }
            
            // Date
            Text(formatDate(review.createdAt))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.gray)
            
            // Review text
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(.body, design: .rounded))
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
