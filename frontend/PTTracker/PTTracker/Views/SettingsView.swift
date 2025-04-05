import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showConfirmLogout = false
    
    var body: some View {
        Form {
            Section(header: Text("Account")) {
                Button(action: {
                    showConfirmLogout = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.red)
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(header: Text("Preferences")) {
                Text("Notification settings")
                Text("Theme settings")
                Text("Privacy settings")
            }
            
            /* Comment out until we fix the error
            Section(header: Text("Admin")) {
                NavigationLink(destination: DatabaseConfigView()) {
                    HStack {
                        Image(systemName: "server.rack")
                        Text("Database Configuration")
                    }
                }
            }
            */
            
            Section(header: Text("Support")) {
                Text("Contact support")
                Text("Report a bug")
                Text("User guide")
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showConfirmLogout) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    authManager.logout()
                },
                secondaryButton: .cancel()
            )
        }
    }
} 