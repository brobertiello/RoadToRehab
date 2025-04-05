import Foundation
import SwiftUI

class RecoveryPlanViewModel: ObservableObject {
    @Published var recoveryPlan: RecoveryPlanDetails?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedWeek: Int = 1
    @Published var hasExistingPlan = false
    @Published var showOverwriteConfirmation = false
    @Published var selectedExercise: (exercise: RecoveryExercise, weekNumber: Int)?
    @Published var showExerciseDetail = false
    
    private let recoveryPlanService: RecoveryPlanService
    
    init(authManager: AuthManager) {
        self.recoveryPlanService = RecoveryPlanService(authManager: authManager)
        
        // Try to load saved plan on init
        Task {
            await loadSavedPlan()
        }
    }
    
    func checkForExistingPlan() async -> Bool {
        do {
            if let _ = try await recoveryPlanService.getSavedRecoveryPlan() {
                DispatchQueue.main.async {
                    self.hasExistingPlan = true
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.hasExistingPlan = false
                }
                return false
            }
        } catch {
            print("Error checking for existing plan: \(error)")
            return false
        }
    }
    
    func promptToGeneratePlan() async {
        if await checkForExistingPlan() {
            DispatchQueue.main.async {
                self.showOverwriteConfirmation = true
            }
        } else {
            await generatePlan()
        }
    }
    
