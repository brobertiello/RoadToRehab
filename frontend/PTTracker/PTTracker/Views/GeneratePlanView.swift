import SwiftUI

struct GeneratePlanView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RecoveryPlanViewModel
    @EnvironmentObject var symptomsViewModel: SymptomsViewModel
    
    @State private var selectedSymptomIds: Set<String> = Set()
    @State private var startDate = Date()
    @State private var planDuration: String = "auto"
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    let durationOptions = ["auto", "1", "2", "3", "4", "6", "8", "12"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Symptoms")) {
                    if symptomsViewModel.symptoms.isEmpty {
                        Text("No symptoms available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(symptomsViewModel.symptoms) { symptom in
                            Button(action: {
                                toggleSymptom(symptom.id)
                            }) {
                                HStack {
                                    Text(symptom.bodyPart)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedSymptomIds.contains(symptom.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Start Date")) {
                    DatePicker(
                        "Choose a start date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                Section(header: Text("Plan Duration")) {
                    Picker("Duration in weeks", selection: $planDuration) {
                        ForEach(durationOptions, id: \.self) { option in
                            Text(option == "auto" ? "Auto (Recommended)" : "\(option) weeks")
                                .tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if planDuration == "auto" {
                        Text("AI will determine the optimal plan length based on your symptoms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
                
                Section {
                    Button(action: generatePlan) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Generate Recovery Plan")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(selectedSymptomIds.isEmpty || isGenerating)
                    .listRowBackground(selectedSymptomIds.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitle("Create Recovery Plan", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .onAppear {
                Task {
                    await symptomsViewModel.fetchSymptoms()
                }
            }
        }
    }
    
    private func toggleSymptom(_ id: String) {
        if selectedSymptomIds.contains(id) {
            selectedSymptomIds.remove(id)
        } else {
            selectedSymptomIds.insert(id)
        }
    }
    
    private func generatePlan() {
        guard !selectedSymptomIds.isEmpty else {
            errorMessage = "Please select at least one symptom"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.generatePlan(
                    symptomIds: Array(selectedSymptomIds),
                    startDate: startDate,
                    planDuration: planDuration
                )
                
                DispatchQueue.main.async {
                    isGenerating = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isGenerating = false
                    errorMessage = "Failed to generate plan: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct GeneratePlanView_Previews: PreviewProvider {
    static var previews: some View {
        GeneratePlanView(viewModel: RecoveryPlanViewModel(authManager: AuthManager.shared))
            .environmentObject(SymptomsViewModel(authManager: AuthManager.shared))
    }
} 