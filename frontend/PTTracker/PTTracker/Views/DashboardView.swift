import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(0)
            
            NavigationView {
                SymptomsView()
            }
            .tabItem {
                Image(systemName: "waveform.path.ecg")
                Text("Symptoms")
            }
            .tag(1)
            
            NavigationView {
                RecoveryPlanView()
            }
            .tabItem {
                Image(systemName: "figure.walk")
                Text("Recovery")
            }
            .tag(2)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .accentColor(.blue)
        .environmentObject(authManager)
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