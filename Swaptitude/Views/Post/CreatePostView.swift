//
//  CreatePostView.swift
//  Swaptitude
//
//  Created by Keerthi Reddy on 4/7/25.
//
import SwiftUI
import Firebase
import FirebaseAuth

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PostViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var teach = ""
    @State private var selectedTeachCategory: SkillCategory = SkillCategories.categories[0]
    @State private var selectedTeachProficiency: ProficiencyLevel = .intermediate
    
    @State private var learn = ""
    @State private var selectedLearnCategory: SkillCategory = SkillCategories.categories[0]
    
    @State private var description = ""
    @State private var location = ""
    @State private var showSuccessAlert = false
    
    @State private var showTeachCategoryPicker = false
    @State private var showLearnCategoryPicker = false
    
    // Function to clear all form fields
    private func clearFormFields() {
        teach = ""
        learn = ""
        description = ""
        location = ""
        selectedTeachCategory = SkillCategories.categories[0]
        selectedLearnCategory = SkillCategories.categories[0]
        selectedTeachProficiency = .intermediate
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header image
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.primaryGradient)
                        .frame(height: 150)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        Text("Create Skill Swap")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    Text("Note: Posts cannot be edited after creation. You can only delete and recreate them.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    // Teaching Section
                    Text("What can you teach?")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                    
                    VStack(spacing: 15) {
                        // Category selection
                        HStack {
                            Text("Category:")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showTeachCategoryPicker = true
                            }) {
                                HStack {
                                    Text("\(selectedTeachCategory.emoji) \(selectedTeachCategory.name)")
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AppColors.secondaryBackground)
                                )
                            }
                        }
                        
                        // Specific skill
                        TextField("Specific skill (e.g. Guitar, French, Python)", text: $teach)
                            .font(.system(.body, design: .rounded))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.secondaryBackground)
                            )
                        
                        // Proficiency level
                        HStack {
                            Text("Your level:")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Picker("Proficiency", selection: $selectedTeachProficiency) {
                                ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Learning Section
                    Text("What do you want to learn?")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                        .padding(.top, 10)
                    
                    VStack(spacing: 15) {
                        // Category selection
                        HStack {
                            Text("Category:")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showLearnCategoryPicker = true
                            }) {
                                HStack {
                                    Text("\(selectedLearnCategory.emoji) \(selectedLearnCategory.name)")
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AppColors.secondaryBackground)
                                )
                            }
                        }
                        
                        // Specific skill
                        TextField("Specific skill (e.g. Piano, Spanish, Design)", text: $learn)
                            .font(.system(.body, design: .rounded))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.secondaryBackground)
                            )
                    }
                    .padding(.horizontal)
                    
                    Text("Describe your swap")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                        .padding(.top, 10)
                    
                    descriptionTextEditor
                        .padding(.horizontal)
                    
                    Text("Your location (optional)")
                        .font(.system(.headline, design: .rounded))
                        .padding(.leading)
                    
                    CustomTextField(
                        placeholder: "City (e.g. New York)",
                        text: $location,
                        icon: "mappin.and.ellipse"
                    )
                    .padding(.horizontal)
                }
                
                // Error message
                if viewModel.showError && !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
                
                // Post button
                PrimaryButton(
                    title: "Post Skill Swap",
                    action: {
                        if validateForm() {
                            print("Form validated, creating post...")
                            viewModel.createPostWithCategory(
                                teach: teach,
                                teachCategory: selectedTeachCategory.id,
                                teachProficiency: selectedTeachProficiency.rawValue,
                                learn: learn,
                                learnCategory: selectedLearnCategory.id,
                                description: description,
                                location: location.isEmpty ? nil : location
                            ) { success in
                                print("Post creation completed, success: \(success)")
                                if success {
                                    // Clear form fields after successful post
                                    clearFormFields()
                                    showSuccessAlert = true
                                    
                                    // Auto-dismiss after a short delay (to show success message)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                    },
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .alert("Post Created", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                // Clear form fields and dismiss
                clearFormFields()
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .navigationTitle("Create Post")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTeachCategoryPicker) {
            CategoryPickerView(
                selectedCategory: $selectedTeachCategory
            )
        }
        .sheet(isPresented: $showLearnCategoryPicker) {
            CategoryPickerView(
                selectedCategory: $selectedLearnCategory
            )
        }
        .onAppear {
            // Clean up any posts from deleted users when this view appears
            viewModel.fetchValidUsers()
        }
    }
    
    private var descriptionTextEditor: some View {
        ZStack(alignment: .topLeading) {
            if description.isEmpty {
                Text("Describe your experience level and what you're looking for...")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal, 5)
                    .padding(.top, 8)
            }
            
            TextEditor(text: $description)
                .frame(minHeight: 100)
                .font(.system(.body, design: .rounded))
                .padding(5)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(height: 120)
    }
    
    private func validateForm() -> Bool {
        if teach.isEmpty {
            viewModel.errorMessage = "Please enter what you can teach"
            viewModel.showError = true
            return false
        }
        
        if learn.isEmpty {
            viewModel.errorMessage = "Please enter what you want to learn"
            viewModel.showError = true
            return false
        }
        
        if description.isEmpty {
            viewModel.errorMessage = "Please add a description"
            viewModel.showError = true
            return false
        }
        
        viewModel.errorMessage = ""
        viewModel.showError = false
        return true
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: SkillCategory
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SkillCategories.categories, id: \.id) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        HStack {
                            Text("\(category.emoji) \(category.name)")
                                .font(.system(.body, design: .rounded))
                            
                            Spacer()
                            
                            if category.id == selectedCategory.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
