import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var symptomsViewModel: SymptomsViewModel
    
    init() {
        let auth = AuthManager()
        _authManager = StateObject(wrappedValue: auth)
        _symptomsViewModel = StateObject(wrappedValue: SymptomsViewModel(authManager: auth))
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                DashboardView()
                    .environmentObject(authManager)
                    .environmentObject(symptomsViewModel)
            } else {
                LandingView()
                    .environmentObject(authManager)
            }
        }
    }
} 