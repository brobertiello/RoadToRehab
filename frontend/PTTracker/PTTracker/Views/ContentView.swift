import SwiftUI
import UIKit // Required for UIApplication extension

// LoadingIconView from MediaPipe
struct LoadingIconView: View {
    let icons = [
        "figure.basketball",
        "figure.fall",
        "figure.pilates",
        "figure.roll",
        "figure.rolling",
        "figure.walk",
        "figure.cross.training",
        "figure.cooldown",
        "figure.run"
    ]
    
    @State private var currentIndex = 0
    let onIconChange: (Int, Int) -> Void
    
    // App blue color
    let appBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    
    init(onIconChange: @escaping (Int, Int) -> Void = { _, _ in }) {
        self.onIconChange = onIconChange
    }

    var body: some View {
        // More robust fixed size container with clipping and alignment
        ZStack {
            // Create a fixed frame container with clear background
            Color.clear
                .frame(width: 120, height: 120)
            
            // The actual icon with fixed frame and clipping
            Image(systemName: icons[currentIndex])
                .font(.system(size: 60, weight: .regular, design: .default))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(appBlue) // Use app blue color
                .frame(width: 80, height: 80) // Fixed size for all icons
                .transition(.opacity.combined(with: .scale))
                .id(currentIndex) // Force view recreation on index change
                .clipped() // Clip any parts that exceed the frame
                .fixedSize() // Prevent auto-sizing
        }
        .frame(width: 120, height: 120) // Consistent outer frame
        .onAppear {
            // Timer to change the symbol every 0.6 seconds (faster animation)
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Update index and notify parent about progress
                    currentIndex = (currentIndex + 1) % icons.count
                    
                    // Notify parent about icon change and total count
                    onIconChange(currentIndex, icons.count)
                }
            }
        }
    }
}

// LoadingScreen from MediaPipe
struct LoadingScreen: View {
    @Binding var isLoaded: Bool
    @State private var progress = 0.0
    @State private var showText = false
    @State private var animationComplete = false
    @State private var currentIconIndex = 0
    @State private var totalIcons = 9 // Default, will be updated
    
    // Timer for smooth progress bar animation
    @State private var progressTimer: Timer?
    // Total loading duration in seconds - shorter to match actual loading
    private let totalLoadingTime: Double = 3.0
    
    // App blue color
    let appBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Background - white instead of black
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Fixed layout with specific spacing and alignment
            VStack(spacing: 0) {
                // Icon animation container with fixed frame and alignment
                ZStack {
                    // Empty fixed space to guarantee consistent layout
                    Color.clear.frame(height: 120)
                    
                    // Icon with callback for progress updates
                    LoadingIconView(onIconChange: { index, total in
                        totalIcons = total
                        currentIconIndex = index
                    })
                }
                .frame(height: 120) // Fixed height for icon area
                .padding(.bottom, 40)
                
                // App title with appearance animation
                Text("Road to Recovery")
                    .font(.largeTitle.bold())
                    .foregroundColor(appBlue) // Use app blue color
                    .opacity(showText ? 1 : 0)
                    .scaleEffect(showText ? 1 : 0.8)
                    .frame(height: 50) // Fixed height
                    .padding(.bottom, 40)
                
                // Progress bar - fixed position
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 200, height: 4)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .frame(width: 200 * progress, height: 4)
                        .foregroundColor(appBlue) // Use app blue color
                }
                .frame(height: 20) // Fixed height including padding
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity) // Lock width
        }
        .onAppear {
            // Show text after a brief delay
            withAnimation(.easeIn.delay(0.5)) {
                showText = true
            }
            
            // Start completely linear, fixed-rate progress bar animation
            startFixedRateProgressAnimation()
        }
        .onDisappear {
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }
    
    private func startFixedRateProgressAnimation() {
        // Get start time
        let startTime = Date()
        
        // Create a timer that updates progress bar smoothly at 60fps
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
            // Calculate elapsed time
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Very simple, completely linear progression based only on time
            progress = min(elapsed / totalLoadingTime, 1.0)
            
            // If we're done, prepare for dismissal without waiting for specific icon
            if progress >= 1.0 {
                progress = 1.0
                timer.invalidate()
                prepareForDismissal()
            }
        }
    }
    
    private func prepareForDismissal() {
        // Only proceed if we haven't already started the dismissal process
        if !animationComplete {
            animationComplete = true
            
            // Add a tap gesture recognizer to the whole screen
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIApplication.shared.dismissLoadingScreen))
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addGestureRecognizer(tapGesture)
            }
            
            // Transition to main content immediately with a smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isLoaded = true
                }
                
                // Remove the gesture recognizer
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    for recognizer in window.gestureRecognizers ?? [] {
                        window.removeGestureRecognizer(recognizer)
                    }
                }
            }
        }
    }
}

// Extension to allow for dismissing the loading screen
extension UIApplication {
    @objc func dismissLoadingScreen() {
        // This is needed to make the loading screen dismissable by tap
        NotificationCenter.default.post(name: Notification.Name("DismissLoadingScreen"), object: nil)
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var isAppLoaded = false
    
    var body: some View {
        ZStack {
            // Always show loading screen first on app's first launch
            // regardless of authentication status
            if !isAppLoaded && appState.isFirstLaunch {
                // Loading screen
                LoadingScreen(isLoaded: $isAppLoaded)
                    .onAppear {
                        // Set up notification observer for the loading screen
                        setupLoadingScreenObserver()
                    }
            } else {
                // Main app content
                Group {
                    if authManager.isAuthenticated {
                        DashboardView()
                    } else {
                        LandingView()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.5), value: isAppLoaded)
    }
    
    // Setup notification observer for loading screen dismissal
    private func setupLoadingScreenObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("DismissLoadingScreen"), object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.5)) {
                isAppLoaded = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager.shared)
            .environmentObject(AppState())
    }
} 