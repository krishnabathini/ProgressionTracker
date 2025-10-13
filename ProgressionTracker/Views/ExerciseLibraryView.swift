import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Bindable var workoutDay: WorkoutDay
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var libraryItems: [ExerciseLibraryItem]
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var showTargetConfig = false
    @State private var selectedLibraryItem: ExerciseLibraryItem?
    @State private var targetSets = 3
    @State private var targetReps = 10
    
    var filteredExercises: [ExerciseLibraryItem] {
        var filtered = libraryItems
        
        // Filter by category if selected
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = ExerciseLibraryService.searchExercises(query: searchText, in: filtered)
        }
        
        return filtered
    }
    
    var showCreateOption: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !filteredExercises.contains(where: { $0.name.lowercased() == searchText.lowercased() })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search exercises", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color(hex: "2C2C2E"))
                .cornerRadius(10)
                .padding()
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All category button
                        Button {
                            selectedCategory = nil
                        } label: {
                            Text("All")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == nil ? Color.blue : Color(hex: "2C2C2E"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        
                        // Individual category buttons
                        ForEach(ExerciseCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color(hex: "2C2C2E"))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Exercise list
                List {
                    // Show "Create [exercise name]" option if search doesn't match exactly
                    if showCreateOption {
                        Button {
                            createAndAddCustomExercise()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create \"\(searchText)\"")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Add as custom exercise")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(hex: "2C2C2E"))
                    }
                    
                    // Library exercises
                    ForEach(filteredExercises) { item in
                        Button {
                            addExerciseToWorkoutDay(item)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(item.category.displayName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .listRowBackground(Color(hex: "2C2C2E"))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color(hex: "1C1C1E"))
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTargetConfig) {
                NavigationStack {
                    VStack(spacing: 24) {
                        // Exercise name
                        if let libraryItem = selectedLibraryItem {
                            VStack(spacing: 8) {
                                Text(libraryItem.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Set your targets")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 20)
                        }
                        
                        VStack(spacing: 16) {
                            // Target Sets
                            HStack {
                                Text("TARGET SETS")
                                    .font(.caption)
                                    .foregroundStyle(Color(white: 0.6))
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button {
                                        if targetSets > 1 { targetSets -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Text("\(targetSets)")
                                        .font(.system(size: 36, weight: .bold))
                                        .frame(width: 60)
                                        .foregroundStyle(.white)
                                    
                                    Button {
                                        if targetSets < 10 { targetSets += 1 }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                            
                            // Target Reps
                            HStack {
                                Text("TARGET REPS")
                                    .font(.caption)
                                    .foregroundStyle(Color(white: 0.6))
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button {
                                        if targetReps > 1 { targetReps -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    Text("\(targetReps)")
                                        .font(.system(size: 36, weight: .bold))
                                        .frame(width: 60)
                                        .foregroundStyle(.white)
                                    
                                    Button {
                                        if targetReps < 50 { targetReps += 1 }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Add Exercise button
                        Button {
                            confirmAddExercise()
                        } label: {
                            Text("Add Exercise")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .background(Color(hex: "1C1C1E"))
                    .navigationTitle("Set Targets")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                showTargetConfig = false
                                selectedLibraryItem = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func addExerciseToWorkoutDay(_ libraryItem: ExerciseLibraryItem) {
        selectedLibraryItem = libraryItem
        targetSets = 3  // Reset to defaults
        targetReps = 10
        showTargetConfig = true
    }
    
    private func createAndAddCustomExercise() {
        let trimmedName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Auto-determine exercise type based on name keywords
        let exerciseType = determineExerciseType(from: trimmedName)
        
        // Create custom library item
        let customLibraryItem = ExerciseLibraryService.createCustomExercise(
            name: trimmedName,
            type: exerciseType,
            modelContext: modelContext
        )
        
        // Show target config for custom exercise
        selectedLibraryItem = customLibraryItem
        targetSets = 3
        targetReps = 10
        showTargetConfig = true
    }
    
    private func confirmAddExercise() {
        guard let libraryItem = selectedLibraryItem else { return }
        
        // Create exercise with user-specified targets
        let exercise = Exercise(
            day: workoutDay,
            name: libraryItem.name,
            targetSets: targetSets,
            targetReps: targetReps,
            exerciseType: libraryItem.type,
            libraryItem: libraryItem
        )
        
        workoutDay.exercises.append(exercise)
        modelContext.insert(exercise)
        
        do {
            try modelContext.save()
            print("Added exercise '\(libraryItem.name)' with \(targetSets) sets × \(targetReps) reps")
            
            // Haptic feedback for successful add
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error saving exercise: \(error)")
        }
        
        selectedLibraryItem = nil
        dismiss()
    }
    
    private func determineExerciseType(from name: String) -> ExerciseType {
        let lowercaseName = name.lowercased()
        
        // Keywords that indicate lower body
        let lowerBodyKeywords = ["squat", "leg", "deadlift", "lunge", "calf", "glute", "hamstring", "quad"]
        
        for keyword in lowerBodyKeywords {
            if lowercaseName.contains(keyword) {
                return .lowerBody
            }
        }
        
        // Default to upper body
        return .upperBody
    }
}
