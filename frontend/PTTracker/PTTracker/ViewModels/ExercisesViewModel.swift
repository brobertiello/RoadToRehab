import Foundation
import SwiftUI

@MainActor
class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var filterSymptomId: String? = nil
    @Published var lastUpdated: Date = Date()
    
    // Make service accessible
    let exerciseService: ExerciseService
    
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
            lastUpdated = Date()
            print("Fetched \(exercises.count) exercises. Completed: \(exercises.filter { $0.completed }.count)")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
            print("API Error fetching exercises: \(error)")
        } catch {
            errorMessage = "Failed to fetch exercises: \(error.localizedDescription)"
            isLoading = false
            print("Unknown error fetching exercises: \(error)")
        }
    }
    
    // Refresh exercises data from server
    func refreshExercises() async {
        await fetchExercises()
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
            print("Toggling exercise completion for ID: \(exercise.id), current status: \(exercise.completed)")
            
            // Call API to update exercise status
            let updatedExercise = try await exerciseService.updateExercise(
                id: exercise.id, 
                completed: !exercise.completed
            )
            
            print("API returned updated exercise with completion status: \(updatedExercise.completed)")
            
            // Update local data after successful API call
            if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                // Update using the response from the server
                exercises[index] = updatedExercise
                print("Updated local exercise with completion status: \(exercises[index].completed)")
                
                // Force UI refresh
                self.objectWillChange.send()
            } else {
                print("Error: Could not find exercise with ID \(exercise.id) in local data")
            }
            
            // Refresh data from server after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    await self.refreshExercises()
                }
            }
        } catch {
            errorMessage = "Failed to update exercise: \(error.localizedDescription)"
            print("Error toggling exercise completion: \(error)")
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
            print("Error deleting exercise: \(error)")
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
            print("Error generating exercises: \(error)")
        }
    }
} 