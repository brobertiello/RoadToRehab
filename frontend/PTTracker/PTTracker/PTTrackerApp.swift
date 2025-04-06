import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var symptomsViewModel = SymptomsViewModel(authManager: AuthManager.shared)
    @StateObject private var exercisesViewModel = ExercisesViewModel(authManager: AuthManager.shared)
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var dbConfigService = DatabaseConfigService.shared
    
    init() {
        // Initialize chat view model with the other view models
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(
            authManager: AuthManager.shared,
            symptomViewModel: SymptomsViewModel(authManager: AuthManager.shared),
            exercisesViewModel: ExercisesViewModel(authManager: AuthManager.shared)
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(symptomsViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(exercisesViewModel)
                .environmentObject(dbConfigService)
        }
    }
} 