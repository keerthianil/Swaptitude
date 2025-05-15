//
//  ExploreViewModel.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class ExploreViewModel: ObservableObject {
    @Published var posts: [SkillPost] = []
    @Published var filteredPosts: [SkillPost] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var searchText = ""
    
    // Filter options
    @Published var teachFilter = ""
    @Published var learnFilter = ""
    @Published var locationFilter = ""
    
    private let db = Firestore.firestore()
    
    init() {
        fetchPosts()
    }
    
    func fetchPosts() {
        isLoading = true
        
        db.collection("posts")
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.posts = []
                    self.applyFilters()
                    return
                }
                
                self.posts = documents.compactMap { document in
                    try? document.data(as: SkillPost.self)
                }
                
                self.applyFilters()
            }
    }
    
    func applyFilters() {
        var filtered = posts
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { post in
                return post.teach.lowercased().contains(searchText.lowercased()) ||
                       post.learn.lowercased().contains(searchText.lowercased()) ||
                       post.description.lowercased().contains(searchText.lowercased()) ||
                       post.userName.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply teach filter
        if !teachFilter.isEmpty {
            filtered = filtered.filter { post in
                return post.teach.lowercased().contains(teachFilter.lowercased())
            }
        }
        
        // Apply learn filter
        if !learnFilter.isEmpty {
            filtered = filtered.filter { post in
                return post.learn.lowercased().contains(learnFilter.lowercased())
            }
        }
        
        // Apply location filter
        if !locationFilter.isEmpty {
            filtered = filtered.filter { post in
                guard let location = post.location else { return false }
                return location.lowercased().contains(locationFilter.lowercased())
                            }
                        }
                        
                        filteredPosts = filtered
                    }
                    
                    func resetFilters() {
                        teachFilter = ""
                        learnFilter = ""
                        locationFilter = ""
                        searchText = ""
                        applyFilters()
                    }
                }
