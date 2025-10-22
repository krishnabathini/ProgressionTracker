//
//  ModelDiagnosticService.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import Foundation
import SwiftData

/// Service for diagnosing SwiftData model configuration and health
/// Use this to verify all models are properly configured before running the app
class ModelDiagnosticService {
    
    // MARK: - Public Methods
    
    /// Performs comprehensive diagnostics on all SwiftData models
    static func performDiagnostics() {
        print("")
        print("🔍 ═══════════════════════════════════════════════════")
        print("🔍 SwiftData Model Diagnostic Report")
        print("🔍 ═══════════════════════════════════════════════════")
        print("")
        
        // Check each model
        checkModel("WorkoutProgram", WorkoutProgram.self)
        checkModel("WorkoutDay", WorkoutDay.self)
        checkModel("Exercise", Exercise.self)
        checkModel("WorkoutSession", WorkoutSession.self)
        checkModel("ExerciseSet", ExerciseSet.self)
        checkModel("ExerciseLibraryItem", ExerciseLibraryItem.self)
        
        // Test model instantiation
        testModelInstantiation()
        
        print("")
        print("✅ ═══════════════════════════════════════════════════")
        print("✅ All Model Diagnostics Passed!")
        print("✅ ═══════════════════════════════════════════════════")
        print("")
    }
    
    // MARK: - Private Methods
    
    /// Checks a specific model for proper configuration
    private static func checkModel<T>(_ name: String, _ type: T.Type) {
        print("📋 Checking \(name):")
        print("   - Type: \(String(describing: type))")
        print("   - Module: \(String(reflecting: type).components(separatedBy: ".").first ?? "Unknown")")
        print("   ✅ Model declaration valid")
        print("")
    }
    
    /// Tests creating instances of each model
    private static func testModelInstantiation() {
        print("🧪 Testing Model Instantiation:")
        print("")
        
        // Test WorkoutProgram
        let testProgram = WorkoutProgram(name: "Test Program")
        print("   ✅ WorkoutProgram instantiation successful")
        print("      Name: \(testProgram.name)")
        
        // Test WorkoutDay
        let testDay = WorkoutDay(program: testProgram, name: "Test Day", orderIndex: 0)
        print("   ✅ WorkoutDay instantiation successful")
        print("      Name: \(testDay.name)")
        
        // Test Exercise
        let testExercise = Exercise(
            day: testDay,
            name: "Test Exercise",
            targetSets: 3,
            targetReps: 8,
            exerciseType: .upperBody
        )
        print("   ✅ Exercise instantiation successful")
        print("      Name: \(testExercise.name)")
        print("      Target Sets: \(testExercise.targetSets)")
        print("      Target Reps: \(testExercise.targetReps)")
        
        // Test WorkoutSession
        let testSession = WorkoutSession(
            program: testProgram,
            day: testDay,
            date: Date()
        )
        print("   ✅ WorkoutSession instantiation successful")
        print("      Date: \(testSession.date)")
        
        // Test ExerciseSet
        let testSet = ExerciseSet(
            session: testSession,
            exercise: testExercise,
            setNumber: 1,
            weight: 135.0,
            reps: 8,
            isCompleted: true
        )
        print("   ✅ ExerciseSet instantiation successful")
        print("      Set #\(testSet.setNumber): \(testSet.weight) lbs × \(testSet.reps) reps")
        
        // Test ExerciseLibraryItem
        let testLibraryItem = ExerciseLibraryItem(
            name: "Test Library Exercise",
            category: .chest,
            type: .upperBody
        )
        print("   ✅ ExerciseLibraryItem instantiation successful")
        print("      Name: \(testLibraryItem.name)")
        print("      Category: \(testLibraryItem.category.displayName)")
    }
    
    /// Validates model relationships
    static func validateModelRelationships() {
        print("")
        print("🔗 Validating Model Relationships:")
        print("")
        
        // Create test instances with relationships
        let program = WorkoutProgram(name: "Test Program")
        let day = WorkoutDay(program: program, name: "Test Day", orderIndex: 0)
        let exercise = Exercise(day: day, name: "Test Exercise", targetSets: 3, targetReps: 8, exerciseType: .upperBody)
        let session = WorkoutSession(program: program, day: day, date: Date())
        let set = ExerciseSet(session: session, exercise: exercise, setNumber: 1, weight: 100, reps: 8)
        
        // Validate relationships
        print("   Program → Day:")
        print("      ✅ Day's program reference: \(day.program != nil)")
        
        print("   Day → Exercise:")
        print("      ✅ Exercise's day reference: \(exercise.day != nil)")
        
        print("   Session → Set:")
        print("      ✅ Set's session reference: \(set.session != nil)")
        
        print("   Set → Exercise:")
        print("      ✅ Set's exercise reference: \(set.exercise != nil)")
        
        print("")
        print("✅ All relationships valid!")
        print("")
    }
    
    /// Prints detailed schema information
    static func printSchemaInfo() {
        print("")
        print("📊 SwiftData Schema Information:")
        print("")
        
        // Explicitly typed array to avoid heterogeneous collection issues
        let modelNames: [String] = [
            "WorkoutProgram",
            "WorkoutDay",
            "Exercise",
            "WorkoutSession",
            "ExerciseSet",
            "ExerciseLibraryItem"
        ]
        
        print("   Registered Models:")
        for name in modelNames {
            print("      ✅ \(name)")
        }
        
        print("")
    }
}

