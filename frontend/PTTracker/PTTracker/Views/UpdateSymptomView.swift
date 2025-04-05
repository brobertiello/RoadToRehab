import SwiftUI

struct UpdateSymptomView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SymptomsViewModel
    let symptom: Symptom
    
    @State private var severity: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(viewModel: SymptomsViewModel, symptom: Symptom) {
        self.viewModel = viewModel
        self.symptom = symptom
        self._severity = State(initialValue: symptom.currentSeverity)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Pain Level")) {
                    HStack {
                        Text("Body Part:")
                            .fontWeight(.semibold)
                        Text(symptom.bodyPart)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Last recorded: \(symptom.lastUpdated)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("Current Pain Severity: \(severity)")
                        HStack {
                            Text("0")
                            Slider(value: Binding(
                                get: { Double(severity) },
                                set: { severity = Int($0) }
                            ), in: 0...10, step: 1)
                            Text("10")
                        }
                    }
                    .padding(.vertical)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        updateSymptom()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Pain Level")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Update Symptom")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func updateSymptom() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.updateSymptom(symptomId: symptom.id, severity: severity)
                DispatchQueue.main.async {
                    isLoading = false
                    dismiss()
                }
            } catch APIError.requestFailed(let message) {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = message
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "An error occurred: \(error.localizedDescription)"
                }
            }
        }
    }
} 