//
//  ReviewViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth


class ReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var userRating: Double = 0.0
    @Published var reviewCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showSuccess = false
    @Published var userHasReviewed = false
    @Published var existingReview: Review?
    
    private let db = Firestore.firestore()
    
    func fetchReviews(forUserId userId: String) {
        isLoading = true
        
        db.collection("reviews")
            .whereField("recipientId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.reviews = []
                    self.userRating = 0.0
                    self.reviewCount = 0
                    return
                }
                
                self.reviews = documents.compactMap { try? $0.data(as: Review.self) }
                
                // Calculate average rating
                if !self.reviews.isEmpty {
                    let totalRating = self.reviews.reduce(0.0) { $0 + $1.rating }
                    self.userRating = totalRating / Double(self.reviews.count)
                    self.reviewCount = self.reviews.count
                    
                    // Update user document with this rating
                    self.updateUserRating(userId: userId, rating: self.userRating, reviewCount: self.reviewCount)
                } else {
                    self.userRating = 0.0
                    self.reviewCount = 0
                }
                
                // Check if current user has already reviewed
                if let currentUserId = Auth.auth().currentUser?.uid {
                    self.checkIfUserHasReviewed(authorId: currentUserId, recipientId: userId) { hasReviewed, reviewId in
                        self.userHasReviewed = hasReviewed
                        
                        // Load existing review if exists
                        if hasReviewed, let reviewId = reviewId {
                            self.fetchReview(reviewId: reviewId)
                        }
                    }
                }
            }
    }
    
    func fetchReview(reviewId: String, completion: @escaping (Review?) -> Void = { _ in }) {
           db.collection("reviews").document(reviewId).getDocument { [weak self] snapshot, error in
               guard let self = self, let document = snapshot, error == nil, document.exists else {
                   completion(nil)
                   return
               }
               
               do {
                   let review = try document.data(as: Review.self)
                   self.existingReview = review
                   completion(review)
               } catch {
                   print("Error decoding review: \(error.localizedDescription)")
                   completion(nil)
               }
           }
       }
    
    func submitReview(review: Review, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Check if user has already reviewed this match
        checkIfUserHasReviewed(authorId: review.authorId, recipientId: review.recipientId) { [weak self] hasReviewed, existingReviewId in
            guard let self = self else { return }
            
            if hasReviewed, let reviewId = existingReviewId {
                // Update existing review
                self.db.collection("reviews").document(reviewId).updateData([
                    "rating": review.rating,
                    "comment": review.comment,
                    "createdAt": Timestamp(date: Date())
                ]) { error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        completion(false)
                    } else {
                        self.fetchReviews(forUserId: review.recipientId)
                        self.showSuccess = true
                        completion(true)
                    }
                }
            } else {
                // Create new review
                do {
                    try self.db.collection("reviews").addDocument(from: review) { error in
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                            completion(false)
                        } else {
                            self.userHasReviewed = true
                            self.existingReview = review
                            self.fetchReviews(forUserId: review.recipientId)
                            self.showSuccess = true
                            
                            // Create a notification for the review recipient
                            let notification = [
                                "userId": review.recipientId,
                                "type": "newReview",
                                "title": "New Review",
                                "message": "\(review.authorName) left you a \(String(format: "%.1f", review.rating))-star review!",
                                "relatedId": review.recipientId, // Use recipientId as relatedId
                                "isRead": false,
                                "timestamp": FieldValue.serverTimestamp()
                            ] as [String: Any]
                            
                            self.db.collection("notifications").addDocument(data: notification)
                            
                            // Add local notification
                            NotificationManager.shared.scheduleReviewNotification(reviewerName: review.authorName)
                            
                            completion(true)
                        }
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                }
            }
        }
    }
    func checkIfUserHasReviewed(authorId: String, recipientId: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("reviews")
            .whereField("authorId", isEqualTo: authorId)
            .whereField("recipientId", isEqualTo: recipientId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false, nil)
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    completion(true, documents[0].documentID)
                } else {
                    completion(false, nil)
                }
            }
    }
    
    
    private func updateUserRating(userId: String, rating: Double, reviewCount: Int) {
        db.collection("users").document(userId).updateData([
            "rating": rating,
            "reviewCount": reviewCount
        ]) { error in
            if let error = error {
                print("Error updating user rating: \(error.localizedDescription)")
            }
        }
    }
  
    func updateUserRatingAfterDeletion(userId: String) {
        // Recalculate user rating after a review is deleted
        db.collection("reviews")
            .whereField("recipientId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching reviews: \(error.localizedDescription)")
                    return
                }
                
                let reviews = snapshot?.documents.compactMap { try? $0.data(as: Review.self) } ?? []
                
                // Update rating
                if reviews.isEmpty {
                    self.updateUserRating(userId: userId, rating: 0.0, reviewCount: 0)
                } else {
                    let totalRating = reviews.reduce(0.0) { $0 + $1.rating }
                    let newRating = totalRating / Double(reviews.count)
                    self.updateUserRating(userId: userId, rating: newRating, reviewCount: reviews.count)
                }
            }
    }
}
