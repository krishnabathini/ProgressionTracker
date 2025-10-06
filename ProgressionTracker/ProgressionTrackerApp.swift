//
//  ProgressionTrackerApp.swift
//  ProgressionTracker
//
//  Created by Krishna Bathini on 10/6/25.
//

import SwiftUI
import SwiftData

/// Main app entry point for ProgressionTracker
/// Sets up SwiftData model container and initializes the exercise library
@main
struct ProgressionTrackerApp: App {
    
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
            ProgramListView()
                .task {
                    // Initialize exercise library on first app launch
                    // This populates the database with default exercises if they don't exist
                    let context = sharedModelContainer.mainContext
                    ExerciseLibraryService.populateDefaultExercises(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
