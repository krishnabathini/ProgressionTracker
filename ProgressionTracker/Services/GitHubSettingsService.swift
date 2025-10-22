//
//  GitHubSettingsService.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import Foundation

/// Service for managing GitHub integration settings
class GitHubSettingsService: ObservableObject {
    // MARK: - Singleton
    static let shared = GitHubSettingsService()
    
    // MARK: - Published Properties
    @Published var repositoryName: String {
        didSet {
            UserDefaults.standard.set(repositoryName, forKey: "github_repository_name")
        }
    }
    
    @Published var isRepositoryPrivate: Bool {
        didSet {
            UserDefaults.standard.set(isRepositoryPrivate, forKey: "github_repository_private")
        }
    }
    
    @Published var autoLogWorkouts: Bool {
        didSet {
            UserDefaults.standard.set(autoLogWorkouts, forKey: "github_auto_log")
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load saved settings or use defaults
        self.repositoryName = UserDefaults.standard.string(forKey: "github_repository_name") ?? "workout-tracker"
        
        // Always use public repositories (our OAuth scope is public_repo)
        self.isRepositoryPrivate = false
        
        self.autoLogWorkouts = UserDefaults.standard.bool(forKey: "github_auto_log")  // Default: false
    }
    
    // MARK: - Public Methods
    
    /// Resets all settings to defaults
    func resetToDefaults() {
        repositoryName = "workout-tracker"
        isRepositoryPrivate = false
        autoLogWorkouts = false
    }
    
    /// Validates repository name (GitHub naming rules)
    func isValidRepositoryName(_ name: String) -> Bool {
        // GitHub repository name rules:
        // - Can't be empty
        // - Can contain alphanumeric, hyphens, underscores
        // - Can't start with hyphen or underscore
        // - Maximum 100 characters
        
        guard !name.isEmpty, name.count <= 100 else { return false }
        
        let validPattern = "^[a-zA-Z0-9][a-zA-Z0-9_-]*$"
        let regex = try? NSRegularExpression(pattern: validPattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        
        return regex?.firstMatch(in: name, range: range) != nil
    }
}

