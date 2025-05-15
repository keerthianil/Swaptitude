//
//  PostView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct PostView: View {
    let post: SkillPost
    @ObservedObject var viewModel: PostViewModel
    @State private var showDeleteConfirmation = false
    let isProfileView: Bool
    
    init(post: SkillPost, viewModel: PostViewModel, isProfileView: Bool = false) {
        self.post = post
        self.viewModel = viewModel
        self.isProfileView = isProfileView
    }
    
    var isCurrentUserPost: Bool {
        return post.userId == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with user info
            HStack(spacing: 10) {
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
                
                Spacer()
                
                // Delete option (only for current user's posts in profile view)
                if isCurrentUserPost && isProfileView {
                    Button(action: {
                        print("Delete button pressed for post: \(post.id ?? "unknown")")
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                }
            }
            
            // Skills information
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("I'll Teach:")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.teach)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("I Want to Learn:")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                        
                        Text(post.learn)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                
                // Description if available
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(.body, design: .rounded))
                        .padding(.top, 5)
                }
                
                // Location if available
                if let location = post.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppColors.primary)
                        
                        Text(location)
                            .font(.system(.subheadline, design: .rounded))
                    }
                    .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
        .alert("Delete Post", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let postId = post.id {
                    print("Deleting post with ID: \(postId)")
                    viewModel.deletePost(postId: postId)
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? Any matches related to this post will also be affected.")
        }
        // Alert to show success messages from viewModel
        .onChange(of: viewModel.showSuccess) { newValue in
            if newValue {
                print("Success alert showing: \(viewModel.successMessage)")
            }
        }
    }
    
    func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
