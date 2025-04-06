import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var symptomsViewModel = SymptomsViewModel(authManager: AuthManager.shared)
    @StateObject private var exercisesViewModel = ExercisesViewModel(authManager: AuthManager.shared)
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var dbConfigService = DatabaseConfigService.shared
    @StateObject private var appState = AppState()
    
    init() {
        // Initialize chat view model with the other view models
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(
            authManager: AuthManager.shared,
            symptomViewModel: SymptomsViewModel(authManager: AuthManager.shared),
            exercisesViewModel: ExercisesViewModel(authManager: AuthManager.shared)
        ))
        
        // Configure app on first launch
        configureFirstLaunch()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(symptomsViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(exercisesViewModel)
                .environmentObject(dbConfigService)
                .environmentObject(appState)
        }
    }
    
    private func configureFirstLaunch() {
        // Pre-warm any necessary services or resources here
        // This is similar to the AppDelegate in UIKit
        DispatchQueue.global(qos: .userInitiated).async {
            // Initialize any background services that might be needed
            // before the app fully loads
        }
    }
}

// App state class to track global app state
class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool
    
    init() {
        // Check if this is the first launch of the app
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        isFirstLaunch = !hasLaunchedBefore
        
        // After first launch, set the flag
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
} 