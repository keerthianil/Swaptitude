//
//  OnboardingView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    // Onboarding data
    let pages: [(image: String, title: String, description: String)] = [
        (
            image: "person.2.fill",
            title: "Find Your Perfect Match",
            description: "Connect with people who want to learn what you can teach, and teach what you want to learn."
        ),
        (
            image: "arrow.triangle.2.circlepath",
            title: "Skill Swapping Made Easy",
            description: "No money needed - just exchange your knowledge and talents with others in our community."
        ),
        (
            image: "star.fill",
            title: "Grow Your Skills",
            description: "Learn from real people with real experience, while sharing your own expertise."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background color
            AppColors.secondaryBackground
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        print("Skip button tapped")
                        withAnimation {
                            showOnboarding = false
                        }
                    }) {
                        Text("Skip")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(AppColors.primary)
                            .padding()
                    }
                }
                
                // Header with app logo
                VStack(spacing: 10) {
                    Image("swaptitudeicon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                    
                    Text("SWAPTITUDE")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                }
                .padding(.bottom, 30)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryGradient)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: pages[index].image)
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 20)
                            
                            Text(pages[index].title)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].description)
                                .font(.system(.body, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AppColors.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Next/Get Started button
                Button(action: {
                    print("Button tapped: \(currentPage == pages.count - 1 ? "Get Started" : "Next")")
                    if currentPage == pages.count - 1 {
                        // Last page, proceed to main app
                        withAnimation {
                            showOnboarding = false
                        }
                    } else {
                        // Go to next page
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(AppColors.primaryGradient)
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            .padding(.vertical, 30)
        }
        .onDisappear {
            print("OnboardingView disappeared")
        }
    }
}
