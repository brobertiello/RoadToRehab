import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authManager.currentUser {
                    Text("Welcome, \(user.name)")
                        .font(.title)
                        .padding(.top)
                    
                    // Dashboard content would go here
                    // This is a placeholder for future functionality
                    VStack(alignment: .leading, spacing: 15) {
                        DashboardCard(title: "My Exercises", icon: "figure.walk", color: .blue)
                        DashboardCard(title: "Symptom Tracker", icon: "waveform.path.ecg", color: .green)
                        DashboardCard(title: "Progress Reports", icon: "chart.bar.fill", color: .orange)
                        DashboardCard(title: "Settings", icon: "gear", color: .gray)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    Text("Loading...")
                        .font(.title)
                }
            }
            .navigationTitle("PT Tracker")
            .navigationBarItems(trailing: Button("Logout") {
                authManager.logout()
            })
        }
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(.systemGray4))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
} 