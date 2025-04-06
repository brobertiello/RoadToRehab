import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showConfirmLogout = false
    @State private var showUserGuide = false
    
    var body: some View {
        Form {
            Section(header: Text("Account")) {
                NavigationLink(destination: AccountSettingsView()) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Account Details")
                    }
                }
                
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
                NavigationLink(destination: NotificationSettingsView()) {
                    HStack {
                        Image(systemName: "bell")
                        Text("Notification Settings")
                    }
                }
                
                NavigationLink(destination: PrivacySettingsView()) {
                    HStack {
                        Image(systemName: "lock.shield")
                        Text("Privacy Settings")
                    }
                }
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
                NavigationLink(destination: ContactSupportView()) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("Contact Support")
                    }
                }
                
                NavigationLink(destination: ReportBugView()) {
                    HStack {
                        Image(systemName: "ant")
                        Text("Report a Bug")
                    }
                }
                
                Button(action: {
                    showUserGuide = true
                }) {
                    HStack {
                        Image(systemName: "book")
                        Text("User Guide")
                    }
                }
            }
            
            Section(header: Text("About")) {
                NavigationLink(destination: AboutAppView()) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About Road to Rehab")
                    }
                }
                
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
        .sheet(isPresented: $showUserGuide) {
            UserGuideView()
        }
    }
}

