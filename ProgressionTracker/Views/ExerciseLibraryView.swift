import SwiftUI
import SwiftData

// Stub view for exercise library
// TODO: Implement full exercise library view
struct ExerciseLibraryView: View {
    @Bindable var workoutDay: WorkoutDay
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Exercise Library - Coming Soon")
                .navigationTitle("Add Exercise")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

