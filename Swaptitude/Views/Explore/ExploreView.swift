//
//  ExploreView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/9/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct ExploreView: View {
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var matchViewModel = MatchViewModel()
    @State private var searchText = ""
    @State private var selectedTeachCategory: SkillCategory?
    @State private var selectedLearnCategory: SkillCategory?
    @State private var hasSearched = false
    @State private var showCategoryFilters = false
    @Environment(\.colorScheme) var colorScheme
    
    // Filtered posts computed property
    var filteredPosts: [SkillPost] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        // First filter - remove current user's posts
        var posts = postViewModel.allPosts.filter { $0.userId != currentUserId }
        
        // Apply category filters
        if let teachCategory = selectedTeachCategory {
            posts = posts.filter { $0.teachCategory == teachCategory.id }
        }
        
        if let learnCategory = selectedLearnCategory {
            posts = posts.filter { $0.learnCategory == learnCategory.id }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            posts = posts.filter { post in
                return post.teach.lowercased().contains(searchText.lowercased()) ||
                       post.learn.lowercased().contains(searchText.lowercased()) ||
                       post.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        return posts
    }
    
    func isPostMatchingUserSkills(post: SkillPost) -> Bool {
        return postViewModel.isPostCategoryMatchingUserPosts(post: post)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for skills...", text: $searchText)
                    .font(.system(.body, design: .rounded))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            
            // Category filter button
            HStack {
                Button(action: {
                    showCategoryFilters.toggle()
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                        
                        Text("Categories")
                            .font(.system(.headline, design: .rounded))
                        
                        if selectedTeachCategory != nil || selectedLearnCategory != nil {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.secondaryBackground)
                    )
                }
                
                Spacer()
                
                // Reset filters button
                Button(action: {
                    selectedTeachCategory = nil
                    selectedLearnCategory = nil
                    searchText = ""
                    hasSearched = false
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(AppColors.secondaryBackground)
                        )
                }
            }
            .padding(.horizontal)
            
            // Category filters
            if showCategoryFilters {
                VStack(spacing: 15) {
                    // Teach category
                    VStack(alignment: .leading) {
                        Text("Teaching Category:")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Fix for dark mode category buttons
                                ForEach(SkillCategories.categories, id: \.id) { category in
                                    Button(action: {
                                        if selectedTeachCategory?.id == category.id {
                                            selectedTeachCategory = nil
                                        } else {
                                            selectedTeachCategory = category
                                        }
                                        hasSearched = true
                                    }) {
                                        HStack {
                                            Text("\(category.emoji) \(category.name)")
                                                .font(.system(.subheadline, design: .rounded))
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule()
                                                .fill(selectedTeachCategory?.id == category.id ?
                                                      AppColors.primary :
                                                      Color(UIColor.systemGray5)) // Use system color for dark mode compatibility
                                        )
                                        .foregroundColor(selectedTeachCategory?.id == category.id ?
                                                         Color(UIColor.systemBackground) : // Use system background color for text
                                                         Color(UIColor.label)) // System label color adjusts for dark mode
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Learn category
                    VStack(alignment: .leading) {
                        Text("Learning Category:")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SkillCategories.categories, id: \.id) { category in
                                    Button(action: {
                                        if selectedLearnCategory?.id == category.id {
                                            selectedLearnCategory = nil
                                        } else {
                                            selectedLearnCategory = category
                                        }
                                        hasSearched = true
                                    }) {
                                        HStack {
                                            Text("\(category.emoji) \(category.name)")
                                                .font(.system(.subheadline, design: .rounded))
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule()
                                                .fill(selectedLearnCategory?.id == category.id ? AppColors.primary :  Color(UIColor.systemGray5))
                                        )
                                        .foregroundColor(selectedLearnCategory?.id == category.id ? Color(UIColor.systemBackground) :   Color(UIColor.label))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground.opacity(0.5))
                )
                .padding(.horizontal)
            }
            
            // Results
            VStack(alignment: .leading, spacing: 10) {
                if hasSearched || !searchText.isEmpty {
                    Text("Results (\(filteredPosts.count))")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Fix the layout when no results are shown
                    if filteredPosts.isEmpty {
                        VStack {
                            Spacer()
                            Text("No posts match your search criteria")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .frame(minHeight: 200) // Add minimum height to prevent layout shifting
                    } else {
                        ScrollView {
                            ForEach(filteredPosts) { post in
                                SkillCardView(
                                    post: post,
                                    onConnect: {
                                        matchViewModel.createMatch(with: post)
                                    },
                                    showConnectButton: postViewModel.isPostCategoryMatchingUserPosts(post: post)
                                )
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                        }
                    }
                } else {
                    Text("Browse by Category")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                            ForEach(SkillCategories.categories, id: \.id) { category in
                                Button(action: {
                                    selectedTeachCategory = category
                                    hasSearched = true
                                }) {
                                    VStack {
                                        Text(category.emoji)
                                            .font(.system(size: 40))
                                        
                                        Text(category.name)
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(AppColors.secondaryBackground)
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.top)
        .navigationTitle("Explore")
        .onAppear {
            postViewModel.fetchAllPosts()
            postViewModel.fetchUserPosts()
        }
        .overlay {
            if matchViewModel.showMatchSuccess, let newMatch = matchViewModel.newMatch {
                MatchNotificationView(
                    match: newMatch,
                    showMatchSuccess: $matchViewModel.showMatchSuccess
                )
            }
        }
        .alert(isPresented: $matchViewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(matchViewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
