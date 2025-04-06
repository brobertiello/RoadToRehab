import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: ExercisesViewModel
    let exercise: Exercise
    
    @State private var isCompleted: Bool
    @State private var scheduledDate: Date
    @State private var notes: String
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var isUpdating = false
    @State private var errorMessage: String? = nil
    @State private var showingSuccessMessage = false
    
    init(viewModel: ExercisesViewModel, exercise: Exercise) {
        self.viewModel = viewModel
        self.exercise = exercise
        
        // Initialize state variables with fully qualified type names
        self._isCompleted = SwiftUI.State<Bool>(initialValue: exercise.completed)
        self._scheduledDate = SwiftUI.State<Date>(initialValue: exercise.scheduledDate)
        self._notes = SwiftUI.State<String>(initialValue: exercise.notes ?? "")
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                // Header with completion toggle and top actions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exercise.exerciseType)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(isCompleted ? .gray : .primary)
                            .strikethrough(isCompleted)
                        
                        Spacer()
                        
                        // Quick toggle without entering edit mode
                        Button(action: {
                            toggleCompletion()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isCompleted ? .green : .gray)
                                    .font(.title2)
                                
                                Text(isCompleted ? "Completed" : "Mark Complete")
                                    .font(.subheadline)
                                    .foregroundColor(isCompleted ? .green : .gray)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Exercise details grid
                VStack(alignment: .leading, spacing: 16) {
                    // Scheduled date with visual calendar
                    HStack(alignment: .center) {
                        Label("Scheduled", systemImage: "calendar")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 110, alignment: .leading)
                        
                        Spacer()
                        
                        if isEditing {
                            DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            HStack {
                                Text(scheduledDate.formatted(.dateTime.month().day().year()))
                                    .font(.body)
                                
                                // Visual indicator for today
                                if Calendar.current.isDateInToday(scheduledDate) {
                                    Text("Today")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Duration info
                    HStack {
                        Label("Duration", systemImage: "clock")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 110, alignment: .leading)
                        
                        Spacer()
                        
                        Text(exercise.formattedDuration)
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Difficulty stars
                    HStack {
                        Label("Difficulty", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 110, alignment: .leading)
                        
                        Spacer()
                        
                        Text(exercise.difficultyText)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Status (completed or not)
                    HStack {
                        Label("Status", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 110, alignment: .leading)
                        
                        Spacer()
                        
                        if isEditing {
                            Toggle("", isOn: $isCompleted)
                                .labelsHidden()
                        } else {
                            Text(isCompleted ? "Completed" : "Not Completed")
                                .foregroundColor(isCompleted ? .green : .red)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if isEditing {
                            TextEditor(text: $notes)
                                .frame(minHeight: 120)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(8)
                        } else {
                            Text(notes.isEmpty ? "No notes added" : notes)
                                .foregroundColor(notes.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Error and success messages
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                if showingSuccessMessage {
                    Text("Exercise updated successfully!")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onAppear {
                            // Auto-dismiss success message after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showingSuccessMessage = false
                                }
                            }
                        }
                }
                
                // Edit Mode buttons
                if isEditing {
                    HStack {
                        Button(action: {
                            isEditing = false
                            // Reset to original values
                            isCompleted = exercise.completed
                            scheduledDate = exercise.scheduledDate
                            notes = exercise.notes ?? ""
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            saveChanges()
                        }) {
                            if isUpdating {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text("Save Changes")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isUpdating)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                } else {
                    HStack {
                        Button(action: {
                            isEditing = true
                        }) {
                            Label("Edit Exercise", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                Spacer(minLength: 30)
            }
            .padding(.top)
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Exercise Details").font(.headline)
            }
        }
        .alert("Delete Exercise", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("Are you sure you want to delete this exercise? This action cannot be undone.")
        }
    }
    
    // Quick toggle completion function
    private func toggleCompletion() {
        isUpdating = true
        
        Task {
            // Create a temporary copy of the exercise with toggled completion
            var updatedExercise = exercise
            updatedExercise.completed = !isCompleted
            
            // Update in database
            await viewModel.toggleExerciseCompletion(exercise: updatedExercise)
            
            // Update local state
            DispatchQueue.main.async {
                isCompleted = !isCompleted
                isUpdating = false
                
                // Show brief success message
                withAnimation {
                    showingSuccessMessage = true
                }
                
                // Hide success message after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingSuccessMessage = false
                    }
                }
            }
        }
    }
    
    // Save changes function
    private func saveChanges() {
        isUpdating = true
        errorMessage = nil
        
        Task {
            do {
                // First update completion status if needed
                if exercise.completed != isCompleted {
                    // Create a temporary exercise with updated completion
                    var updatedExercise = exercise
                    updatedExercise.completed = isCompleted
                    await viewModel.toggleExerciseCompletion(exercise: updatedExercise)
                }
                
                // Then update other fields
                if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    // Update the exercise with new details
                    var updatedExercise = viewModel.exercises[index]
                    updatedExercise.scheduledDate = scheduledDate
                    updatedExercise.notes = notes.isEmpty ? nil : notes
                    
                    // Update on server
                    _ = try await viewModel.exerciseService.updateExercise(
                        id: exercise.id,
                        scheduledDate: scheduledDate,
                        notes: notes.isEmpty ? nil : notes
                    )
                    
                    // Update local copy
                    viewModel.exercises[index] = updatedExercise
                    viewModel.objectWillChange.send()
                }
                
                DispatchQueue.main.async {
                    isUpdating = false
                    isEditing = false
                    showingSuccessMessage = true
                    
                    // Refresh all exercises to ensure we have the latest data
                    Task {
                        await viewModel.refreshExercises()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to update exercise: \(error.localizedDescription)"
                    isUpdating = false
                    print("Error saving exercise changes: \(error)")
                }
            }
        }
    }
    
    // Delete exercise function
    private func deleteExercise() {
        Task {
            await viewModel.deleteExercise(id: exercise.id)
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager.shared
        let viewModel = ExercisesViewModel(authManager: authManager)
        let sampleExercise = Exercise(
            exerciseType: "Neck Stretches", 
            description: "Slowly tilt your head toward your shoulder, using your hand to apply gentle pressure.",
            scheduledDate: Date(),
            duration: "Hold for 15-30 seconds, 3 sets per side, daily",
            sets: 3,
            repetitions: 10,
            symptomId: "sample-id",
            difficulty: 2,
            notes: "Take it slow and be gentle with this one."
        )
        
        NavigationView {
            ExerciseDetailView(viewModel: viewModel, exercise: sampleExercise)
        }
        .environmentObject(authManager)
    }
} 