    func generatePlan() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.successMessage = nil
        }
        
        do {
            let recoveryPlanResponse = try await recoveryPlanService.generateRecoveryPlan()
            
            // Get the plan locally before updating the published property
            let generatedPlan = recoveryPlanResponse.plan
            
            DispatchQueue.main.async {
                self.recoveryPlan = generatedPlan
                self.isLoading = false
                
                // Set selected week to the first week
                if let weeks = self.recoveryPlan?.weeks, !weeks.isEmpty {
                    self.selectedWeek = weeks[0].weekNumber
                }
            }
            
            // Save with the locally captured plan instead of using the published property
            await savePlanDirectly(RecoveryPlan(plan: generatedPlan))
            
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
    
    // Helper function to save a plan directly without checking the published property
    private func savePlanDirectly(_ plan: RecoveryPlan) async {
        DispatchQueue.main.async {
            self.isSaving = true
            self.errorMessage = nil
        }
        
        do {
            let savedSuccessfully = try await recoveryPlanService.saveRecoveryPlan(plan)
            
            DispatchQueue.main.async {
                self.isSaving = false
                self.hasExistingPlan = true
                if savedSuccessfully {
                    self.successMessage = "Recovery plan saved successfully!"
                    
                    // Automatically dismiss success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = nil
                    }
                }
            }
        } catch APIError.requestFailed(let message) {
            DispatchQueue.main.async {
                self.errorMessage = message
                self.isSaving = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save recovery plan: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
    
    func savePlan() async {
        guard let plan = recoveryPlan else {
            DispatchQueue.main.async {
                self.errorMessage = "No plan to save"
            }
            return
        }
        
        // Debug output of completion status before saving
        var completedCount = 0
        for week in plan.weeks {
            for ex in week.exercises {
                if ex.isCompleted {
                    completedCount += 1
                    print("About to save completed exercise: \(ex.name), id: \(ex.id)")
                }
            }
        }
        print("Saving plan with \(completedCount) completed exercises")
        
        await savePlanDirectly(RecoveryPlan(plan: plan))
    }
    
    func loadSavedPlan() async {
        print("Loading saved recovery plan...")
        do {
            if let savedPlan = try await recoveryPlanService.getSavedRecoveryPlan() {
                print("Successfully loaded recovery plan")
                
                // Debug output of completion status
                var completedCount = 0
                for (weekIndex, week) in savedPlan.plan.weeks.enumerated() {
                    print("Week \(week.weekNumber) (index \(weekIndex)):")
                    for (exIndex, ex) in week.exercises.enumerated() {
                        print("  Exercise \(exIndex): \(ex.name), completed: \(ex.isCompleted), id: \(ex.id)")
                        if ex.isCompleted {
                            completedCount += 1
                        }
                    }
                }
                print("Plan has \(completedCount) completed exercises")
                
                DispatchQueue.main.async {
                    self.recoveryPlan = savedPlan.plan
                    self.hasExistingPlan = true
                    
                    // Set selected week to the first week
                    if let weeks = self.recoveryPlan?.weeks, !weeks.isEmpty {
                        self.selectedWeek = weeks[0].weekNumber
                    }
                    
                    // Verify loaded data matches what we expect
                    if let plan = self.recoveryPlan {
                        var verifiedCount = 0
                        for week in plan.weeks {
                            for ex in week.exercises {
                                if ex.isCompleted {
                                    verifiedCount += 1
                                    print("Verified completed exercise in UI model: \(ex.name)")
                                }
                            }
                        }
                        print("ViewModel has \(verifiedCount) completed exercises after loading")
                    }
                }
            } else {
                print("No saved recovery plan found")
                DispatchQueue.main.async {
                    self.hasExistingPlan = false
                }
            }
        } catch {
            print("Could not load saved plan: \(error)")
            // Not showing an error to the user since this is done automatically
        }
    }
    
    func showExerciseDetails(exercise: RecoveryExercise, weekNumber: Int) {
        selectedExercise = (exercise, weekNumber)
        showExerciseDetail = true
    }
    
    func markExerciseAsCompleted(exercise: RecoveryExercise, weekNumber: Int) {
        print("Marking exercise \(exercise.name) as completed (was \(exercise.isCompleted))")
        guard var plan = recoveryPlan else { 
            print("Error: Cannot mark exercise as completed - no plan exists")
            return 
        }
        
        // Find the week
        if let weekIndex = plan.weeks.firstIndex(where: { $0.weekNumber == weekNumber }) {
            // Find the exercise within that week
            if let exerciseIndex = plan.weeks[weekIndex].exercises.firstIndex(where: { $0.id == exercise.id }) {
                // Mark as completed
                plan.weeks[weekIndex].exercises[exerciseIndex].isCompleted = true
                
                print("Updated completion status: week=\(weekIndex), exercise=\(exerciseIndex), id=\(exercise.id)")
                print("Exercise ID: \(exercise.id)")
                
                // Log all exercise completion states for debugging
                for (idx, ex) in plan.weeks[weekIndex].exercises.enumerated() {
                    print("  Exercise \(idx): \(ex.name) - completed: \(ex.isCompleted), id: \(ex.id)")
                }
                
                // Update the view model
                DispatchQueue.main.async {
                    self.recoveryPlan = plan
                    
                    // Show a brief success message
                    self.successMessage = "Exercise marked as completed!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
                
                // Save the updated plan
                Task {
                    do {
                        let savedPlan = RecoveryPlan(plan: plan)
                        let success = try await recoveryPlanService.saveRecoveryPlan(savedPlan)
                        if success {
                            print("Successfully saved plan with completed exercise")
                            // Verify the save by loading it back
                            if let loadedPlan = try await recoveryPlanService.getSavedRecoveryPlan() {
                                let savedExercise = loadedPlan.plan.weeks[weekIndex].exercises[exerciseIndex]
                                print("Verified saved exercise: \(savedExercise.name), completed: \(savedExercise.isCompleted)")
                            }
                        } else {
                            print("Failed to save plan after marking exercise as completed")
                        }
                    } catch {
                        print("Error saving plan after marking exercise as completed: \(error)")
                    }
                }
            } else {
                print("Error: Exercise with id \(exercise.id) not found in week \(weekNumber)")
            }
        } else {
            print("Error: Week \(weekNumber) not found in recovery plan")
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
    
    func getProgressForWeek(_ weekNumber: Int) -> (completed: Int, total: Int) {
        guard let plan = recoveryPlan else { return (0, 0) }
        
        if let week = plan.weeks.first(where: { $0.weekNumber == weekNumber }) {
            let completed = week.exercises.filter { $0.isCompleted }.count
            return (completed, week.exercises.count)
        }
        
        return (0, 0)
    }
} 