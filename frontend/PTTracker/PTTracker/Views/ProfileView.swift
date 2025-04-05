import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let user = authManager.currentUser {
                    HStack {
                        Spacer()
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Group {
                        ProfileInfoRow(title: "Name", value: user.name)
                        Divider()
                        ProfileInfoRow(title: "Email", value: user.email)
                        Divider()
                        ProfileInfoRow(title: "Member Since", value: formattedDate(user.dateJoined))
                        Divider()
                        ProfileInfoRow(title: "Last Login", value: formattedDate(user.lastLogin))
                    }
                } else {
                    Text("User data not available")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
} 