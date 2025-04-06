import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var chatService: ChatService
    private var authManager: AuthManager
    private var symptomViewModel: SymptomsViewModel
    private var exercisesViewModel: ExercisesViewModel
    
    // For maintaining contextual awareness even with simple API
    private var contextualPrompt: String = ""
    private var lastQuery: String = ""
    
    init(authManager: AuthManager, symptomViewModel: SymptomsViewModel, exercisesViewModel: ExercisesViewModel) {
        self.authManager = authManager
        self.symptomViewModel = symptomViewModel
        self.exercisesViewModel = exercisesViewModel
        self.chatService = ChatService(authManager: authManager)
        
        // Add welcome message
        messages.append(ChatMessage.botMessage("Hello! I'm your PT assistant. How can I help with your recovery journey today?"))
    }
    
    // Update references to environment objects
    func updateReferences(authManager: AuthManager, symptomViewModel: SymptomsViewModel, exercisesViewModel: ExercisesViewModel) {
        self.authManager = authManager
        self.symptomViewModel = symptomViewModel
        self.exercisesViewModel = exercisesViewModel
        self.chatService = ChatService(authManager: authManager)
    }
    
    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let messageToSend = ChatMessage.userMessage(userMessage)
        
        DispatchQueue.main.async {
            self.messages.append(messageToSend)
            self.inputMessage = ""
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Prepare context for the chat
            let userName = authManager.currentUser?.name ?? "User"
            
            // Format symptoms data
            var symptomsContext = ""
            let symptoms = await symptomViewModel.symptoms
            if symptoms.isEmpty {
                symptomsContext += "No symptoms recorded yet.\n"
            } else {
                for symptom in symptoms {
                    symptomsContext += "• \(symptom.bodyPart) (Current Severity: \(symptom.currentSeverity)/10)\n"
                    
                    // Add severity history if available
                    if symptom.severities.count > 1 {
                        let sortedSeverities = symptom.severities.sorted(by: { $0.date > $1.date }).prefix(3)
                        symptomsContext += "  History: "
                        for (index, severity) in sortedSeverities.enumerated() {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .short
                            symptomsContext += "\(dateFormatter.string(from: severity.date)): \(severity.value)/10"
                            if index < sortedSeverities.count - 1 {
                                symptomsContext += ", "
                            }
                        }
                        symptomsContext += "\n"
                    }
                    
                    // Add notes if available
                    if let notes = symptom.notes, !notes.isEmpty {
                        symptomsContext += "  Notes: \(notes)\n"
                    }
                    
                    symptomsContext += "\n"
                }
            }
            
            // Format exercise data with more details
            var exercisesContext = ""
            let exercises = await exercisesViewModel.exercises
            
            if exercises.isEmpty {
                exercisesContext += "No exercises prescribed yet.\n"
            } else {
                // Get the current date
                let today = Date()
                let calendar = Calendar.current
                
                // Get exercises for the next 7 days
                var upcomingExercises: [Date: [Exercise]] = [:]
                for i in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: i, to: today) {
                        let exercisesForDate = await exercisesViewModel.exercisesForDate(date)
                        if !exercisesForDate.isEmpty {
                            upcomingExercises[date] = exercisesForDate
                        }
                    }
                }
                
                if upcomingExercises.isEmpty {
                    exercisesContext += "No exercises scheduled for the upcoming week.\n"
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    
                    let sortedDates = upcomingExercises.keys.sorted()
                    
                    for date in sortedDates {
                        let isToday = calendar.isDateInToday(date)
                        let dateLabel = isToday ? "Today" : dateFormatter.string(from: date)
                        
                        exercisesContext += "• \(dateLabel):\n"
                        
                        if let exercisesForDate = upcomingExercises[date] {
                            for exercise in exercisesForDate {
                                let status = exercise.completed ? "✓ Completed" : "○ Not completed"
                                
                                exercisesContext += "  - \(exercise.exerciseType): \(status)\n"
                                exercisesContext += "    Description: \(exercise.description)\n"
                                
                                // Add difficulty
                                exercisesContext += "    Difficulty: \(exercise.difficulty)/5\n"
                                
                                // Add exercise details if available
                                if let sets = exercise.sets, let reps = exercise.repetitions {
                                    exercisesContext += "    Prescription: \(sets) sets of \(reps) repetitions\n"
                                } else if let duration = exercise.duration {
                                    exercisesContext += "    Duration: \(duration)\n"
                                }
                                
                                // Add notes if available
                                if let notes = exercise.notes, !notes.isEmpty {
                                    exercisesContext += "    Notes: \(notes)\n"
                                }
                                
                                exercisesContext += "\n"
                            }
                        }
                    }
                    
                    // Add overall completion rate
                    let totalExercises = exercises.count
                    let completedExercises = exercises.filter { $0.completed }.count
                    let completionRate = totalExercises > 0 ? Double(completedExercises) / Double(totalExercises) * 100 : 0
                    
                    exercisesContext += "Overall Progress: \(completedExercises)/\(totalExercises) exercises completed (\(Int(completionRate))%)\n"
                }
            }
            
            // Build a contextually enhanced message to maintain conversation continuity
            var enhancedUserMessage = userMessage
            
            // If we have prior conversation and this isn't the first message
            if messages.count > 2 {
                // Add recent conversation context (latest 3 exchanges, last 6 messages)
                enhancedUserMessage = "Our recent conversation: \n"
                
                let recentMessages = messages.suffix(min(6, messages.count - 1)) // Get the last few messages excluding welcome
                
                for (index, msg) in recentMessages.enumerated() {
                    if index % 2 == 0 {
                        enhancedUserMessage += "User: \(msg.message)\n"
                    } else {
                        enhancedUserMessage += "Assistant: \(msg.message)\n"
                    }
                }
                
                enhancedUserMessage += "\nWith that context, please respond to my new question: \(userMessage)"
            }
            
            // Send message with the enhanced context
            let response = try await chatService.sendMessage(
                enhancedUserMessage,
                userName: userName,
                symptomsContext: symptomsContext,
                exercisesContext: exercisesContext
            )
            
            DispatchQueue.main.async {
                self.messages.append(ChatMessage.botMessage(response.response))
                self.isLoading = false
            }
        } catch APIError.requestFailed(let message) {
            DispatchQueue.main.async {
                self.errorMessage = message
                self.isLoading = false
                self.messages.append(ChatMessage.botMessage("Sorry, I encountered an error. Please try again."))
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.messages.append(ChatMessage.botMessage("Sorry, I encountered an error. Please try again."))
            }
        }
    }
    
    func clearChat() {
        messages.removeAll(where: { $0.isUserMessage })
        messages.removeAll(where: { !$0.isUserMessage && $0.message != "Hello! I'm your PT assistant. How can I help with your recovery journey today?" })
    }
} 