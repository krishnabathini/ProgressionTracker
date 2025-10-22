//
//  GitHubAuthService.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import Foundation
import AuthenticationServices
import SwiftUI

/// Manages GitHub OAuth authentication flow
class GitHubAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    // MARK: - GitHub OAuth Configuration
    private let clientID = "Ov23livLsewsXSLDl0qj"
    private let clientSecret = "69a6f042d105c448358c4ab88e55a4355fcbf796"
    private let redirectURI = "progressiontracker://oauth"
    private let authorizationBaseURL = "https://github.com/login/oauth/authorize"
    private let tokenExchangeURL = "https://github.com/login/oauth/access_token"
    
    // MARK: - Singleton
    static let shared = GitHubAuthService()
    
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var authenticationError: String?
    @Published var isAuthenticating: Bool = false
    @Published var currentUser: GitHubUser?
    
    // MARK: - Private Properties
    private var webAuthSession: ASWebAuthenticationSession?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        
        // Check if we already have a valid token
        if let token = KeychainService.shared.getAccessToken() {
            self.isAuthenticated = !token.isEmpty
            if self.isAuthenticated {
                // Fetch user info on initialization
                Task {
                    await fetchUserInfo()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Initiates the GitHub OAuth authentication flow
    func authenticate() {
        isAuthenticating = true
        authenticationError = nil
        
        let authURL = generateAuthorizationURL()
        print("🔐 Starting GitHub OAuth authentication")
        print("📍 Authorization URL: \(authURL)")
        
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "progressiontracker"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                if let error = error {
                    // Enhanced error logging
                    print("❌ Authentication Error Occurred:")
                    print("   Error: \(error)")
                    print("   Localized Description: \(error.localizedDescription)")
                    
                    if let nsError = error as NSError? {
                        print("   Domain: \(nsError.domain)")
                        print("   Code: \(nsError.code)")
                        print("   User Info: \(nsError.userInfo)")
                    }
                    
                    // User cancelled or other error occurred
                    if let authError = error as? ASWebAuthenticationSessionError {
                        switch authError.code {
                        case .canceledLogin:
                            print("🚫 User cancelled login")
                            self.authenticationError = "Authentication was cancelled"
                        case .presentationContextNotProvided:
                            print("🚫 Presentation context not provided")
                            self.authenticationError = "Authentication setup error. Please try again."
                        case .presentationContextInvalid:
                            print("🚫 Presentation context invalid")
                            self.authenticationError = "Authentication setup error. Please try again."
                        @unknown default:
                            print("🚫 Unknown authentication error: \(authError.code.rawValue)")
                            self.authenticationError = "Authentication failed: \(error.localizedDescription)"
                        }
                    } else {
                        self.authenticationError = "Authentication failed: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("❌ No callback URL received")
                    self.authenticationError = "Invalid callback URL"
                    return
                }
                
                print("✅ Callback URL received: \(callbackURL)")
                self.handleOAuthCallback(url: callbackURL)
            }
        }
        
        webAuthSession?.prefersEphemeralWebBrowserSession = false
        webAuthSession?.presentationContextProvider = self
        
        let started = webAuthSession?.start() ?? false
        print("🚀 Authentication session started: \(started)")
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    /// Provides the window for presenting the authentication session
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the active window scene
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback to any available window
            return UIApplication.shared.windows.first ?? ASPresentationAnchor()
        }
        return window
    }
    
    /// Signs out the current user
    func signOut() {
        KeychainService.shared.deleteAccessToken()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.authenticationError = nil
        }
    }
    
    /// Fetches the current authenticated user's information
    @MainActor
    func fetchUserInfo() async {
        guard let token = KeychainService.shared.getAccessToken() else {
            self.isAuthenticated = false
            return
        }
        
        guard let url = URL(string: "https://api.github.com/user") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubAuthError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                // Token is invalid or expired
                self.signOut()
                throw GitHubAuthError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                throw GitHubAuthError.apiError(statusCode: httpResponse.statusCode)
            }
            
            let user = try JSONDecoder().decode(GitHubUser.self, from: data)
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            print("Failed to fetch user info: \(error)")
            self.authenticationError = "Failed to fetch user information"
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates the GitHub authorization URL with required parameters
    /// Uses minimal scopes for privacy: public_repo (create/write to public repos only) and user:email (basic profile)
    private func generateAuthorizationURL() -> URL {
        var components = URLComponents(string: authorizationBaseURL)!
        
        // Minimal scopes for privacy:
        // - public_repo: Create and write to public repositories only (not all repos)
        // - user:email: Access user's email and basic profile info
        let scopes = "public_repo user:email"
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: generateRandomState())
        ]
        
        print("🔐 Requesting minimal OAuth scopes: \(scopes)")
        
        return components.url!
    }
    
    /// Handles the OAuth callback URL after user authorization
    private func handleOAuthCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            authenticationError = "Invalid callback URL format"
            return
        }
        
        // Check for error in callback
        if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
            authenticationError = "Authorization failed: \(error)"
            return
        }
        
        // Extract authorization code
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            authenticationError = "No authorization code received"
            return
        }
        
        // Exchange code for access token
        exchangeCodeForToken(code: code)
    }
    
    /// Exchanges the authorization code for an access token
    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: tokenExchangeURL) else {
            authenticationError = "Invalid token exchange URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: String] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            authenticationError = "Failed to encode request: \(error.localizedDescription)"
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.authenticationError = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.authenticationError = "No data received from GitHub"
                    return
                }
                
                do {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    
                    // Check if there was an error in the response
                    if let error = tokenResponse.error {
                        self.authenticationError = "Token exchange failed: \(error)"
                        return
                    }
                    
                    guard let accessToken = tokenResponse.accessToken else {
                        self.authenticationError = "No access token in response"
                        return
                    }
                    
                    // Save token securely to Keychain
                    KeychainService.shared.saveAccessToken(accessToken)
                    self.isAuthenticated = true
                    self.authenticationError = nil
                    
                    // Fetch user information
                    Task {
                        await self.fetchUserInfo()
                    }
                    
                } catch {
                    self.authenticationError = "Failed to parse token response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    /// Generates a random state string for CSRF protection
    private func generateRandomState() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in characters.randomElement()! })
    }
}

// MARK: - Supporting Types

/// Represents the OAuth token response from GitHub
struct TokenResponse: Codable {
    let accessToken: String?
    let scope: String?
    let tokenType: String?
    let error: String?
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case scope
        case tokenType = "token_type"
        case error
        case errorDescription = "error_description"
    }
}

/// Represents a GitHub user
struct GitHubUser: Codable, Identifiable {
    let id: Int
    let login: String
    let name: String?
    let email: String?
    let avatarUrl: String?
    let htmlUrl: String?
    let bio: String?
    let publicRepos: Int?
    let followers: Int?
    let following: Int?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case email
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case bio
        case publicRepos = "public_repos"
        case followers
        case following
        case createdAt = "created_at"
    }
}

/// Custom errors for GitHub authentication
enum GitHubAuthError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case apiError(statusCode: Int)
    case tokenNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .unauthorized:
            return "Authentication token is invalid or expired"
        case .apiError(let statusCode):
            return "GitHub API error with status code: \(statusCode)"
        case .tokenNotFound:
            return "Authentication token not found"
        }
    }
}

