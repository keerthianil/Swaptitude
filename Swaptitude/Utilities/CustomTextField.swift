//
//  CustomTextField.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import SwiftUI
import UIKit

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(.body, design: .rounded))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.oneTimeCode) // This prevents password suggestions
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(.body, design: .rounded))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(placeholder.contains("Email") ? .emailAddress : .none)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        )
    }
}

