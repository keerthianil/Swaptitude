//
//  FormField.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/8/25.
//

import SwiftUI

struct FormField: View {
    var title: String
    @Binding var text: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
                    .frame(width: 24)
                
                TextField(title, text: $text)
                    .font(.system(.body, design: .rounded))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
        }
    }
}
