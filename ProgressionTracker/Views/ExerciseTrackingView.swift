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
    
    // Weight input state variables
    @State private var showWeightInput = false
    @State private var weightInputText = ""
    
    // Edit state variables
    @State private var editingSet: ExerciseSet?
    
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
                recommendation = "Try \(String(format: "%.1f", nextWeight)) lbs × \(exercise.targetReps) reps"
                currentWeight = nextWeight // Pre-fill with recommended weight
            } else {
                recommendation = "Maintain \(String(format: "%.1f", lastWeight)) lbs × \(exercise.targetReps) reps"
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
    
    private func deleteSet(_ set: ExerciseSet) {
        if let index = completedSets.firstIndex(where: { $0.persistentModelID == set.persistentModelID }) {
            completedSets.remove(at: index)
            modelContext.delete(set)
            
            // Renumber remaining sets
            for (idx, remainingSet) in completedSets.enumerated() {
                remainingSet.setNumber = idx + 1
            }
            
            setNumber = completedSets.count + 1
            try? modelContext.save()
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                
                // Progressive overload recommendation banner
                if !recommendation.isEmpty {
                    VStack(spacing: 4) {
                        Text(recommendation)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        recommendation.contains("Try") ? 
                        Color.green.opacity(0.3) : 
                        Color.yellow.opacity(0.3)
                    )
                    .cornerRadius(0)
                }
                
                Spacer()
                
                // Date display above set history
                if let session = currentSession {
                    Text(session.date, format: .dateTime.month(.wide).day().year())
                        .font(.system(.caption, design: .default, weight: .medium))
                        .foregroundStyle(Color(white: 0.5))
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                }
                
                // Set history section
                if completedSets.isEmpty {
                    VStack {
                        Text("No sets completed yet")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .padding()
                    }
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(12)
                } else {
                    List {
                        ForEach(completedSets) { set in
                            if editingSet?.persistentModelID == set.persistentModelID {
                                // EDIT MODE
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("SET \(set.setNumber)")
                                            .font(.system(.subheadline, weight: .semibold))
                                            .foregroundStyle(.blue)
                                        Spacer()
                                        Button("Done") {
                                            try? modelContext.save()
                                            editingSet = nil
                                        }
                                        .foregroundStyle(.blue)
                                    }
                                    
                                    // Reps stepper
                                    HStack {
                                        Text("REPS").font(.caption).foregroundStyle(Color(white: 0.6))
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Button { if set.reps > 1 { set.reps -= 1 } } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Color(white: 0.5))
                                            }
                                            Text("\(set.reps)")
                                                .font(.system(.title3, weight: .semibold))
                                                .frame(width: 40)
                                            Button { if set.reps < 50 { set.reps += 1 } } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Weight stepper
                                    HStack {
                                        Text("WEIGHT").font(.caption).foregroundStyle(Color(white: 0.6))
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Button { if set.weight >= 2.5 { set.weight -= 2.5 } } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Color(white: 0.5))
                                            }
                                            Text(String(format: "%.1f", set.weight))
                                                .font(.system(.title3, weight: .semibold))
                                                .frame(width: 60)
                                            Button { if set.weight < 1000 { set.weight += 2.5 } } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                    }
                                }
                                .listRowBackground(Color(hex: "2C2C2E"))
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 2))
                            } else {
                                // NORMAL MODE
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("SET \(set.setNumber)")
                                            .font(.system(.subheadline, design: .default, weight: .semibold))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(set.reps) reps × \(String(format: "%.1f", set.weight)) lbs")
                                            .font(.system(.subheadline, design: .default))
                                            .foregroundStyle(Color(white: 0.7))
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingSet = set
                                    }
                                    
                                    if set.setNumber != completedSets.last?.setNumber {
                                        Divider()
                                            .background(Color(white: 0.3))
                                            .padding(.top, 12)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteSet(set)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(12)
                    .frame(height: CGFloat(completedSets.count * 56))
                }
                
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
                            Text(String(format: "%.1f", currentWeight))
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(minWidth: 100)
                                .onTapGesture {
                                    weightInputText = String(format: "%.1f", currentWeight)
                                    showWeightInput = true
                                }
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
            .alert("Enter Weight", isPresented: $showWeightInput) {
                TextField("Weight", text: $weightInputText)
                    .keyboardType(.decimalPad)
                Button("Cancel", role: .cancel) { }
                Button("Set") {
                    if let weight = Double(weightInputText) {
                        currentWeight = weight
                    }
                }
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
