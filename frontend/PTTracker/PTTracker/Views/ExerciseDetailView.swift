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
                // Exercise type and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.exerciseType)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Exercise details
                VStack(alignment: .leading, spacing: 16) {
                    detailRow(icon: "calendar", title: "Scheduled Date") {
                        if isEditing {
                            DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                                .labelsHidden()
                        } else {
                            Text(scheduledDate.formatted(.dateTime.month().day().year()))
                        }
                    }
                    
                    detailRow(icon: "clock", title: "Duration") {
                        Text(exercise.formattedDuration)
                    }
                    
                    detailRow(icon: "star.fill", title: "Difficulty") {
                        Text(exercise.difficultyText)
                            .foregroundColor(.orange)
                    }
                    
                    detailRow(icon: "checkmark.circle", title: "Status") {
                        if isEditing {
                            Toggle("", isOn: $isCompleted)
                                .labelsHidden()
                        } else {
                            Text(isCompleted ? "Completed" : "Not Completed")
                                .foregroundColor(isCompleted ? .green : .red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .frame(width: 25)
                                .foregroundColor(.blue)
                            Text("Notes")
                                .font(.headline)
                        }
                        
                        if isEditing {
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Text(notes.isEmpty ? "No notes added" : notes)
                                .foregroundColor(notes.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer(minLength: 30)
            }
            .padding(.top)
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: leadingBarItem,
            trailing: trailingBarItem
        )
        .alert("Delete Exercise", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("Are you sure you want to delete this exercise? This action cannot be undone.")
        }
    }
    
    // Leading bar item (cancel button when editing)
    @ViewBuilder
    private var leadingBarItem: some View {
        if isEditing {
            Button("Cancel") {
                isEditing = false
                // Reset to original values
                isCompleted = exercise.completed
                scheduledDate = exercise.scheduledDate
                notes = exercise.notes ?? ""
            }
        } else {
            EmptyView()
        }
    }
    
    // Trailing bar item (save/edit/delete)
    @ViewBuilder
    private var trailingBarItem: some View {
        if isEditing {
            if isUpdating {
                ProgressView()
            } else {
                Button("Save") {
                    saveChanges()
                }
            }
        } else {
            Menu {
                Button(action: {
                    isEditing = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                        .foregroundColor(.red)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    // Helper function to create detail rows
    private func detailRow<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 25)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            content()
        }
        .padding(.horizontal)
    }
    
    // Save changes function
    private func saveChanges() {
        isUpdating = true
        errorMessage = nil
        
        Task {
            do {
                // Use the ViewModel's toggle method instead of directly accessing exerciseService
                // First update completion status if needed
                if exercise.completed != isCompleted {
                    await updateCompletionStatus()
                }
                
                // Then update other fields
                await updateExerciseDetails()
                
                DispatchQueue.main.async {
                    isUpdating = false
                    isEditing = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to update exercise: \(error.localizedDescription)"
                    isUpdating = false
                }
            }
        }
    }
    
    // Helper to update completion status
    private func updateCompletionStatus() async {
        // Find the exercise in the viewModel
        if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }) {
            // Create a temporary updated exercise with the new completion status
            var updatedExercise = viewModel.exercises[index]
            // Only toggle completion if it's different
            if updatedExercise.completed != isCompleted {
                // Use the viewModel method to toggle
                await viewModel.toggleExerciseCompletion(exercise: updatedExercise)
            }
        }
    }
    
    // Helper to update exercise details
    private func updateExerciseDetails() async {
        // Find the exercise in the viewModel
        if let index = viewModel.exercises.firstIndex(where: { $0.id == exercise.id }) {
            // Update the exercise directly in the viewModel
            var updatedExercise = viewModel.exercises[index]
            updatedExercise.scheduledDate = scheduledDate
            updatedExercise.notes = notes.isEmpty ? nil : notes
            // Update in the viewModel
            viewModel.exercises[index] = updatedExercise
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