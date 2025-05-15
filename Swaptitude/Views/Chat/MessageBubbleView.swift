//
//  MessageBubbleView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
            HStack {
                if message.isFromCurrentUser {
                    Spacer()
                    
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundColor(.black)
                        .background(
                            // 3D effect with gradient and shadow using app's yellow color
                            ZStack {
                                BubbleShape(isFromCurrentUser: true)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.white, AppColors.primary.opacity(0.9)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                
                                // Inner highlight for 3D effect
                                BubbleShape(isFromCurrentUser: true)
                                    .fill(Color.white.opacity(0.3))
                                    .padding(1)
                                    .mask(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.7), Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: UnitPoint(x: 0.4, y: 0.6)
                                        )
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                } else {
                   
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundColor(.primary)
                        .background(
                            // 3D effect with gradient and shadow
                            ZStack {
                                BubbleShape(isFromCurrentUser: false)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color(UIColor.systemGray6), Color(UIColor.systemGray5)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                
                                // Inner highlight for 3D effect
                                BubbleShape(isFromCurrentUser: false)
                                    .fill(Color.white.opacity(0.3))
                                    .padding(1)
                                    .mask(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.7), Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: UnitPoint(x: 0.4, y: 0.6)
                                        )
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    
                    Spacer()
                }
            }
            
            // Time below the message
            Text(formatTime(date: message.timestamp))
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.top, 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BubbleShape: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 20
        let smallCornerRadius: CGFloat = 4
        
        var path = Path()
        
        if isFromCurrentUser {
            // Bottom right corner is more rounded
            let trCornerRadius: CGFloat = 8
            
            path.move(to: CGPoint(x: width - trCornerRadius, y: height))
            
            // Bottom right corner
            path.addQuadCurve(
                to: CGPoint(x: width, y: height - trCornerRadius),
                control: CGPoint(x: width, y: height)
            )
            
            // Right side
            path.addLine(to: CGPoint(x: width, y: cornerRadius))
            
            // Top right corner - more rounded
            path.addQuadCurve(
                to: CGPoint(x: width - cornerRadius, y: 0),
                control: CGPoint(x: width, y: 0)
            )
            
            // Top side
            path.addLine(to: CGPoint(x: cornerRadius, y: 0))
            
            // Top left corner - fully rounded
            path.addQuadCurve(
                to: CGPoint(x: 0, y: cornerRadius),
                control: CGPoint(x: 0, y: 0)
            )
            
            // Left side
            path.addLine(to: CGPoint(x: 0, y: height - cornerRadius))
            
            // Bottom left corner - fully rounded
            path.addQuadCurve(
                to: CGPoint(x: cornerRadius, y: height),
                control: CGPoint(x: 0, y: height)
            )
            
            // Bottom side
            path.addLine(to: CGPoint(x: width - trCornerRadius, y: height))
            
        } else {
            // Bottom left corner is more rounded
            let tlCornerRadius: CGFloat = 8
            
            path.move(to: CGPoint(x: tlCornerRadius, y: height))
            
            // Bottom side
            path.addLine(to: CGPoint(x: width - cornerRadius, y: height))
            
            // Bottom right corner
            path.addQuadCurve(
                to: CGPoint(x: width, y: height - cornerRadius),
                control: CGPoint(x: width, y: height)
            )
            
            // Right side
            path.addLine(to: CGPoint(x: width, y: cornerRadius))
            
            // Top right corner
            path.addQuadCurve(
                to: CGPoint(x: width - cornerRadius, y: 0),
                control: CGPoint(x: width, y: 0)
            )
            
            // Top side
            path.addLine(to: CGPoint(x: cornerRadius, y: 0))
            
            // Top left corner
            path.addQuadCurve(
                to: CGPoint(x: 0, y: cornerRadius),
                control: CGPoint(x: 0, y: 0)
            )
            
            // Left side
            path.addLine(to: CGPoint(x: 0, y: height - tlCornerRadius))
            
            // Bottom left corner - slightly different curve
            path.addQuadCurve(
                to: CGPoint(x: tlCornerRadius, y: height),
                control: CGPoint(x: 0, y: height)
            )
        }
        
        path.closeSubpath()
        return path
    }
}
