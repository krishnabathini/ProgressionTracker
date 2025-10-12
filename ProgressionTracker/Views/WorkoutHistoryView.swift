import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var workoutsByDate: [(date: Date, count: Int)] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(workoutsByDate, id: \.date) { item in
                    NavigationLink(destination: WorkoutDateDetailView(date: item.date)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.date, format: .dateTime.month(.wide).day().year())
                                    .font(.headline)
                                
                                Text("\(item.count) \(item.count == 1 ? "session" : "sessions")")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadWorkoutHistory()
        }
    }
    
    private func loadWorkoutHistory() {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let sessions = try? modelContext.fetch(descriptor) else { return }
        
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]
        
        for session in sessions {
            // Only count sessions with completed sets
            guard !session.sets.isEmpty else { continue }
            let hasCompletedSet = session.sets.contains { $0.isCompleted }
            
            if hasCompletedSet {
                let dateKey = calendar.startOfDay(for: session.date)
                grouped[dateKey, default: 0] += 1
            }
        }
        
        workoutsByDate = grouped.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

