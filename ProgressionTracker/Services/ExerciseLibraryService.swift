import Foundation
import SwiftData

/// Service for managing the exercise library, including default exercises and custom user exercises
class ExerciseLibraryService {
    
    // MARK: - Default Exercise Population
    
    /// Populates the database with default exercises if they don't already exist
    /// - Parameter modelContext: The SwiftData model context to insert exercises into
    static func populateDefaultExercises(modelContext: ModelContext) {
        // Check if default exercises already exist to prevent duplicates
        let descriptor = FetchDescriptor<ExerciseLibraryItem>(
            predicate: #Predicate<ExerciseLibraryItem> { $0.isCustom == false }
        )
        
        do {
            let existingExercises = try modelContext.fetch(descriptor)
            if !existingExercises.isEmpty {
                print("Default exercises already exist, skipping population")
                return
            }
        } catch {
            print("Error checking for existing exercises: \(error)")
            return
        }
        
        // Create all default exercises
        let defaultExercises = createDefaultExerciseList()
        
        // Insert all exercises into the database
        for exercise in defaultExercises {
            modelContext.insert(exercise)
        }
        
        // Save the context
        do {
            try modelContext.save()
            print("Successfully populated \(defaultExercises.count) default exercises")
        } catch {
            print("Error saving default exercises: \(error)")
        }
    }
    
    // MARK: - Search Functionality
    
    /// Searches exercises by name with intelligent matching
    /// - Parameters:
    ///   - query: The search query string
    ///   - exercises: Array of exercises to search through
    /// - Returns: Filtered and sorted array of exercises
    static func searchExercises(query: String, in exercises: [ExerciseLibraryItem]) -> [ExerciseLibraryItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return exercises
        }
        
        let lowercaseQuery = query.lowercased()
        
        // Separate exact matches from contains matches
        var exactMatches: [ExerciseLibraryItem] = []
        var containsMatches: [ExerciseLibraryItem] = []
        
        for exercise in exercises {
            let exerciseName = exercise.name.lowercased()
            
            if exerciseName == lowercaseQuery {
                exactMatches.append(exercise)
            } else if exerciseName.contains(lowercaseQuery) {
                containsMatches.append(exercise)
            }
        }
        
        // Return exact matches first, then contains matches
        return exactMatches + containsMatches
    }
    
    // MARK: - Custom Exercise Creation
    
    /// Creates a new custom exercise and saves it to the database
    /// - Parameters:
    ///   - name: The name of the custom exercise
    ///   - type: Whether it's upper or lower body
    ///   - modelContext: The SwiftData model context
    /// - Returns: The created ExerciseLibraryItem
    static func createCustomExercise(name: String, type: ExerciseType, modelContext: ModelContext) -> ExerciseLibraryItem {
        // Determine category based on exercise name (simple heuristic)
        let category = determineCategoryFromName(name)
        
        let customExercise = ExerciseLibraryItem(
            name: name,
            category: category,
            type: type,
            isCustom: true
        )
        
        modelContext.insert(customExercise)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving custom exercise: \(error)")
        }
        
        return customExercise
    }
    
    // MARK: - Helper Methods
    
    /// Creates the complete list of default exercises
    private static func createDefaultExerciseList() -> [ExerciseLibraryItem] {
        return [
            // Chest Exercises
            ExerciseLibraryItem(name: "Bench Press (Barbell)", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Bench Press (Dumbbell)", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Incline Bench Press", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Decline Bench Press", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Chest Fly", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Cable Crossover", category: .chest, type: .upperBody),
            ExerciseLibraryItem(name: "Push-ups", category: .chest, type: .upperBody),
            
            // Back Exercises
            ExerciseLibraryItem(name: "Pull-ups", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Chin-ups", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Barbell Row", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Dumbbell Row", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Lat Pulldown", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Seated Cable Row", category: .back, type: .upperBody),
            ExerciseLibraryItem(name: "Deadlift", category: .back, type: .lowerBody),
            
            // Leg Exercises
            ExerciseLibraryItem(name: "Squats (Barbell)", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Front Squats", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Leg Press", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Leg Curl", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Leg Extension", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Romanian Deadlift", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Lunges", category: .legs, type: .lowerBody),
            ExerciseLibraryItem(name: "Calf Raises", category: .legs, type: .lowerBody),
            
            // Shoulder Exercises
            ExerciseLibraryItem(name: "Overhead Press (Barbell)", category: .shoulders, type: .upperBody),
            ExerciseLibraryItem(name: "Overhead Press (Dumbbell)", category: .shoulders, type: .upperBody),
            ExerciseLibraryItem(name: "Lateral Raises", category: .shoulders, type: .upperBody),
            ExerciseLibraryItem(name: "Front Raises", category: .shoulders, type: .upperBody),
            ExerciseLibraryItem(name: "Face Pulls", category: .shoulders, type: .upperBody),
            ExerciseLibraryItem(name: "Shrugs", category: .shoulders, type: .upperBody),
            
            // Arm Exercises
            ExerciseLibraryItem(name: "Bicep Curls (Barbell)", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Bicep Curls (Dumbbell)", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Hammer Curls", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Tricep Dips", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Tricep Pushdowns", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Skull Crushers", category: .arms, type: .upperBody),
            ExerciseLibraryItem(name: "Close-Grip Bench Press", category: .arms, type: .upperBody),
            
            // Core Exercises
            ExerciseLibraryItem(name: "Planks", category: .core, type: .upperBody),
            ExerciseLibraryItem(name: "Crunches", category: .core, type: .upperBody),
            ExerciseLibraryItem(name: "Hanging Leg Raises", category: .core, type: .upperBody),
            ExerciseLibraryItem(name: "Russian Twists", category: .core, type: .upperBody)
        ]
    }
    
    /// Determines the most appropriate category for a custom exercise based on its name
    /// - Parameter name: The exercise name
    /// - Returns: The best matching ExerciseCategory
    private static func determineCategoryFromName(_ name: String) -> ExerciseCategory {
        let lowercaseName = name.lowercased()
        
        // Simple keyword-based categorization
        if lowercaseName.contains("chest") || lowercaseName.contains("bench") || lowercaseName.contains("fly") {
            return .chest
        } else if lowercaseName.contains("back") || lowercaseName.contains("row") || lowercaseName.contains("pull") || lowercaseName.contains("deadlift") {
            return .back
        } else if lowercaseName.contains("leg") || lowercaseName.contains("squat") || lowercaseName.contains("lunge") || lowercaseName.contains("calf") {
            return .legs
        } else if lowercaseName.contains("shoulder") || lowercaseName.contains("press") || lowercaseName.contains("raise") {
            return .shoulders
        } else if lowercaseName.contains("bicep") || lowercaseName.contains("tricep") || lowercaseName.contains("curl") || lowercaseName.contains("dip") {
            return .arms
        } else if lowercaseName.contains("core") || lowercaseName.contains("ab") || lowercaseName.contains("plank") || lowercaseName.contains("crunch") {
            return .core
        }
        
        // Default to core if no clear match
        return .core
    }
}
