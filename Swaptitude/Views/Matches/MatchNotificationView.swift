//
//  MatchNotificationView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct MatchNotificationView: View {
    let match: Match
    @Binding var showMatchSuccess: Bool
    @State private var opacity = 0.0
    @State private var scale = 0.7
    @State private var rotation = 0.0
    @State private var showParticles = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            // Match content
            VStack(spacing: 25) {
                // Header animation
                VStack(spacing: 0) {
                    Text("IT'S A")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    
                    Text("SWAP!")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.primary)
                        .shadow(color: AppColors.primary.opacity(0.6), radius: 10, x: 0, y: 0)
                }
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0.5)) {
                        rotation = 360.0
                    }
                }
                
                // Profile images
                HStack(spacing: -20) {
                    // Current user image
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .frame(width: 110, height: 110)
                    }
                    .offset(x: showParticles ? -40 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showParticles)
                    
                    // Other user image
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppColors.primary, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        if let otherUserImagePath = match.otherUserProfileImageUrl(currentUserId: Auth.auth().currentUser?.uid ?? ""),
                           let otherUserImage = ImageManager.shared.loadImage(fromPath: otherUserImagePath) {
                            Image(uiImage: otherUserImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .frame(width: 110, height: 110)
                        }
                    }
                    .offset(x: showParticles ? 40 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showParticles)
                }
                .zIndex(1)
                
                // Connection explanation
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        VStack(alignment: .trailing) {
                            Text("You teach")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text(match.myTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Image(systemName: "arrow.right.arrow.left")
                            .font(.title)
                            .foregroundColor(AppColors.primary)
                        
                        VStack(alignment: .leading) {
                            Text("They teach")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text(match.otherUserTeach(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 20)
                    
                    Text("Perfect skill match with")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Text(match.otherUserName(currentUserId: Auth.auth().currentUser?.uid ?? ""))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(UIColor.systemBackground).opacity(0.15))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .blur(radius: 0.5)
                )
                .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 15) {
                    // Button to send message (from MatchNotificationView)
                    Button(action: {
                        presentChatView()
                    }) {
                        HStack {
                            Text("Send Message")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            
                            Image(systemName: "message.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.primaryGradient)
                                .shadow(color: AppColors.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // View profile button (from MatchAnimationView)
                    NavigationLink(destination: MatchDetailView(match: match, viewModel: MatchViewModel())) {
                        HStack {
                            Text("View Profile")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            
                            Image(systemName: "person.fill")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.primaryGradient.opacity(0.8))
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                    }
                    
                    // Keep browsing button
                    Button(action: {
                        withAnimation {
                            showMatchSuccess = false
                        }
                    }) {
                        Text("Keep Browsing")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .padding(.bottom, 50)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Animate appearance
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    opacity = 1.0
                    scale = 1.0
                }
                
                // Trigger particles effect after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showParticles = true
                    }
                }
            }
            
            // Celebration particles
            if showParticles {
                ParticlesView()
            }
        }
    }
    
    // Use UIKit to present the ChatView
    private func presentChatView() {
        // Dismiss the match animation
        showMatchSuccess = false
        
        // Create chat view
        let chatView = ChatView(match: match)
        
        // Present using UIKit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let hostingController = UIHostingController(rootView:
                    NavigationView {
                        chatView
                    }
                )
                rootViewController.present(hostingController, animated: true)
            }
        }
    }
}

// Particle effect views
struct ParticlesView: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .pink, .purple, AppColors.primary]
    let particleCount = 50
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                ParticleView(
                    color: colors.randomElement() ?? .blue,
                    startPosition: randomStartPosition(),
                    endPosition: randomEndPosition()
                )
            }
        }
    }
    
    func randomStartPosition() -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        return CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: -50...0)
        )
    }
    
    func randomEndPosition() -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        return CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: screenHeight-50...screenHeight+100)
        )
    }
}

struct ParticleView: View {
    let color: Color
    let startPosition: CGPoint
    let endPosition: CGPoint
    
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    
    init(color: Color, startPosition: CGPoint, endPosition: CGPoint) {
        self.color = color
        self.startPosition = startPosition
        self.endPosition = endPosition
        self._position = State(initialValue: startPosition)
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
            .position(x: position.x, y: position.y)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeOut(duration: Double.random(in: 2...3)).delay(Double.random(in: 0...0.5))) {
                    position = endPosition
                    rotation = Double.random(in: 180...720)
                    scale = 1.0
                }
            }
    }
}
