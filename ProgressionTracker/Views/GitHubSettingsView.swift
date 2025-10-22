//
//  GitHubSettingsView.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import SwiftUI

/// View for configuring GitHub integration settings
struct GitHubSettingsView: View {
    @ObservedObject private var settings = GitHubSettingsService.shared
    @ObservedObject private var authService = GitHubAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempRepoName: String = ""
    @State private var showingInvalidNameAlert = false
    @State private var invalidNameMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Repository Configuration Section
                Section {
                    // Repository Name
                    HStack {
                        Text("Repository Name")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("workout-tracker", text: $tempRepoName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.blue)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                validateAndSaveRepoName()
                            }
                    }
                    
                    // Repository Privacy (disabled - requires full repo scope)
                    HStack {
                        Toggle("Private Repository", isOn: .constant(false))
                            .disabled(true)
                        
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                // Could show alert explaining why it's disabled
                            }
                    }
                    
                    // Current repository info
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repository URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("github.com/\(user.login)/\(settings.repositoryName)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Repository Configuration")
                } footer: {
                    Text("Repository will be public. Private repositories require additional GitHub permissions. Changes to repository name will create a new repository.")
                }
                
                // Auto-logging Section
                Section {
                    Toggle("Auto-log Workouts", isOn: $settings.autoLogWorkouts)
                } header: {
                    Text("Automation")
                } footer: {
                    Text("Automatically log workouts to GitHub when you complete them.")
                }
                
                // Repository Info Section
                Section {
                    HStack {
                        Text("Visibility")
                        Spacer()
                        Text("Public")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Full Name")
                        Spacer()
                        if let user = authService.currentUser {
                            Text("\(user.login)/\(settings.repositoryName)")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Current Repository")
                }
                
                // Actions Section
                Section {
                    Button("View on GitHub") {
                        if let user = authService.currentUser,
                           let url = URL(string: "https://github.com/\(user.login)/\(settings.repositoryName)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("Reset to Defaults") {
                        settings.resetToDefaults()
                        tempRepoName = settings.repositoryName
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("GitHub Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        validateAndSaveRepoName()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                tempRepoName = settings.repositoryName
            }
            .alert("Invalid Repository Name", isPresented: $showingInvalidNameAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(invalidNameMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateAndSaveRepoName() {
        let trimmed = tempRepoName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            // Reset to current value if empty
            tempRepoName = settings.repositoryName
            return
        }
        
        if settings.isValidRepositoryName(trimmed) {
            settings.repositoryName = trimmed
        } else {
            invalidNameMessage = """
            Repository name must:
            • Start with a letter or number
            • Contain only letters, numbers, hyphens, or underscores
            • Be 100 characters or less
            """
            showingInvalidNameAlert = true
            tempRepoName = settings.repositoryName  // Reset to valid name
        }
    }
}

// MARK: - Preview

struct GitHubSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GitHubSettingsView()
    }
}

