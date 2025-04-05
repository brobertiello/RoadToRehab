import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var symptomsViewModel: SymptomsViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    init() {
        let auth = AuthManager()
        _authManager = StateObject(wrappedValue: auth)
        _symptomsViewModel = StateObject(wrappedValue: SymptomsViewModel(authManager: auth))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(authManager: auth))
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                DashboardView()
                    .environmentObject(authManager)
                    .environmentObject(symptomsViewModel)
                    .environmentObject(chatViewModel)
            } else {
                LandingView()
                    .environmentObject(authManager)
            }
        }
    }
} 