import SwiftUI

@main
struct PTTrackerApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                DashboardView()
                    .environmentObject(authManager)
            } else {
                LandingView()
                    .environmentObject(authManager)
            }
        }
    }
} 