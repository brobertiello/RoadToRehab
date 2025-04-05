import SwiftUI

struct LandingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLoginView = false
    @State private var showRegisterView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Text("PT Tracker")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("Track your physical therapy journey")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        showLoginView = true
                    } label: {
                        Text("Login")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        showRegisterView = true
                    } label: {
                        Text("Register")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .sheet(isPresented: $showLoginView) {
                LoginView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
                    .environmentObject(authManager)
            }
        }
    }
} 