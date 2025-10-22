//
//  GitHubAuthView.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import SwiftUI

/// View for GitHub authentication and account management
struct GitHubAuthView: View {
    @ObservedObject private var authService = GitHubAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        if authService.isAuthenticated {
                            authenticatedContent
                        } else {
                            unauthenticatedContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("GitHub Integration")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Authenticated Content
    
    private var authenticatedContent: some View {
        VStack(spacing: 25) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text("Connected to GitHub")
                .font(.title2)
                .fontWeight(.bold)
            
            // User information card
            if let user = authService.currentUser {
                userInfoCard(user: user)
            }
            
            // Features list
            VStack(alignment: .leading, spacing: 15) {
                Text("What you can do:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                featureRow(icon: "cloud.fill", text: "Automatically sync workouts to GitHub")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your fitness progress in commits")
                featureRow(icon: "calendar", text: "View workout history in your repository")
                featureRow(icon: "person.2.fill", text: "Share your fitness journey")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            Spacer()
            
            // Sign out button
            Button(action: {
                authService.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Unauthenticated Content
    
    private var unauthenticatedContent: some View {
        VStack(spacing: 25) {
            // GitHub logo and title
            Image(systemName: "link.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Connect to GitHub")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Link your GitHub account to automatically log your workouts as commits")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 15) {
                Text("Benefits:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                featureRow(icon: "checkmark.circle", text: "Automatic workout logging")
                featureRow(icon: "checkmark.circle", text: "GitHub contribution graph integration")
                featureRow(icon: "checkmark.circle", text: "Share progress with friends")
                featureRow(icon: "checkmark.circle", text: "Keep your data under your control")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Permissions requested
            VStack(alignment: .leading, spacing: 12) {
                Text("Minimal Permissions Requested:")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 25)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Public Repositories")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Create and write to public workout tracker repo only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.blue)
                        .frame(width: 25)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Basic Profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Your email and public profile information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Privacy notice
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Privacy First")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text("We request minimal permissions. No access to private repos or sensitive data. Your workout data stays in your control.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
            
            // Error message
            if let error = authService.authenticationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Sign in button
            Button(action: {
                authService.authenticate()
            }) {
                HStack {
                    if authService.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Connect with GitHub")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .disabled(authService.isAuthenticating)
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func userInfoCard(user: GitHubUser) -> some View {
        VStack(spacing: 15) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
            
            // User details
            VStack(spacing: 5) {
                if let name = user.name {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Text("@\(user.login)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
            }
            
            // Stats
            HStack(spacing: 30) {
                statView(value: user.publicRepos ?? 0, label: "Repos")
                statView(value: user.followers ?? 0, label: "Followers")
                statView(value: user.following ?? 0, label: "Following")
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func statView(value: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Preview

struct GitHubAuthView_Previews: PreviewProvider {
    static var previews: some View {
        GitHubAuthView()
    }
}

