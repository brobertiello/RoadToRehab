import Foundation
import SwiftUI

class SymptomsViewModel: ObservableObject {
    @Published var symptoms: [Symptom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let symptomService: SymptomService
    
    init(authManager: AuthManager) {
        self.symptomService = SymptomService(authManager: authManager)
    }
    
    func fetchSymptoms() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let symptoms = try await symptomService.getSymptoms()
            DispatchQueue.main.async {
                self.symptoms = symptoms
                self.isLoading = false
            }
        } catch APIError.requestFailed(let message) {
            DispatchQueue.main.async {
                self.errorMessage = message
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load symptoms: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func addSymptom(bodyPart: String, severity: Int, notes: String? = nil) async throws {
        let newSymptom = try await symptomService.createSymptom(bodyPart: bodyPart, severity: severity, notes: notes)
        DispatchQueue.main.async {
            self.symptoms.append(newSymptom)
        }
    }
    
    func updateSymptom(symptomId: String, severity: Int, notes: String? = nil) async throws {
        let updatedSymptom = try await symptomService.updateSymptom(id: symptomId, severity: severity, notes: notes)
        DispatchQueue.main.async {
            if let index = self.symptoms.firstIndex(where: { $0.id == symptomId }) {
                self.symptoms[index] = updatedSymptom
            }
        }
    }
    
    func deleteSymptom(at indexSet: IndexSet) async {
        let symptomsToDelete = indexSet.map { self.symptoms[$0] }
        
        // First, remove from local array optimistically
        DispatchQueue.main.async {
            self.symptoms.remove(atOffsets: indexSet)
        }
        
        // Then delete from server
        for symptom in symptomsToDelete {
            do {
                try await symptomService.deleteSymptom(id: symptom.id)
            } catch {
                // If deletion fails, refresh the list to restore correct state
                await self.fetchSymptoms()
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete symptom: \(error.localizedDescription)"
                }
                break
            }
        }
    }
} 