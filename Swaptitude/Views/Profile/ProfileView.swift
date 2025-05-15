//
//  ProfileView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/9/25.
//

import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var reviewViewModel = ReviewViewModel()
    @StateObject private var postViewModel = PostViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingReviews = false
    @State private var showDeleteConfirmation = false
    @State private var postToDelete: SkillPost?
    @State private var showSkillsInventory = false
    @State private var showMeetingsList = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Profile header section
                ProfileHeaderView(
                    authViewModel: authViewModel,
                    showingEditProfile: $showingEditProfile
                )
                
                // Stats section
                ProfileStatsView(
                    postCount: postViewModel.userPosts.count,
                    reviewCount: reviewViewModel.reviews.count,
                    rating: authViewModel.currentUser?.rating ?? 0.0,
                    showingReviews: $showingReviews
                )
                
                // Reviews section (if there are reviews)
                if reviewViewModel.reviews.count > 0 {
                    ProfileReviewsSection(
                        reviews: reviewViewModel.reviews,
                        showingReviews: $showingReviews
                    )
                }
                
                // User posts section
                ProfilePostsSection(
                    viewModel: postViewModel,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    postToDelete: $postToDelete
                )
                
                // Meetings section
                ProfileMeetingsSection(
                    showMeetingsList: $showMeetingsList
                )
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Profile")
        .navigationDestination(isPresented: $showingEditProfile) {
            if let user = authViewModel.currentUser {
                EditProfileView(user: user)
            }
        }
        .navigationDestination(isPresented: $showingReviews) {
            if let userId = authViewModel.currentUser?.id, let userName = authViewModel.currentUser?.fullName {
                ReviewsListView(userId: userId, userName: userName)
            }
        }
        .navigationDestination(isPresented: $showMeetingsList) {
            MeetingsListView()
        }
        .alert("Delete Post", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let post = postToDelete, let postId = post.id {
                    postViewModel.deletePost(postId: postId)
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .alert("Success", isPresented: $postViewModel.showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(postViewModel.successMessage)
        }
        .onAppear {
            // Refresh user data when the view appears
            authViewModel.fetchUser()
            postViewModel.fetchUserPosts()
            
            // Fetch reviews if user ID is available
            if let userId = authViewModel.currentUser?.id {
                reviewViewModel.fetchReviews(forUserId: userId)
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Break out header into separate component
struct ProfileHeaderView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showingEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            // Profile image and header background
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 25)
                    .fill(AppColors.primaryGradient)
                    .frame(height: 150)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                
                // Profile image or placeholder
                if let profileImagePath = authViewModel.currentUser?.profileImagePath,
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
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
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
                Text(authViewModel.currentUser?.fullName ?? "User Name")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .padding(.top, 45)
                
                Text(authViewModel.currentUser?.username ?? "@username")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                
                if let isVerified = authViewModel.currentUser?.isVerified, isVerified {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppColors.primary)
                        
                        Text("Verified")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, 5)
                }
                
                // Rating
                if let rating = authViewModel.currentUser?.rating,
                   let reviewCount = authViewModel.currentUser?.reviewCount {
                    HStack {
                        RatingView(rating: .constant(rating), isEditable: false)
                        
                        Text("(\(reviewCount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 5)
                }
                
                // Bio section
                if let bio = authViewModel.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                }
            }
            
            // Edit profile button
            Button(action: {
                showingEditProfile = true
            }) {
                HStack {
                    Text("Edit Profile")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                    
                    Image(systemName: "pencil")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.primaryGradient)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                )
            }
            .padding(.top, 10)
        }
    }
}

// Stats section
struct ProfileStatsView: View {
    let postCount: Int
    let reviewCount: Int
    let rating: Double
    @Binding var showingReviews: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("\(postCount)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                
                Text("Posts")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Make reviews clickable to show all reviews
            Button(action: {
                showingReviews = true
            }) {
                VStack {
                    Text("\(reviewCount)")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Reviews")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 40)
            
            // Make rating clickable to show all reviews
            Button(action: {
                showingReviews = true
            }) {
                VStack {
                    Text(String(format: "%.1f", rating))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Rating")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Reviews section
struct ProfileReviewsSection: View {
    let reviews: [Review]
    @Binding var showingReviews: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Reviews")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingReviews = true
                }) {
                    Text("See All")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            ForEach(reviews.prefix(2)) { review in
                ReviewCardView(review: review)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Posts section
struct ProfilePostsSection: View {
    @ObservedObject var viewModel: PostViewModel
    @Binding var showDeleteConfirmation: Bool
    @Binding var postToDelete: SkillPost?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Your Posts")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                // Added refresh button
                Button(action: {
                    viewModel.fetchUserPosts()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    .padding()
            } else if viewModel.userPosts.isEmpty {
                Text("You haven't created any posts yet")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.userPosts) { post in
                    PostView(post: post, viewModel: viewModel, isProfileView: true)
                        .padding(.horizontal)
                        .onLongPressGesture {
                            postToDelete = post
                            showDeleteConfirmation = true
                        }
                }
            }
            
            // Create post button
            NavigationLink(destination: CreatePostView()) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create New Post")
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
            .padding(.top, 10)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Meetings section 
struct ProfileMeetingsSection: View {
    @Binding var showMeetingsList: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Scheduled Meetings")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showMeetingsList = true
                }) {
                    Text("See All")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            ScheduledMeetingsPreview()
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    struct ScheduledMeetingsPreview: View {
        @StateObject private var viewModel = MeetingViewModel()
        @State private var showCopiedAlert = false
        @State private var selectedMeetingLink = ""
        
        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
        
        var body: some View {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        .padding()
                } else if viewModel.meetings.isEmpty {
                    Text("No upcoming meetings")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Break down the complex sorting into simpler steps
                    let upcomingMeetings = viewModel.meetings.prefix(2)
                    let sortedMeetings = upcomingMeetings.sorted(by: { $0.startTime < $1.startTime })
                    
                    ForEach(sortedMeetings) { meeting in
                        MeetingPreviewRow(
                            meeting: meeting,
                            dateFormatter: dateFormatter,
                            onCopyLink: {
                                // Only copy if there's a link
                                if !meeting.zoomLink.isEmpty {
                                    UIPasteboard.general.string = meeting.zoomLink
                                    selectedMeetingLink = meeting.zoomLink
                                    showCopiedAlert = true
                                }
                            }
                        )
                        
                        // Link display and copy button
                        if !meeting.zoomLink.isEmpty {
                            HStack {
                                Text(meeting.zoomLink)
                                    .font(.system(.caption, design: .rounded))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                
                                Button(action: {
                                    UIPasteboard.general.string = meeting.zoomLink
                                    selectedMeetingLink = meeting.zoomLink
                                    showCopiedAlert = true
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No meeting link yet")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(6)
                                .padding(.horizontal)
                        }
                        
                        // Only show divider if not the last meeting
                        if meeting.id != sortedMeetings.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchMeetings()
            }
            .alert("Link Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
                Button("Open Link") {
                    if let url = URL(string: selectedMeetingLink), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Meeting link has been copied to clipboard.")
            }
        }
    }
    struct MeetingPreviewRow: View {
        let meeting: MeetingSchedule
        let dateFormatter: DateFormatter
        let onCopyLink: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(meeting.meetingTitle)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.primary)
                    Text(dateFormatter.string(from: meeting.startTime))
                        .font(.system(.subheadline, design: .rounded))
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
