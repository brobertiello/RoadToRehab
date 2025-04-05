import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RecoveryPlanViewModel
    let exercise: RecoveryExercise
    let weekNumber: Int
    
    @State private var showingCamera = false
    @State private var localIsCompleted: Bool
    
    init(viewModel: RecoveryPlanViewModel, exercise: RecoveryExercise, weekNumber: Int) {
        self.viewModel = viewModel
        self.exercise = exercise
        self.weekNumber = weekNumber
        // Initialize local state from the passed exercise
        _localIsCompleted = State(initialValue: exercise.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Exercise header
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(exercise.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("For \(exercise.bodyPart)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Completion status badge
                        if localIsCompleted {
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Instructions")
                            .font(.headline)
                        
                        Text(exercise.description)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Frequency
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Frequency & Intensity")
                            .font(.headline)
                        
                        Text(exercise.frequency)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.headline)
                                Text("Perform Exercise")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            localIsCompleted = true
                            viewModel.markExerciseAsCompleted(exercise: exercise, weekNumber: weekNumber)
                            
                            // Add visual feedback that the exercise was completed
                            withAnimation {
                                // First update the local state for immediate visual feedback
                                localIsCompleted = true
                            }
                            
                            // Add a slight delay before dismissing to let the user see the completion state change
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                Text("Complete Exercise")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(localIsCompleted ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(localIsCompleted)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Exercise Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingCamera) {
                CameraPlaceholderView()
            }
            .onAppear {
                // Ensure local state is synced with the current exercise state
                // This handles cases where the exercise might have been updated elsewhere
                localIsCompleted = exercise.isCompleted
                print("ExerciseDetailView appeared: Exercise \(exercise.name) isCompleted = \(exercise.isCompleted)")
            }
        }
    }
}

// Placeholder for the camera view
struct CameraPlaceholderView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                Text("Camera Integration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("This is a placeholder for the camera view that would allow users to record themselves performing the exercise.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .foregroundColor(.secondary)
            }
            .navigationBarTitle("Perform Exercise", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let exercise = RecoveryExercise(
            bodyPart: "Knee",
            name: "Straight Leg Raises",
            description: "Lie on your back with one leg straight and the other bent. Tighten the thigh muscle of the straight leg and lift it several inches off the floor. Hold briefly, then lower slowly.",
            frequency: "3 sets of 10 reps, twice daily"
        )
        
        ExerciseDetailView(
            viewModel: RecoveryPlanViewModel(authManager: AuthManager.shared),
            exercise: exercise,
            weekNumber: 1
        )
    }
} 