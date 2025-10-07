import SwiftUI
import SwiftData

/// Sheet view for selecting a workout program template or creating a custom program
struct ProgramTemplateSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // State for custom program creation alert
    @State private var showingCustomAlert = false
    @State private var customProgramName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Section 1: Pre-Made Programs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pre-Made Programs")
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(ProgramTemplateService.availableTemplates, id: \.name) { template in
                                TemplateRowView(template: template) {
                                    createProgramFromTemplate(template)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Section 2: Divider with "or" text
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Section 3: Create Custom
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create Custom")
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCustomAlert = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                Text("Create Custom Program")
                                    .font(.system(.body, design: .default, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12)) // #1C1C1E
            .navigationTitle("Choose Program")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Create Custom Program", isPresented: $showingCustomAlert) {
            TextField("Program Name", text: $customProgramName)
            Button("Create") {
                createCustomProgram()
            }
            .disabled(customProgramName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                customProgramName = ""
            }
        } message: {
            Text("Enter a name for your custom workout program")
        }
    }
    
    // MARK: - Template Selection
    
    /// Creates a program from the selected template
    /// - Parameter template: The ProgramTemplate to create the program from
    private func createProgramFromTemplate(_ template: ProgramTemplate) {
        // Create the program using the template service
        let program = ProgramTemplateService.createProgram(from: template, modelContext: modelContext)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Dismiss the sheet
        dismiss()
        
        print("Created program '\(program.name)' with \(program.days.count) workout days")
    }
    
    // MARK: - Custom Program Creation
    
    /// Creates a custom program with the entered name
    private func createCustomProgram() {
        let trimmedName = customProgramName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        // Create a new empty program
        let program = WorkoutProgram(name: trimmedName)
        
        // Insert into the database
        modelContext.insert(program)
        
        do {
            try modelContext.save()
            print("Created custom program '\(program.name)'")
        } catch {
            print("Error saving custom program: \(error)")
        }
        
        // Clear the text field and dismiss
        customProgramName = ""
        dismiss()
    }
}

// MARK: - Template Row View

/// Individual row view for displaying a program template
struct TemplateRowView: View {
    let template: ProgramTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Template name
                    Text(template.name)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    // Template description
                    Text(template.description)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(Color(white: 0.6))
                        .multilineTextAlignment(.leading)
                    
                    // Number of days
                    Text("\(template.workoutDayNames.count) workouts")
                        .font(.system(.subheadline, design: .default, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Right chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(red: 0.17, green: 0.17, blue: 0.18)) // #2C2C2E
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProgramTemplateSelectionView()
        .modelContainer(for: [WorkoutProgram.self, WorkoutDay.self])
}
