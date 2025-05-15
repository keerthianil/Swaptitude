//
//  HomeView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/9/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct HomeView: View {
    @Binding var isDarkMode: Bool
    @Binding var showProfileDrawer: Bool
    @State private var searchText = ""
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var matchViewModel = MatchViewModel()
    @State private var matchedPostIds = Set<String>()
    @State private var refreshTimer: Timer?
    @State private var showUserProfile = false
    @State private var selectedProfileUserId = ""
    @State private var selectedProfileUserName = ""
    @State private var selectedPost: SkillPost?
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var showNotifications = false

    var body: some View {
        ScrollView {
            // Header
            headerSection
            
            // Welcome banner
            welcomeBanner
            
            // All Posts Section (showing all posts)
            allPostsSection
            
            // Potential Matches Section (showing only matching posts)
            potentialMatchesSection
            
            Spacer()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            // Clean up posts from deleted users first
            postViewModel.cleanUpDeletedUserPosts()
            postViewModel.fetchAllPosts()
            postViewModel.fetchUserPosts()
            matchViewModel.findPotentialMatches()
            loadMatchedPostIds()
               
            // Set up a timer to refresh data periodically
            let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                postViewModel.fetchAllPosts()
                loadMatchedPostIds()
            }
            refreshTimer = timer
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .overlay {
            if matchViewModel.showMatchSuccess, let newMatch = matchViewModel.newMatch {
                MatchNotificationView(
                    match: newMatch,
                    showMatchSuccess: $matchViewModel.showMatchSuccess
                )
            }
        }
        .refreshable {
            // Run cleanup on refresh
            postViewModel.cleanUpDeletedUserPosts()
            postViewModel.fetchAllPosts()
            postViewModel.fetchUserPosts()
            matchViewModel.findPotentialMatches()
            loadMatchedPostIds()
        }
        .onAppear {
            notificationViewModel.fetchNotifications()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationView()
        }
        .sheet(isPresented: $showUserProfile) {
            NavigationView {
                UserProfileDetailView(
                    userId: selectedProfileUserId,
                    userName: selectedProfileUserName,
                    post: selectedPost
                )
            }
        }
    }
    
    // MARK: - View Components
    
    var headerSection: some View {
        HStack {
            // Profile image button to open drawer
            Button(action: {
                withAnimation {
                    showProfileDrawer = true
                }
            }) {
                Image("swaptitudeicon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(10)
            }
            
            Text("SWAPTITUDE")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            Spacer()
            
            // Notification bell button
            Button(action: {
                showNotifications = true
            }) {
                ZStack {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(AppColors.secondaryBackground)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    
                    // Badge if there are unread notifications
                    if notificationViewModel.unreadCount > 0 {
                        Text("\(notificationViewModel.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(.red))
                            .offset(x: 15, y: -15)
                    }
                }
            }
            
            // Dark mode toggle
            Button(action: {
                withAnimation {
                    isDarkMode.toggle()
                }
            }) {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AppColors.secondaryBackground)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
            }
        }
        .padding(.horizontal)
    }
    
    var welcomeBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(AppColors.primaryGradient)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Welcome to Swaptitude!")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Swap skills, sharpen aptitudes")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                NavigationLink(destination: CreatePostView().onDisappear {
                    // Refresh posts when returning from create post
                    postViewModel.fetchAllPosts()
                    postViewModel.fetchUserPosts()
                }) {
                    Text("Create a Post")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                }
                .padding(.top, 5)
            }
            .padding(25)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 180)
        .padding(.horizontal)
    }
    
    var allPosts: [SkillPost] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        // Get all posts except current user's, from valid users only
        return postViewModel.allPosts.filter { post in
            post.userId != currentUserId
        }
    }
    
    var allPostsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Skill Posts")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                // Added refresh button
                Button(action: {
                    postViewModel.fetchAllPosts()
                    loadMatchedPostIds()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            if postViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                    Spacer()
                }
                .padding()
            } else if allPosts.isEmpty {
                HStack {
                    Spacer()
                    Text("No posts available")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                ForEach(allPosts.prefix(5)) { post in
                    SkillCardView(
                        post: post,
                        onConnect: {
                            matchViewModel.createMatch(with: post)
                        },
                        // Only show connect button if categories match AND not already matched
                        showConnectButton: postViewModel.isPostCategoryMatchingUserPosts(post: post) && !isPostAlreadyMatched(post),
                        isAlreadyMatched: isPostAlreadyMatched(post)
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // Get posts that match your categories only AND are not already matched
    var potentialMatches: [SkillPost] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        return postViewModel.allPosts.filter { post in
            post.userId != currentUserId &&
            postViewModel.isPostCategoryMatchingUserPosts(post: post) &&
            !isPostAlreadyMatched(post) // Filter out already matched posts
        }
    }
    
    var potentialMatchesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Potential Matches")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    postViewModel.fetchAllPosts()
                    matchViewModel.findPotentialMatches()
                    loadMatchedPostIds()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal)
            
            if potentialMatches.isEmpty {
                HStack {
                    Spacer()
                    Text("No potential matches found")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(potentialMatches.prefix(3)) { post in
                            HomePotentialMatchView(
                                post: post,
                                onTap: {
                                    showUserProfile(post)
                                },
                                onConnect: {
                                    // Connect with the post
                                    matchViewModel.createMatch(with: post)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
   
    func showUserProfile(_ post: SkillPost) {
        selectedProfileUserId = post.userId
        selectedProfileUserName = post.userName
        selectedPost = post
        showUserProfile = true
    }
    
   
    func isPostAlreadyMatched(_ post: SkillPost) -> Bool {
        guard let postId = post.id else { return false }
        return matchedPostIds.contains(postId)
    }
    
    
    private func loadMatchedPostIds() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Clear current set
        matchedPostIds.removeAll()
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        // Query for matches where user is user1
        group.enter()
        db.collection("matches")
            .whereField("user1Id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching matches (user1): \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    for doc in documents {
                        // Add post IDs if they exist
                        if let user1PostId = doc.data()["user1PostId"] as? String, !user1PostId.isEmpty {
                            self.matchedPostIds.insert(user1PostId)
                        }
                        if let user2PostId = doc.data()["user2PostId"] as? String, !user2PostId.isEmpty {
                            self.matchedPostIds.insert(user2PostId)
                        }
                        
                        // Also track the other user's ID
                        if let user2Id = doc.data()["user2Id"] as? String {
                            self.addPostsFromUser(userId: user2Id)
                        }
                    }
                }
            }
        
        // Query for matches where user is user2
        group.enter()
        db.collection("matches")
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching matches (user2): \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    for doc in documents {
                        // Add post IDs if they exist
                        if let user1PostId = doc.data()["user1PostId"] as? String, !user1PostId.isEmpty {
                            self.matchedPostIds.insert(user1PostId)
                        }
                        if let user2PostId = doc.data()["user2PostId"] as? String, !user2PostId.isEmpty {
                            self.matchedPostIds.insert(user2PostId)
                        }
                        
                        // Also track the other user's ID
                        if let user1Id = doc.data()["user1Id"] as? String {
                            self.addPostsFromUser(userId: user1Id)
                        }
                    }
                }
            }
    }
    
   
    private func addPostsFromUser(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    DispatchQueue.main.async {
                        for doc in documents {
                            self.matchedPostIds.insert(doc.documentID)
                        }
                    }
                }
            }
    }
}

struct PostDetailView: View {
    let post: SkillPost
    let onConnect: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showUserProfile = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with user info
                Button(action: {
                    showUserProfile = true
                }) {
                    HStack {
                        if let profileImagePath = post.userProfileImagePath,
                           let profileImage = ImageManager.shared.loadImage(fromPath: profileImagePath) {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(post.userName)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                            
                            if let location = post.location, !location.isEmpty {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                    
                                    Text(location)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.secondaryBackground)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Skills exchange
                VStack(alignment: .leading, spacing: 15) {
                    Text("Skills Exchange")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Teaches:")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text(post.teach)
                                .font(.system(.title3, design: .rounded))
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
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("Wants to Learn:")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text(post.learn)
                                .font(.system(.title3, design: .rounded))
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
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground)
                )
                
                // Description
                if !post.description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text(post.description)
                            .font(.system(.body, design: .rounded))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.secondaryBackground)
                    )
                }
                
                // Connect button
                PrimaryButton(
                    title: "Connect with \(post.userName)",
                    action: {
                        onConnect()
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Skill Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .sheet(isPresented: $showUserProfile) {
            NavigationView {
                UserProfileDetailView(
                    userId: post.userId,
                    userName: post.userName,
                    post: post
                )
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
