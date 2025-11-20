//
//  BugReportView.swift
//  ProgressionTracker
//
//  Created on 10/22/2025
//

import SwiftUI
import FirebaseFirestore

/// View for reporting bugs and issues
struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var bugDescription: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var submissionError: Error?
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background matching app theme
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header icon
                        Image(systemName: "ladybug.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                        
                        // Instructions
                        VStack(spacing: 8) {
                            Text("Report a Bug")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Help us improve by reporting any issues you encounter")
                                .font(.subheadline)
                                .foregroundColor(Color(white: 0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        // Bug description text field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe the bug")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            TextEditor(text: $bugDescription)
                                .frame(minHeight: 200)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .background(Color(hex: "2C2C2E"))
                                .foregroundColor(.white)
                                .tint(.blue)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(white: 0.2), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                                .focused($isTextEditorFocused)
                                .colorScheme(.dark)
                        }
                        
                        // Tips section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips for reporting:")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                tipRow(icon: "1.circle.fill", text: "Describe what you were trying to do")
                                tipRow(icon: "2.circle.fill", text: "Explain what actually happened")
                                tipRow(icon: "3.circle.fill", text: "Include steps to reproduce if possible")
                            }
                            .padding()
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        // Error message display
                        if let error = submissionError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error: \(error.localizedDescription)")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                        
                        // Submit button
                        Button(action: {
                            submitBugReport()
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text(isSubmitting ? "Submitting..." : "Submit Report")
                            }
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextEditorFocused = false
                }
            }
            .navigationTitle("Report Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Return") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") {
                    bugDescription = ""
                    dismiss()
                }
            } message: {
                Text("Thank you for reporting this bug. We'll look into it!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(white: 0.8))
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func submitBugReport() {
        let trimmedDescription = bugDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedDescription.isEmpty else {
            errorMessage = "Please describe the bug before submitting."
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        submissionError = nil
        
        let db = Firestore.firestore()
        
        let bugReport: [String: Any] = [
            "id": UUID().uuidString,
            "description": trimmedDescription,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "deviceModel": UIDevice.current.model,
            "iOSVersion": UIDevice.current.systemVersion,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Submit to Firestore
        db.collection("bug_reports").addDocument(data: bugReport) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.submissionError = error
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    self.isSubmitting = false
                } else {
                    // Send Slack Notification after successful Firestore save
                    SlackNotificationService.shared.sendBugReportNotification(description: trimmedDescription)
                    
                    self.isSubmitting = false
                    self.showSuccessAlert = true
                    
                    // Clear description and dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.bugDescription = ""
                        self.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct BugReportView_Previews: PreviewProvider {
    static var previews: some View {
        BugReportView()
    }
}


