import SwiftUI

struct GenerateExercisesView: View {
    @Binding var isPresented: Bool
    @ObservedObject var exercisesViewModel: ExercisesViewModel
    @EnvironmentObject var symptomViewModel: SymptomsViewModel
    
    @State private var selectedSymptomIds: [String] = []
    @State private var startDate = Date()
    @State private var durationDays: Int = 14
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil
    
    // Duration options
    private let durationOptions = [7, 14, 21, 28]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Symptoms")) {
                    if symptomViewModel.symptoms.isEmpty {
                        Text("No symptoms available. Add symptoms first.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(symptomViewModel.symptoms) { symptom in
                            Button(action: {
                                toggleSymptom(symptom.id)
                            }) {
                                HStack {
                                    Text(symptom.bodyPart)
                                    Spacer()
                                    if selectedSymptomIds.contains(symptom.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("Start Date")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section(header: Text("Duration")) {
                    Picker("Duration (Days)", selection: $durationDays) {
                        ForEach(durationOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: generateExercises) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Generate Exercises")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(selectedSymptomIds.isEmpty || isGenerating)
                }
            }
            .navigationTitle("Generate Recovery Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                // Pre-fetch symptoms data if needed to ensure it's ready
                if symptomViewModel.symptoms.isEmpty {
                    Task {
                        await symptomViewModel.fetchSymptoms()
                    }
                }
            }
        }
    }
    
    // Toggle symptom selection
    private func toggleSymptom(_ id: String) {
        if selectedSymptomIds.contains(id) {
            selectedSymptomIds.removeAll { $0 == id }
        } else {
            selectedSymptomIds.append(id)
        }
    }
    
    // Generate exercises using AI
    private func generateExercises() {
        guard !selectedSymptomIds.isEmpty else {
            errorMessage = "Please select at least one symptom"
            return
        }
        
        // Set state first
        isGenerating = true
        errorMessage = nil
        
        // Create local copies of the values to avoid potential state changes during async operation
        let selectedIds = selectedSymptomIds
        let start = startDate
        let duration = durationDays
        
        Task {
            do {
                // Ensure we're on main thread before accessing ViewModel
                await MainActor.run {
                    // Call the view model to generate exercises
                    // Use the actual API signature (without completion handler if it doesn't expect one)
                    Task {
                        do {
                            try await exercisesViewModel.generateExercises(
                                symptomIds: selectedIds,
                                startDate: start,
                                durationDays: duration
                            )
                            
                            isGenerating = false
                            isPresented = false
                        } catch {
                            isGenerating = false
                            errorMessage = "Failed to generate exercises: \(error.localizedDescription)"
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = "Failed to generate exercises: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct GenerateExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateExercisesView(
            isPresented: .constant(true),
            exercisesViewModel: ExercisesViewModel(authManager: AuthManager.shared)
        )
        .environmentObject(SymptomsViewModel(authManager: AuthManager.shared))
    }
} 