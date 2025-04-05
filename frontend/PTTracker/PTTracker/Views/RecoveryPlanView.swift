import SwiftUI
import UIKit

struct RecoveryPlanView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel: RecoveryPlanViewModel
    @State private var showGeneratePlanConfirmation = false
    
    init() {
        _viewModel = StateObject(wrappedValue: RecoveryPlanViewModel(authManager: AuthManager.shared))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Recovery Plan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    } else if viewModel.hasRecoveryPlan {
                        recoveryPlanContent
                        
                        // Success message if plan was saved
                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .foregroundColor(.green)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    } else {
                        noPlanView
                    }
                }
                .padding(.vertical)
            }
            
            // Loading overlay for save
            if viewModel.isSaving {
                savingOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: generateButton)
        .alert("Generate Recovery Plan", isPresented: $showGeneratePlanConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Generate") {
                Task {
                    await viewModel.promptToGeneratePlan()
                }
            }
        } message: {
            Text("This will create a personalized recovery plan based on your reported symptoms. Continue?")
        }
        .alert("Overwrite Existing Plan?", isPresented: $viewModel.showOverwriteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Overwrite", role: .destructive) {
                Task {
                    await viewModel.generatePlan()
                }
            }
        } message: {
            Text("You already have a saved recovery plan. Generating a new plan will replace your existing one. Do you want to continue?")
        }
        .sheet(isPresented: $viewModel.showExerciseDetail) {
            if let selectedExercise = viewModel.selectedExercise {
                ExerciseDetailView(
                    viewModel: viewModel,
                    exercise: selectedExercise.exercise,
                    weekNumber: selectedExercise.weekNumber
                )
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            showGeneratePlanConfirmation = true
        }) {
            Text(viewModel.hasRecoveryPlan ? "Regenerate Plan" : "Generate Plan")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating your personalized recovery plan...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }
    
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Saving your recovery plan...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await viewModel.generatePlan()
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var noPlanView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("No Recovery Plan Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Generate a personalized recovery plan based on your symptoms and injuries.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            
            // Add a button here to simplify the UI and avoid emoji search issues
            Button(action: {
                showGeneratePlanConfirmation = true
            }) {
                Text("Create Recovery Plan")
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(.vertical, 60)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .onAppear {
            // Force dismiss keyboard if it's open
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var recoveryPlanContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Plan overview
            if let plan = viewModel.recoveryPlan {
                VStack(alignment: .leading, spacing: 12) {
                    Text(plan.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text(plan.description)
                        .font(.body)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Week selection
                    weekSelector
                        .padding(.horizontal)
                    
                    // Current week's exercises
                    weekContent
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    private var weekSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Program Weeks")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.weekNumbers, id: \.self) { week in
                        Button(action: {
                            viewModel.selectedWeek = week
                        }) {
                            VStack(spacing: 4) {
                                Text("Week \(week)")
                                    .fontWeight(.medium)
                                
                                // Progress indicator
                                let progress = viewModel.getProgressForWeek(week)
                                if progress.total > 0 {
                                    Text("\(progress.completed)/\(progress.total)")
                                        .font(.caption2)
                                        .foregroundColor(viewModel.selectedWeek == week ? .white.opacity(0.9) : .gray)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(viewModel.selectedWeek == week ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(viewModel.selectedWeek == week ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    private var weekContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let currentWeek = viewModel.currentWeekData {
                Text("Week \(currentWeek.weekNumber): \(currentWeek.focus)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top)
                
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(currentWeek.exercises.indices, id: \.self) { index in
                    exerciseRow(exercise: currentWeek.exercises[index], index: index)
                }
            } else {
                Text("No data available for this week")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.top, 8)
    }
    
    private func exerciseRow(exercise: RecoveryExercise, index: Int) -> some View {
        Button(action: {
            viewModel.showExerciseDetails(exercise: exercise, weekNumber: viewModel.selectedWeek)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // Exercise number and completion indicator
                    ZStack {
                        Circle()
                            .fill(exercise.isCompleted ? Color.green : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 30)
                        
                        if exercise.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(exercise.frequency)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Text(exercise.bodyPart)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
                
                Text(exercise.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // View details button
                HStack {
                    Spacer()
                    
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(exercise.isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(exercise.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecoveryPlanView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPlanView()
            .environmentObject(AuthManager.shared)
    }
} 