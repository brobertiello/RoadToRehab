import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var symptomsViewModel: SymptomsViewModel
    @EnvironmentObject var exercisesViewModel: ExercisesViewModel
    @State private var selectedTab = 0
    @State private var showChatView = false
    
    var body: some View {
        ZStack {
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
            
            // Floating Chat Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showChatView = true
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 80) // Keep above tab bar
                }
            }
        }
        .sheet(isPresented: $showChatView) {
            ChatView(viewModel: chatViewModel)
        }
        .onAppear {
            // Load symptoms for the recovery plan
            Task {
                await symptomsViewModel.fetchSymptoms()
                await exercisesViewModel.fetchExercises()
            }
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