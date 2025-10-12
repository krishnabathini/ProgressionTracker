import SwiftUI
import SwiftData

// View for displaying a workout day definition (from a program)
struct WorkoutDayDetailView: View {
    @Bindable var workoutDay: WorkoutDay
    @State private var showingExerciseLibrary = false
    
    var body: some View {
        VStack(spacing: 0) {
            if workoutDay.exercises.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "dumbbell")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No exercises yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Add exercises to this workout day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1C1C1E"))
            } else {
                // Exercise list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(workoutDay.exercises.sorted(by: { $0.name < $1.name })) { exercise in
                            NavigationLink(destination: ExerciseTrackingView(exercise: exercise)) {
                                ExerciseRowView(exercise: exercise)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .background(Color(hex: "1C1C1E"))
            }
        }
        .navigationTitle(workoutDay.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingExerciseLibrary = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExerciseLibraryView(workoutDay: workoutDay)
        }
    }
}

private struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Target: \(exercise.targetSets) sets × \(exercise.targetReps) reps")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(12)
    }
}
