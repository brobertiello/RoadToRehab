import Foundation
import SwiftUI

class RecoveryPlanViewModel: ObservableObject {
    @Published var recoveryPlan: RecoveryPlanDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedWeek: Int = 1
    
    private let recoveryPlanService: RecoveryPlanService
    
    init(authManager: AuthManager) {
        self.recoveryPlanService = RecoveryPlanService(authManager: authManager)
    }
    
    func generatePlan() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let recoveryPlanResponse = try await recoveryPlanService.generateRecoveryPlan()
            DispatchQueue.main.async {
                self.recoveryPlan = recoveryPlanResponse.plan
                self.isLoading = false
                
                // Set selected week to the first week
                if let weeks = self.recoveryPlan?.weeks, !weeks.isEmpty {
                    self.selectedWeek = weeks[0].weekNumber
                }
            }
        } catch APIError.requestFailed(let message) {
            DispatchQueue.main.async {
                self.errorMessage = message
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate recovery plan: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    var currentWeekData: RecoveryWeek? {
        recoveryPlan?.weeks.first(where: { $0.weekNumber == selectedWeek })
    }
    
    var hasRecoveryPlan: Bool {
        recoveryPlan != nil
    }
    
    var weekNumbers: [Int] {
        recoveryPlan?.weeks.map { $0.weekNumber }.sorted() ?? []
    }
} 