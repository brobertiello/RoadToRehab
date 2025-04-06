import SwiftUI

struct GeneratePlanSheetView: View {
    @ObservedObject var viewModel: RecoveryPlanViewModel
    @ObservedObject var symptomViewModel: SymptomViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var startDate = Date()
    @State private var selectedSymptoms: [Symptom] = []
    @State private var planDuration = "4 weeks"
    @State private var isGenerating = false
    
    private let durations = ["2 weeks", "4 weeks", "6 weeks", "8 weeks"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Symptoms")) {
                    if symptomViewModel.symptoms.isEmpty {
                        Text("No symptoms available. Please add symptoms in the Symptoms tab.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        List {
                            ForEach(symptomViewModel.symptoms) { symptom in
                                Button(action: {
                                    toggleSymptom(symptom)
                                }) {
                                    HStack {
                                        Text(symptom.name)
                                        Spacer()
                                        if isSymptomSelected(symptom) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Plan Start Date")) {
                    DatePicker(
                        "Starting From",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(DefaultDatePickerStyle())
                }
                
                Section(header: Text("Plan Duration")) {
                    Picker("Duration", selection: $planDuration) {
                        ForEach(durations, id: \.self) { duration in
                            Text(duration)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(footer: Text("Your recovery plan will be generated based on the symptoms you've selected and will schedule exercises starting from the chosen date.")) {
                    Button(action: generateRecoveryPlan) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Generate Recovery Plan")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedSymptoms.isEmpty || isGenerating)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedSymptoms.isEmpty ? .gray : .white)
                    .background(selectedSymptoms.isEmpty ? Color.gray.opacity(0.2) : Color.blue)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Generate Plan")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $viewModel.showOverwriteConfirmation) {
                Alert(
                    title: Text("Overwrite Existing Plan?"),
                    message: Text("You already have a saved recovery plan. Generating a new plan will replace your existing one. Do you want to continue?"),
                    primaryButton: .destructive(Text("Overwrite")) {
                        generatePlan()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            symptomViewModel.fetchSymptoms()
        }
    }
    
    private func toggleSymptom(_ symptom: Symptom) {
        if let index = selectedSymptoms.firstIndex(where: { $0.id == symptom.id }) {
            selectedSymptoms.remove(at: index)
        } else {
            selectedSymptoms.append(symptom)
        }
    }
    
    private func isSymptomSelected(_ symptom: Symptom) -> Bool {
        return selectedSymptoms.contains(where: { $0.id == symptom.id })
    }
    
    private func generateRecoveryPlan() {
        Task {
            // Check if there's an existing plan
            if await viewModel.checkForExistingPlan() {
                // This will trigger the alert
                DispatchQueue.main.async {
                    viewModel.showOverwriteConfirmation = true
                }
            } else {
                generatePlan()
            }
        }
    }
    
    private func generatePlan() {
        let symptomIds = selectedSymptoms.map { $0.id }
        
        isGenerating = true
        
        Task {
            do {
                try await viewModel.generatePlan(
                    symptomIds: symptomIds,
                    startDate: startDate,
                    planDuration: planDuration
                )
                
                DispatchQueue.main.async {
                    isGenerating = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isGenerating = false
                }
            }
        }
    }
} 