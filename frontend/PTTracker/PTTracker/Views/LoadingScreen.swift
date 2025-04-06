import SwiftUI
import UIKit

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
    @State private var cycleComplete = false
    let onIconChange: (Int, Int) -> Void
    
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
                .foregroundColor(.white)
                .frame(width: 80, height: 80) // Fixed size for all icons
                .transition(.opacity.combined(with: .scale))
                .id(currentIndex) // Force view recreation on index change
                .clipped() // Clip any parts that exceed the frame
                .fixedSize() // Prevent auto-sizing
        }
        .frame(width: 120, height: 120) // Consistent outer frame
        .onAppear {
            // Timer to change the symbol every 0.8 seconds
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Update index and notify parent about progress
                    let oldIndex = currentIndex
                    currentIndex = (currentIndex + 1) % icons.count
                    
                    // Notify parent about icon change and total count
                    onIconChange(currentIndex, icons.count)
                    
                    // Check if we've shown all icons (completed one full cycle)
                    if oldIndex == icons.count - 1 {
                        cycleComplete = true
                        timer.invalidate() // Stop the timer after one full cycle
                    }
                }
            }
        }
    }
}

struct LoadingScreen: View {
    @Binding var isLoaded: Bool
    @State private var progress = 0.0
    @State private var showText = false
    @State private var animationComplete = false
    @State private var currentIconIndex = 0
    @State private var totalIcons = 10 // Default, will be updated
    
    // Timer for smooth progress bar animation
    @State private var progressTimer: Timer?
    // Total loading duration in seconds
    private let totalLoadingTime: Double = 8.0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
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
                        
                        // When we reach the last icon, ensure we're close to done
                        if index == total - 1 && progress < 0.9 {
                            // Speed up if needed to ensure we complete together
                            progress = 0.9
                        }
                    })
                }
                .frame(height: 120) // Fixed height for icon area
                .padding(.bottom, 40)
                
                // App title with appearance animation
                Text("Road To Rehab")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
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
                        .foregroundColor(.white)
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
            // This ensures absolutely constant rate regardless of icon changes
            progress = min(elapsed / totalLoadingTime, 1.0)
            
            // If we're done, prepare for dismissal
            if progress >= 0.99 && currentIconIndex == totalIcons - 1 {
                progress = 1.0
                timer.invalidate()
                prepareForDismissal()
            }
            
            // If we're nearly done with time but still showing icons, slow down progress
            if progress > 0.95 && currentIconIndex < totalIcons - 1 {
                // Hold at 95% until the last icon is shown
                progress = 0.95
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
            
            // Transition to main content after a short delay to allow final animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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