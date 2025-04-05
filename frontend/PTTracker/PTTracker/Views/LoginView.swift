import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegisterView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Login")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        login()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                
                Section {
                    HStack {
                        Text("Don't have an account?")
                        Spacer()
                        Button("Register") {
                            dismiss()
                            showRegisterView = true
                        }
                    }
                }
            }
            .navigationTitle("Login")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func login() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await authManager.login(email: email, password: password)
                if success {
                    DispatchQueue.main.async {
                        isLoading = false
                        dismiss()
                    }
                }
            } catch APIError.requestFailed(let message) {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = message
                }
            } catch APIError.decodingFailed {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Could not process the server response. Please try again."
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "An error occurred: \(error.localizedDescription)"
                }
            }
        }
    }
} 