import SwiftUI

struct RecoveryPlanView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Recovery Plan")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your personalized recovery plan includes exercises and activities designed specifically for your condition. Follow along with your plan to optimize your recovery.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text("Coming Soon!")
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                .padding(.bottom, 40)
        }
        .padding()
        .navigationTitle("Recovery Plan")
    }
} 