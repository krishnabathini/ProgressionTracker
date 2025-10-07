import SwiftUI
import SwiftData

/// Main workout logging screen where users log sets and receive progressive overload recommendations
/// This is a basic skeleton - functionality will be added piece by piece
struct ExerciseTrackingView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Input control state variables
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 8
    @State private var setNumber: Int = 1
    
    // Session management state variables
    @State private var currentSession: WorkoutSession?
    @State private var completedSets: [ExerciseSet] = []
    @State private var recommendation: String = ""
    
    // MARK: - Session Management
    
    private func findOrCreateSession() {
        // Get today's date (start of day)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch all sessions using FetchDescriptor
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let allSessions = try modelContext.fetch(descriptor)
            
            // Filter in Swift code to find session for today with sets for this exercise
            let todaysSession = allSessions.first { session in
                let sessionDate = calendar.startOfDay(for: session.date)
                let isToday = sessionDate == today
                let hasSetsForThisExercise = session.sets.contains { $0.exercise?.persistentModelID == exercise.persistentModelID }
                return isToday && hasSetsForThisExercise
            }
            
            if let existingSession = todaysSession {
                currentSession = existingSession
                // Load completed sets for this exercise from the session
                completedSets = existingSession.sets.filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
                setNumber = completedSets.count + 1
            } else {
                // Create new session for today
                let newSession = WorkoutSession(
                    program: exercise.day?.program,
                    day: exercise.day,
                    date: Date(),
                    notes: nil
                )
                modelContext.insert(newSession)
                currentSession = newSession
                completedSets = []
                setNumber = 1
            }
        } catch {
            print("Error fetching sessions: \(error)")
            // Fallback: create new session
            let newSession = WorkoutSession(
                program: exercise.day?.program,
                day: exercise.day,
                date: Date(),
                notes: nil
            )
            modelContext.insert(newSession)
            currentSession = newSession
            completedSets = []
            setNumber = 1
        }
        
        // Calculate progression recommendation
        let calculator = ProgressionCalculator()
        if let lastSession = completedSets.last,
           !completedSets.isEmpty {
            let lastWeight = lastSession.weight
            
            // Check if user hit all target reps in ALL sets
            let allSetsHitTarget = completedSets.allSatisfy { $0.reps >= exercise.targetReps }
            
            if allSetsHitTarget {
                let nextWeight = calculator.calculateNextWeight(
                    currentWeight: lastWeight,
                    exerciseType: exercise.exerciseType
                )
                recommendation = "Great job! Try \(String(format: "%.1f", nextWeight)) lbs next time"
                currentWeight = nextWeight // Pre-fill with recommended weight
            } else {
                recommendation = "Maintain \(String(format: "%.1f", lastWeight)) lbs - aim for all target reps"
                currentWeight = lastWeight
            }
        }
    }
    
    private func addSet() {
        guard let session = currentSession else {
            print("No current session available")
            return
        }
        
        // Create new exercise set
        let newSet = ExerciseSet(
            session: session,
            exercise: exercise,
            setNumber: setNumber,
            weight: currentWeight,
            reps: currentReps,
            isCompleted: true
        )
        
        // Insert into model context
        modelContext.insert(newSet)
        
        // Add to completed sets array
        completedSets.append(newSet)
        
        // Increment set number for next set
        setNumber += 1
        
        // Save context
        do {
            try modelContext.save()
            print("Set added: \(currentWeight) lbs × \(currentReps) reps")
        } catch {
            print("Error saving set: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // Progressive overload recommendation banner
                if !recommendation.isEmpty {
                    Text(recommendation)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(recommendation.contains("Great job") ? Color.green.opacity(0.3) : Color.yellow.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    Text("Complete your first workout to get recommendations")
                        .font(.system(.subheadline, design: .default))
                        .foregroundStyle(Color(white: 0.6))
                        .padding()
                }
                
                Spacer()
                
                // Set history section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed Sets")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    if completedSets.isEmpty {
                        Text("No sets completed yet")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    } else {
                        ForEach(completedSets, id: \.setNumber) { set in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 16))
                                
                                Text("Set \(set.setNumber)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(12)
                
                Spacer()
                
                // Input controls section
                VStack(spacing: 16) {
                    // REPS section
                    HStack {
                        Text("REPS")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .medium, design: .default))
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                if currentReps > 1 {
                                    currentReps -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                            Text("\(currentReps)")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .frame(minWidth: 60)
                            Button(action: {
                                if currentReps < 50 {
                                    currentReps += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // WEIGHT section
                    HStack {
                        Text("WEIGHT")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .medium, design: .default))
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                if currentWeight >= 2.5 {
                                    currentWeight -= 2.5
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                            Text("\(Int(currentWeight))")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .frame(minWidth: 60)
                            Button(action: {
                                if currentWeight < 1000 {
                                    currentWeight += 2.5
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // Weight unit label
                    HStack {
                        Spacer()
                        Text("lbs")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .medium, design: .default))
                    }
                    
                    // Add Set button
                    Button(action: {
                        addSet()
                    }) {
                        Text("Add Set")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                currentReps = exercise.targetReps
                findOrCreateSession()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutProgram.self, WorkoutDay.self, Exercise.self, configurations: config)
    
    let program = WorkoutProgram(name: "Push Pull Legs")
    let day = WorkoutDay(program: program, name: "Push Day", orderIndex: 0)
    let exercise = Exercise(day: day, name: "Bench Press", targetSets: 3, targetReps: 8, exerciseType: .upperBody)
    
    return ExerciseTrackingView(exercise: exercise)
        .modelContainer(container)
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
