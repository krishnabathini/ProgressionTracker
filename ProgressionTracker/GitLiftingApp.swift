//
//  GitLiftingApp.swift
//  GitLifting
//
//  Created by Krishna Bathini on 10/6/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

// Firebase Configuration AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

/// Main app entry point for GitLifting
/// Sets up SwiftData model container and initializes the exercise library
@main
struct GitLiftingApp: App {
    // Firebase Delegate Registration
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Run SwiftData model diagnostics (debug builds only)
        #if DEBUG
        // Uncomment to run diagnostics:
        // ModelDiagnosticService.performDiagnostics()
        // ModelDiagnosticService.validateModelRelationships()
        // ModelDiagnosticService.printSchemaInfo()
        #endif
        
        // Configure navigation bar appearance for entire app
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        navBarAppearance.shadowColor = .clear // Remove separator line
        
        // Title text colors - WHITE for all states
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Apply to all states
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Set tint color for buttons (back button, + button)
        UINavigationBar.appearance().tintColor = .systemBlue
    }
    
    /// Shared model container configured with all workout tracking models
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutProgram.self,
            WorkoutDay.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseSet.self,
            ExerciseLibraryItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                ProgramListView()
                    .task {
                        // Initialize exercise library on first app launch
                        // This populates the database with default exercises if they don't exist
                        let context = sharedModelContainer.mainContext
                        ExerciseLibraryService.populateDefaultExercises(modelContext: context)
                    }
                    .tabItem {
                        Label("Workouts", systemImage: "dumbbell.fill")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .onOpenURL { url in
                // Handle OAuth callback from GitHub
                handleOAuthCallback(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// Handles OAuth callback URLs from GitHub authentication
    /// - Parameter url: The callback URL containing the authorization code
    private func handleOAuthCallback(_ url: URL) {
        // Check if this is a GitHub OAuth callback
        guard url.scheme == "gitlifting",
              url.host == "oauth" else {
            return
        }
        
        // The auth service handles the OAuth flow internally
        // It will update its published properties (isAuthenticated, authenticationError, etc.)
        // which the UI observes automatically
        print("Received OAuth callback: \(url)")
    }
}
