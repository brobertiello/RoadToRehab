import Foundation
import SwiftUI

@MainActor
class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var filterSymptomId: String? = nil
    
    private let exerciseService: ExerciseService
    
    init(authManager: AuthManager) {
        self.exerciseService = ExerciseService(authManager: authManager)
    }
    
    // Fetch all exercises
    func fetchExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            exercises = try await exerciseService.getExercises()
            isLoading = false
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch exercises: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Filter exercises by symptom
    func filterBySymptom(symptomId: String?) {
        filterSymptomId = symptomId
    }
    
    // Get filtered exercises
    var filteredExercises: [Exercise] {
        guard let symptomId = filterSymptomId else {
            return exercises
        }
        
        return exercises.filter { $0.symptomId == symptomId }
    }
    
    // Group exercises by day for calendar view
    func exercisesByDay() -> [Date: [Exercise]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: filteredExercises) { exercise in
            // Strip time component to group by date only
            let components = calendar.dateComponents([.year, .month, .day], from: exercise.scheduledDate)
            return calendar.date(from: components) ?? exercise.scheduledDate
        }
    }
    
    // Get exercises for a specific date
    func exercisesForDate(_ date: Date) -> [Exercise] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let startOfDay = calendar.date(from: dateComponents) ?? date
        
        return filteredExercises.filter { exercise in
            let exerciseComponents = calendar.dateComponents([.year, .month, .day], from: exercise.scheduledDate)
            let exerciseDay = calendar.date(from: exerciseComponents) ?? exercise.scheduledDate
            return startOfDay == exerciseDay
        }
    }
    
    // Get exercises for the current week
    func exercisesForCurrentWeek() -> [Date: [Exercise]] {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the start of the week (Sunday or Monday depending on locale)
        var startOfWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let startOfWeek = calendar.date(from: startOfWeekComponents) ?? today
        
        // Create date range for the week
        var dates: [Date] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        
        // Filter exercises for each day in the week
        var result: [Date: [Exercise]] = [:]
        for date in dates {
            let exercisesForDay = exercisesForDate(date)
            if !exercisesForDay.isEmpty {
                result[date] = exercisesForDay
            }
        }
        
        return result
    }
    
    // Mark an exercise as completed
    func toggleExerciseCompletion(exercise: Exercise) async {
        do {
            let _ = try await exerciseService.updateExercise(id: exercise.id, completed: !exercise.completed)
            
            // Update local data after successful API call
            if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                var updatedExercise = exercises[index]
                updatedExercise.completed = !updatedExercise.completed
                exercises[index] = updatedExercise
            }
        } catch {
            errorMessage = "Failed to update exercise: \(error.localizedDescription)"
        }
    }
    
    // Delete an exercise
    func deleteExercise(id: String) async {
        do {
            try await exerciseService.deleteExercise(id: id)
            
            // Remove from local data after successful deletion
            exercises.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete exercise: \(error.localizedDescription)"
        }
    }
    
    // Generate exercises using AI
    func generateExercises(symptomIds: [String], startDate: Date? = nil, durationDays: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let generatedExercises = try await exerciseService.generateExercises(
                symptomIds: symptomIds,
                startDate: startDate,
                durationDays: durationDays
            )
            
            // Add new exercises to the existing list
            exercises.append(contentsOf: generatedExercises)
            isLoading = false
        } catch {
            errorMessage = "Failed to generate exercises: \(error.localizedDescription)"
            isLoading = false
        }
    }
} 