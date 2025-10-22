//
//  GitHubRepositoryService.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import Foundation

/// Service for interacting with GitHub repositories to log workout data
class GitHubRepositoryService {
    // MARK: - Singleton
    static let shared = GitHubRepositoryService()
    
    // MARK: - Constants
    private let apiBaseURL = "https://api.github.com"
    
    // Get repository name from settings
    private var repositoryName: String {
        GitHubSettingsService.shared.repositoryName
    }
    
    private var isPrivateRepo: Bool {
        GitHubSettingsService.shared.isRepositoryPrivate
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Creates a workout log repository if it doesn't exist
    /// - Returns: Result containing the repository information or an error
    func createWorkoutRepository() async -> Result<GitHubRepository, Error> {
        print("📦 Creating/verifying repository...")
        
        guard let token = KeychainService.shared.getAccessToken() else {
            print("   ❌ No access token found")
            return .failure(GitHubAuthError.tokenNotFound)
        }
        
        // First, try to fetch existing repository
        print("   🔍 Checking if repository exists: \(repositoryName)")
        let existingRepo = await getRepository(name: repositoryName)
        
        switch existingRepo {
        case .success(let repo):
            print("   ✅ Repository already exists: \(repo.htmlUrl)")
            return .success(repo)
        case .failure:
            print("   ℹ️ Repository doesn't exist, creating new one...")
        }
        
        // Repository doesn't exist, create it
        guard let url = URL(string: "\(apiBaseURL)/user/repos") else {
            print("   ❌ Invalid URL")
            return .failure(GitHubRepositoryError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let repoData: [String: Any] = [
            "name": repositoryName,
            "description": "GitLifting - My workout progression tracker",
            "private": isPrivateRepo,
            "auto_init": true
        ]
        
        print("   📝 Creating repository with settings:")
        print("      Name: \(repositoryName)")
        print("      Private: \(isPrivateRepo)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: repoData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("   ❌ Invalid HTTP response")
                return .failure(GitHubRepositoryError.invalidResponse)
            }
            
            print("   📊 Repository creation response: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 422 {
                print("   ℹ️ Repository already exists (422), fetching...")
                // Repository already exists, fetch it instead
                return await getRepository(name: repositoryName)
            }
            
            guard httpResponse.statusCode == 201 else {
                print("   ❌ Failed to create repository: \(httpResponse.statusCode)")
                // Try to get error message from response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorDict["message"] as? String {
                    print("   Error message: \(message)")
                }
                return .failure(GitHubRepositoryError.apiError(statusCode: httpResponse.statusCode))
            }
            
            let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)
            print("   ✅ Repository created successfully: \(repository.htmlUrl)")
            return .success(repository)
            
        } catch {
            print("   ❌ Exception during repository creation: \(error)")
            return .failure(error)
        }
    }
    
