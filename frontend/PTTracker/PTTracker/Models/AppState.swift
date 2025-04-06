import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool
    
    init() {
        // For testing purposes: reset the flag to always show loading screen
        // Later you can uncomment the normal implementation
        // UserDefaults.standard.set(false, forKey: "hasLaunchedBefore") // Force first launch for testing
        
        // Check if this is the first launch of the app
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        isFirstLaunch = !hasLaunchedBefore
        
        // After first launch, set the flag
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    // For testing - call this to force show loading screen again
    func resetFirstLaunch() {
        UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
        isFirstLaunch = true
    }
} 