//
//  MainTabView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
//  MainTabView.swift
//  Swaptitude
//
import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var showProfileDrawer = false
    @State private var showSkillBeeChat = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
    
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView(isDarkMode: $isDarkMode, showProfileDrawer: $showProfileDrawer)
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                NavigationStack {
                    ExploreView()
                }
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)
                
                NavigationStack {
                    CreatePostView()
                }
                .tabItem {
                    Label("Post", systemImage: "plus.square.fill")
                }
                .tag(2)
                
                NavigationStack {
                    MatchesView()
                }
                .tabItem {
                    Label("Matches", systemImage: "person.2.fill")
                }
                .tag(3)
                
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
            }
            .tint(AppColors.primary)
            .preferredColorScheme(isDarkMode ? .dark : .light)

            // Profile side drawer 
            if showProfileDrawer {
                ProfileSideDrawerView(isShowing: $showProfileDrawer)
                    .environmentObject(authViewModel)
                    .zIndex(1)
            }

            // SkillBee floating button that is hidden when chat is open
            if !showSkillBeeChat {
                SkillBeeFloatingButton(isShowingChat: $showSkillBeeChat)
                    .zIndex(2)
            }

            if showSkillBeeChat {
               
                VStack {
                    Spacer()
                    SkillBeeChatView(isPresented: $showSkillBeeChat)
                        .frame(height: 500)
                        .transition(.move(edge: .bottom))
                        .zIndex(4)
                }
                .animation(.spring(), value: showSkillBeeChat)
            }
        }
        .onChange(of: selectedTab) { _ in
            showSkillBeeChat = false
        }
    }
    
}
