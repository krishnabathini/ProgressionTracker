import SwiftUI
import SwiftData

struct WorkoutDateDetailView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [(exercise: String, sets: [ExerciseSet])] = []
    
    var body: some View {
        List {
            ForEach(exercises, id: \.exercise) { item in
                Section(header: Text(item.exercise).textCase(.uppercase)) {
                    ForEach(Array(item.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("SET \(set.setNumber)")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(set.reps) reps × \(String(format: "%.1f", set.weight)) lbs")
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExercises()
        }
    }
    
    private func loadExercises() {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        
        let dateSessions = sessions.filter { session in
            calendar.isDate(calendar.startOfDay(for: session.date), inSameDayAs: targetDate)
        }
        
        var grouped: [String: [ExerciseSet]] = [:]
        
        for session in dateSessions {
            guard !session.sets.isEmpty else { continue }
            
            for set in session.sets where set.isCompleted {
                if let exercise = set.exercise {
                    let exerciseName = exercise.name
                    grouped[exerciseName, default: []].append(set)
                }
            }
        }
        
        exercises = grouped.map { (exercise: $0.key, sets: $0.value.sorted { $0.setNumber < $1.setNumber }) }
            .sorted { $0.exercise < $1.exercise }
    }
}
