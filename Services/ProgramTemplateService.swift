import Foundation
import SwiftData

/// Represents a pre-made workout program template that users can choose from
struct ProgramTemplate {
    let name: String
    let description: String
    let workoutDayNames: [String]
}

/// Service for managing workout program templates and creating programs from templates
class ProgramTemplateService {
    
    // MARK: - Available Templates
    
    /// Returns all available workout program templates
    /// Each template includes a name, description, and ordered list of workout day names
    static var availableTemplates: [ProgramTemplate] {
        return [
            ProgramTemplate(
                name: "Push Pull Legs",
                description: "3-day split focusing on push muscles, pull muscles, and legs",
                workoutDayNames: ["Push Day", "Pull Day", "Leg Day"]
            ),
            
            ProgramTemplate(
                name: "Upper Lower",
                description: "4-day split alternating upper and lower body",
                workoutDayNames: ["Upper Body A", "Lower Body A", "Upper Body B", "Lower Body B"]
            ),
            
            ProgramTemplate(
                name: "Bro Split",
                description: "5-day split targeting one muscle group per day",
                workoutDayNames: ["Chest + Triceps", "Back + Biceps", "Shoulders", "Legs", "Arms"]
            ),
            
            ProgramTemplate(
                name: "Full Body",
                description: "3-day full body routine for beginners",
                workoutDayNames: ["Full Body A", "Full Body B", "Full Body C"]
            )
        ]
    }
    
    // MARK: - Program Creation
    
    /// Creates a new WorkoutProgram from a template
    /// - Parameters:
    ///   - template: The ProgramTemplate to create the program from
    ///   - modelContext: The SwiftData model context to insert the program into
    /// - Returns: The created WorkoutProgram with all workout days properly linked
    static func createProgram(from template: ProgramTemplate, modelContext: ModelContext) -> WorkoutProgram {
        // Create the main workout program
        let program = WorkoutProgram(name: template.name)
        
        // Create workout days for each day name in the template
        var workoutDays: [WorkoutDay] = []
        
        for (index, dayName) in template.workoutDayNames.enumerated() {
            let workoutDay = WorkoutDay(
                program: program,
                name: dayName,
                orderIndex: index
            )
            
            // Add the day to the program's days array
            program.days.append(workoutDay)
            workoutDays.append(workoutDay)
        }
        
        // Insert the program and all its days into the model context
        modelContext.insert(program)
        
        // Insert each workout day
        for day in workoutDays {
            modelContext.insert(day)
        }
        
        // Save the context to persist the changes
        do {
            try modelContext.save()
            print("Successfully created program '\(template.name)' with \(workoutDays.count) workout days")
        } catch {
            print("Error saving program '\(template.name)': \(error)")
        }
        
        return program
    }
    
    // MARK: - Template Information
    
    /// Returns a detailed description of what each template type is best for
    static func getTemplateRecommendations() -> [String: String] {
        return [
            "Push Pull Legs": "Best for intermediate lifters who can train 3x per week. Focuses on movement patterns rather than individual muscles.",
            "Upper Lower": "Ideal for intermediate to advanced lifters training 4x per week. Allows for more volume per muscle group.",
            "Bro Split": "Perfect for advanced lifters training 5-6x per week. Maximizes muscle-specific training volume.",
            "Full Body": "Excellent for beginners or those with limited time. Trains all major muscle groups in each session."
        ]
    }
    
    /// Returns the recommended training frequency for each template
    static func getTrainingFrequency(for template: ProgramTemplate) -> String {
        switch template.name {
        case "Push Pull Legs":
            return "3 days per week"
        case "Upper Lower":
            return "4 days per week"
        case "Bro Split":
            return "5-6 days per week"
        case "Full Body":
            return "3 days per week"
        default:
            return "Varies"
        }
    }
}