// Account Settings View
struct AccountSettingsView: View {
    @State private var email = ""
    @State private var notificationsEnabled = true
    @State private var showSaved = false
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(AuthManager.shared.currentUser?.name ?? "User")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Email")
                    Spacer()
                    Text(AuthManager.shared.currentUser?.email ?? "user@example.com")
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    showSaved = true
                }) {
                    Text("Edit Profile")
                }
            }
            
            Section(header: Text("Security")) {
                Button(action: {
                    showSaved = true
                }) {
                    Text("Change Password")
                }
                
                Button(action: {
                    showSaved = true
                }) {
                    Text("Two-Factor Authentication")
                }
            }
        }
        .navigationTitle("Account")
        .alert(isPresented: $showSaved) {
            Alert(
                title: Text("Feature Not Implemented"),
                message: Text("This feature is not active in the current version."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Notification Settings View
struct NotificationSettingsView: View {
    @State private var exerciseReminders = true
    @State private var completionReminders = true
    @State private var weeklyReports = true
    @State private var showSaved = false
    
    var body: some View {
        Form {
            Section(header: Text("Exercise Reminders")) {
                Toggle("Daily exercise reminders", isOn: $exerciseReminders)
                Toggle("Completion reminders", isOn: $completionReminders)
            }
            
            Section(header: Text("Reports")) {
                Toggle("Weekly progress reports", isOn: $weeklyReports)
            }
            
            Section {
                Button(action: {
                    showSaved = true
                }) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
        }
        .navigationTitle("Notifications")
        .alert(isPresented: $showSaved) {
            Alert(
                title: Text("Settings Saved"),
                message: Text("Your notification preferences have been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Privacy Settings View
struct PrivacySettingsView: View {
    @State private var locationServices = false
    @State private var analyticsEnabled = true
    @State private var showSaved = false
    
    var body: some View {
        Form {
            Section(header: Text("Data Collection")) {
                Toggle("Analytics", isOn: $analyticsEnabled)
                Toggle("Location Services", isOn: $locationServices)
            }
            
            Section(header: Text("Data Management")) {
                Button(action: {
                    showSaved = true
                }) {
                    Text("Export My Data")
                }
                
                Button(action: {
                    showSaved = true
                }) {
                    Text("Delete My Account")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Privacy")
        .alert(isPresented: $showSaved) {
            Alert(
                title: Text("Feature Not Implemented"),
                message: Text("This feature is not active in the current version."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Contact Support View
struct ContactSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    @State private var showSent = false
    
    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(AuthManager.shared.currentUser?.email ?? "user@example.com")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Message")) {
                TextField("Subject", text: $subject)
                
                ZStack(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Describe your issue or question...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                        .opacity(message.isEmpty ? 0.25 : 1)
                }
            }
            
            Section {
                Button(action: {
                    showSent = true
                }) {
                    Text("Send Message")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
                .disabled(subject.isEmpty || message.isEmpty)
            }
        }
        .navigationTitle("Contact Support")
        .alert(isPresented: $showSent) {
            Alert(
                title: Text("Message Sent"),
                message: Text("We've received your message and will respond soon."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Report Bug View
struct ReportBugView: View {
    @State private var bugDescription = ""
    @State private var showSent = false
    
    var body: some View {
        Form {
            Section(header: Text("Bug Details")) {
                ZStack(alignment: .topLeading) {
                    if bugDescription.isEmpty {
                        Text("Describe the bug in detail...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $bugDescription)
                        .frame(minHeight: 150)
                        .opacity(bugDescription.isEmpty ? 0.25 : 1)
                }
            }
            
            Section {
                Button(action: {
                    showSent = true
                }) {
                    Text("Submit Report")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
                .disabled(bugDescription.isEmpty)
            }
        }
        .navigationTitle("Report a Bug")
        .alert(isPresented: $showSent) {
            Alert(
                title: Text("Report Submitted"),
                message: Text("Thank you for helping us improve the app!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// User Guide View
struct UserGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Getting Started")) {
                    GuideItemView(
                        title: "Recording Symptoms",
                        description: "Tap the Symptoms tab to record and track your physical symptoms. Rate severity on a scale of 1-10.",
                        icon: "waveform.path.ecg"
                    )
                    
                    GuideItemView(
                        title: "Your Recovery Plan",
                        description: "Go to the Recovery tab to view your exercise schedule. Filter exercises by body part using the buttons at the top.",
                        icon: "figure.walk"
                    )
                    
                    GuideItemView(
                        title: "Generating Exercises",
                        description: "Tap 'Generate' in the Recovery tab to create a personalized exercise plan based on your symptoms.",
                        icon: "wand.and.stars"
                    )
                }
                
                Section(header: Text("Using the App")) {
                    GuideItemView(
                        title: "Marking Exercises Complete",
                        description: "Tap the circle next to an exercise to mark it as complete. Your progress is saved automatically.",
                        icon: "checkmark.circle"
                    )
                    
                    GuideItemView(
                        title: "Calendar Views",
                        description: "Switch between Weekly, Calendar, and List views to see your exercises organized differently.",
                        icon: "calendar"
                    )
                    
                    GuideItemView(
                        title: "Exercise Details",
                        description: "Tap on any exercise to view detailed instructions and track your progress.",
                        icon: "list.bullet.rectangle"
                    )
                    
                    GuideItemView(
                        title: "Using the PT Assistant",
                        description: "Tap the chat bubble icon to get personalized advice and answers about your recovery.",
                        icon: "message.fill"
                    )
                }
                
                Section(header: Text("Tips for Success")) {
                    GuideItemView(
                        title: "Consistency is Key",
                        description: "Try to complete exercises daily. Regular practice leads to better outcomes.",
                        icon: "clock.arrow.circlepath"
                    )
                    
                    GuideItemView(
                        title: "Track Your Progress",
                        description: "Regularly update symptom severity to track improvement over time.",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    GuideItemView(
                        title: "Listen to Your Body",
                        description: "If an exercise causes pain (not just discomfort), stop and consult your healthcare provider.",
                        icon: "ear"
                    )
                }
            }
            .navigationTitle("User Guide")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Guide Item Component
struct GuideItemView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 40)
        }
        .padding(.vertical, 8)
    }
}

// About App View
struct AboutAppView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Road to Rehab")
                        .font(.title)
                        .bold()
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.gray)
                    
                    Text("Your personal physical therapy assistant")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            
            Section(header: Text("Development")) {
                HStack {
                    Text("Developed by")
                    Spacer()
                    Text("Road to Rehab Team")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Copyright")
                    Spacer()
                    Text("© 2025 Road to Rehab")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Legal")) {
                Button(action: {}) {
                    Text("Terms of Service")
                }
                
                Button(action: {}) {
                    Text("Privacy Policy")
                }
                
                Button(action: {}) {
                    Text("Licenses")
                }
            }
        }
        .navigationTitle("About")
    }
} 