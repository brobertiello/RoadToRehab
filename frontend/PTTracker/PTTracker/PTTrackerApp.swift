import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var symptomsViewModel = SymptomsViewModel(authManager: AuthManager.shared)
    @StateObject private var chatViewModel = ChatViewModel(authManager: AuthManager.shared)
    @StateObject private var exercisesViewModel = ExercisesViewModel(authManager: AuthManager.shared)
    @StateObject private var dbConfigService = DatabaseConfigService.shared
    
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