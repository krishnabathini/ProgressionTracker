//
//  GitLiftingApp.swift
//  GitLifting
//
//  Created by Krishna Bathini on 10/6/25.
//

import SwiftUI
import SwiftData

/// Main app entry point for GitLifting
/// Sets up SwiftData model container and initializes the exercise library
@main
struct GitLiftingApp: App {
    
    init() {
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
                
                Text("Cardio - Coming Soon")
                    .tabItem {
                        Label("Cardio", systemImage: "figure.run")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