    /// Fetches an existing repository
    /// - Parameter name: The repository name
    /// - Returns: Result containing the repository information or an error
    func getRepository(name: String) async -> Result<GitHubRepository, Error> {
        guard let token = KeychainService.shared.getAccessToken() else {
            print("   ❌ No access token for getRepository")
            return .failure(GitHubAuthError.tokenNotFound)
        }
        
        guard let user = GitHubAuthService.shared.currentUser else {
            print("   ❌ No current user for getRepository")
            return .failure(GitHubRepositoryError.userNotFound)
        }
        
        let urlString = "\(apiBaseURL)/repos/\(user.login)/\(name)"
        print("   🔍 Fetching repository: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("   ❌ Invalid URL: \(urlString)")
            return .failure(GitHubRepositoryError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("   ❌ Invalid HTTP response type")
                return .failure(GitHubRepositoryError.invalidResponse)
            }
            
            print("   📊 Get repository response: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    print("   ℹ️ Repository not found (404)")
                }
                return .failure(GitHubRepositoryError.apiError(statusCode: httpResponse.statusCode))
            }
            
            let repository = try JSONDecoder().decode(GitHubRepository.self, from: data)
            print("   ✅ Repository fetched successfully")
            return .success(repository)
            
        } catch {
            print("   ❌ Exception during getRepository: \(error)")
            return .failure(error)
        }
    }
    
    /// Logs a workout by creating a commit in the repository
    /// - Parameters:
    ///   - workoutData: The workout data to log
    ///   - date: The date of the workout
    /// - Returns: Result indicating success or failure
    func logWorkout(workoutData: WorkoutLogData, date: Date) async -> Result<Void, Error> {
        guard let token = KeychainService.shared.getAccessToken() else {
            return .failure(GitHubAuthError.tokenNotFound)
        }
        
        guard let user = GitHubAuthService.shared.currentUser else {
            return .failure(GitHubRepositoryError.userNotFound)
        }
        
        // Format the workout data as markdown
        let workoutContent = formatWorkoutAsMarkdown(workoutData: workoutData, date: date)
        let fileName = "workouts/\(formatDateForFileName(date)).md"
        
        // Ensure repository exists first
        let repoResult = await createWorkoutRepository()
        switch repoResult {
        case .failure(let error):
            print("Failed to create repository: \(error)")
            return .failure(error)
        case .success(let repo):
            print("Repository verified/created: \(repo.name)")
        }
        
        // Create or update the file in the repository
        let result = await createOrUpdateFile(
            owner: user.login,
            repo: repositoryName,
            path: fileName,
            content: workoutContent,
            message: "Workout completed: \(formatDateForCommit(date))",
            token: token
        )
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Creates or updates a file in the repository
    private func createOrUpdateFile(
        owner: String,
        repo: String,
        path: String,
        content: String,
        message: String,
        token: String
    ) async -> Result<Void, Error> {
        let urlString = "\(apiBaseURL)/repos/\(owner)/\(repo)/contents/\(path)"
        print("📝 Creating file in repository...")
        print("   URL: \(urlString)")
        print("   Path: \(path)")
        
        guard let url = URL(string: urlString) else {
            print("   ❌ Invalid URL")
            return .failure(GitHubRepositoryError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode content to base64
        guard let contentData = content.data(using: .utf8) else {
            print("   ❌ Failed to encode content")
            return .failure(GitHubRepositoryError.encodingError)
        }
        let base64Content = contentData.base64EncodedString()
        
        // Check if file already exists to get its SHA
        var sha: String?
        let getResult = await getFileSHA(owner: owner, repo: repo, path: path, token: token)
        if case .success(let existingSHA) = getResult {
            sha = existingSHA
            print("   ℹ️ File exists, updating with SHA")
        } else {
            print("   ℹ️ File doesn't exist, creating new")
        }
        
        var requestBody: [String: Any] = [
            "message": message,
            "content": base64Content
        ]
        
        if let sha = sha {
            requestBody["sha"] = sha
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("   ❌ Invalid HTTP response type")
                return .failure(GitHubRepositoryError.invalidResponse)
            }
            
            print("   📊 File creation response: \(httpResponse.statusCode)")
            
            guard (200...201).contains(httpResponse.statusCode) else {
                print("   ❌ Failed to create file: \(httpResponse.statusCode)")
                // Try to get error message
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorDict["message"] as? String {
                    print("   Error: \(errorMessage)")
                }
                return .failure(GitHubRepositoryError.apiError(statusCode: httpResponse.statusCode))
            }
            
            print("   ✅ File created/updated successfully!")
            return .success(())
            
        } catch {
            print("   ❌ Exception during file creation: \(error)")
            return .failure(error)
        }
    }
    
    /// Gets the SHA of an existing file
    private func getFileSHA(owner: String, repo: String, path: String, token: String) async -> Result<String, Error> {
        guard let url = URL(string: "\(apiBaseURL)/repos/\(owner)/\(repo)/contents/\(path)") else {
            return .failure(GitHubRepositoryError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(GitHubRepositoryError.invalidResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(GitHubRepositoryError.fileNotFound)
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sha = json["sha"] as? String {
                return .success(sha)
            }
            
            return .failure(GitHubRepositoryError.invalidResponse)
            
        } catch {
            return .failure(error)
        }
    }
    
    /// Formats workout data as markdown
    private func formatWorkoutAsMarkdown(workoutData: WorkoutLogData, date: Date) -> String {
        var markdown = "# Workout Log - \(formatDateForDisplay(date))\n\n"
        markdown += "## Program: \(workoutData.programName)\n\n"
        
        if let dayName = workoutData.dayName {
            markdown += "### Day: \(dayName)\n\n"
        }
        
        markdown += "## Exercises\n\n"
        
        for exercise in workoutData.exercises {
            markdown += "### \(exercise.name)\n\n"
            markdown += "| Set | Weight | Reps |\n"
            markdown += "|-----|--------|------|\n"
            
            for (index, set) in exercise.sets.enumerated() {
                markdown += "| \(index + 1) | \(set.weight) \(set.unit) | \(set.reps) |\n"
            }
            
            markdown += "\n"
        }
        
        markdown += "---\n"
        markdown += "*Logged automatically by GitLifting*\n"
        
        return markdown
    }
    
    /// Formats date for file name
    private func formatDateForFileName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Formats date for commit message
    private func formatDateForCommit(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    /// Formats date for display
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

/// Represents a GitHub repository
struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let defaultBranch: String
    let `private`: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlUrl = "html_url"
        case defaultBranch = "default_branch"
        case `private`
    }
}

/// Represents workout data to be logged
struct WorkoutLogData {
    let programName: String
    let dayName: String?
    let exercises: [ExerciseLogData]
}

/// Represents exercise data to be logged
struct ExerciseLogData {
    let name: String
    let sets: [SetLogData]
}

/// Represents set data to be logged
struct SetLogData {
    let weight: Double
    let reps: Int
    let unit: String // "kg" or "lbs"
}

/// Custom errors for GitHub repository operations
enum GitHubRepositoryError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case userNotFound
    case fileNotFound
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .apiError(let statusCode):
            return "GitHub API error with status code: \(statusCode)"
        case .userNotFound:
            return "User not found. Please authenticate first."
        case .fileNotFound:
            return "File not found in repository"
        case .encodingError:
            return "Failed to encode content"
        }
    }
}

