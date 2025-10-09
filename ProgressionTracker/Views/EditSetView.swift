import SwiftUI

struct EditSetView: View {
    let set: ExerciseSet
    let onSave: (Double, Int) -> Void
    
    @State private var weight: Double
    @State private var reps: Int
    @Environment(\.dismiss) var dismiss
    
    init(set: ExerciseSet, onSave: @escaping (Double, Int) -> Void) {
        self.set = set
        self.onSave = onSave
        _weight = State(initialValue: set.weight)
        _reps = State(initialValue: set.reps)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    HStack {
                        Text("REPS")
                            .font(.caption)
                            .foregroundStyle(Color(white: 0.6))
                        Spacer()
                        HStack(spacing: 12) {
                            Button { if reps > 1 { reps -= 1 } } label: {
                                Image(systemName: "minus")
                                    .frame(width: 44, height: 44)
                                    .background(Color(white: 0.2))
                                    .cornerRadius(8)
                            }
                            Text("\(reps)")
                                .font(.system(size: 32, weight: .bold))
                                .frame(width: 60)
                            Button { if reps < 50 { reps += 1 } } label: {
                                Image(systemName: "plus")
                                    .frame(width: 44, height: 44)
                                    .background(Color(white: 0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    HStack {
                        Text("WEIGHT")
                            .font(.caption)
                            .foregroundStyle(Color(white: 0.6))
                        Spacer()
                        HStack(spacing: 12) {
                            Button { if weight >= 2.5 { weight -= 2.5 } } label: {
                                Image(systemName: "minus")
                                    .frame(width: 44, height: 44)
                                    .background(Color(white: 0.2))
                                    .cornerRadius(8)
                            }
                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 32, weight: .bold))
                                .frame(width: 100)
                            Button { if weight < 1000 { weight += 2.5 } } label: {
                                Image(systemName: "plus")
                                    .frame(width: 44, height: 44)
                                    .background(Color(white: 0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(hex: "1C1C1E"))
            .navigationTitle("Edit Set \(set.setNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(weight, reps)
                        dismiss()
                    }
                }
            }
        }
    }
}

