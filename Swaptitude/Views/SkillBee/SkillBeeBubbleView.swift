//
//  SkillBeeFloatingButton.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/24/25.
//

import SwiftUI

struct SkillBeeBubbleView: View {
    let message: SkillBeeMessage
    
    var body: some View {
        HStack {
            if message.isFromBot {
                Image("skillbee-icon") 
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            } else {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isFromBot ?
                    Color.yellow.opacity(0.2) : AppColors.primary.opacity(0.2))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            
            if !message.isFromBot {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
