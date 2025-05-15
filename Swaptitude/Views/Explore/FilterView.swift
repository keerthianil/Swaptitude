//
//  FilterView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/6/25.
//
import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var teachFilterTemp: String
    @State private var learnFilterTemp: String

    init(viewModel: ExploreViewModel) {
        self.viewModel = viewModel
        _teachFilterTemp = State(initialValue: viewModel.teachFilter)
        _learnFilterTemp = State(initialValue: viewModel.learnFilter)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Header
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.primaryGradient)
                        .frame(height: 120)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    VStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("Filter Posts")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                // Filter form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Teaching Skills")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                    
                    CustomTextField(
                        placeholder: "Filter by teaching skill",
                        text: $teachFilterTemp,
                        icon: "lightbulb.fill"
                    )
                    .padding(.horizontal)
                    
                    Text("Learning Skills")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                    
                    CustomTextField(
                        placeholder: "Filter by learning skill",
                        text: $learnFilterTemp,
                        icon: "book.fill"
                    )
                    .padding(.horizontal)
                }
                Spacer()
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.resetFilters()
                        dismiss()
                    }) {
                        Text("Reset Filters")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color.gray)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            )
                    }
                    
                    Button(action: {
                        viewModel.teachFilter = teachFilterTemp
                        viewModel.learnFilter = learnFilterTemp
                        viewModel.applyFilters()
                        dismiss()
                    }) {
                        Text("Apply Filters")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.primaryGradient)
                            )
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
