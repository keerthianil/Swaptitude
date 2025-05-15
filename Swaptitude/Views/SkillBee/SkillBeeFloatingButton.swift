//
//  SkillBeeFloatingButton.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//

import SwiftUI

struct SkillBeeFloatingButton: View {
    @Binding var isShowingChat: Bool
    @State private var animateButton = false
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 80,
                                         y: UIScreen.main.bounds.height - 200)
    
    var body: some View {
        ZStack {
            Button(action: {
                // Only trigger button tap if not dragging
                if !isDragging {
                    isShowingChat.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, AppColors.primary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                    
                    // Bee emoji without background circle
                    Text("🐝")
                        .font(.system(size: 30))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1) // Add shadow to emoji
                }
                .scaleEffect(animateButton ? 1.1 : 1.0)
                .scaleEffect(isDragging ? 1.15 : 1.0) // Scale up when dragging
            }
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .simultaneousGesture(
                // Use simultaneousGesture to allow both drag and tap
                DragGesture(minimumDistance: 5) // Small minimum distance to distinguish tap from drag
                    .onChanged { value in
                        // Set dragging flag
                        isDragging = true
                        
                        // Update drag offset for smooth movement
                        self.dragOffset = value.translation
                    }
                    .onEnded { value in
                        // Update position with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            // Update final position
                            self.position.x += value.translation.width
                            self.position.y += value.translation.height
                            self.dragOffset = .zero
                            
                            // Keep within screen bounds
                            let buttonRadius: CGFloat = 30
                            let screenWidth = UIScreen.main.bounds.width
                            let screenHeight = UIScreen.main.bounds.height
                            let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets()
                            
                            // Ensure button stays within visible area
                            self.position.x = min(max(buttonRadius, self.position.x), screenWidth - buttonRadius)
                            self.position.y = min(max(buttonRadius + safeAreaInsets.top, self.position.y),
                                                screenHeight - buttonRadius - safeAreaInsets.bottom - 70)
                        }
                        
                        // Reset dragging flag after a delay to prevent accidental tap
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isDragging = false
                        }
                    }
            )
            .onAppear {
                // Start gentle pulsing animation
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animateButton = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
