import SwiftUI

struct RecoveryPlanView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel: RecoveryPlanViewModel
    @State private var showGeneratePlanConfirmation = false
    
    init() {
        _viewModel = StateObject(wrappedValue: RecoveryPlanViewModel(authManager: AuthManager.shared))
    }
    
    var body: some View {
        NavigationView {
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
                        } else {
                            noPlanView
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: generateButton)
            .alert("Generate Recovery Plan", isPresented: $showGeneratePlanConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Generate") {
                    Task {
                        await viewModel.generatePlan()
                    }
                }
            } message: {
                Text("This will create a personalized recovery plan based on your reported symptoms. Continue?")
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
            
            Button(action: {
                showGeneratePlanConfirmation = true
            }) {
                Text("Generate Recovery Plan")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .padding(.vertical, 60)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
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
                            Text("Week \(week)")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\(index + 1).")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exercise.frequency)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct RecoveryPlanView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPlanView()
            .environmentObject(AuthManager.shared)
    }
} 