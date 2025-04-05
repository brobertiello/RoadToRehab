import SwiftUI

struct AddSymptomView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SymptomsViewModel
    
    // Predefined list of body parts
    private let bodyParts = ["Neck", "Shoulder", "Wrist", "Back", "Hip", "Knee", "Ankle"]
    
    @State private var selectedBodyPart = "Neck"
    @State private var severity = 5
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Symptom Details")) {
                    Picker("Body Part", selection: $selectedBodyPart) {
                        ForEach(bodyParts, id: \.self) { part in
                            Text(part)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Pain Severity: \(severity)")
                        HStack {
                            Text("0")
                            Slider(value: Binding(
                                get: { Double(severity) },
                                set: { severity = Int($0) }
                            ), in: 0...10, step: 1)
                            Text("10")
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
                    Button {
                        addSymptom()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Add Symptom")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Add Symptom")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func addSymptom() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.addSymptom(bodyPart: selectedBodyPart, severity: severity)
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