import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showLoginView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Create Account")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        register()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword)
                }
                
                Section {
                    HStack {
                        Text("Already have an account?")
                        Spacer()
                        Button("Login") {
                            dismiss()
                            showLoginView = true
                        }
                    }
                }
            }
            .navigationTitle("Register")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showLoginView) {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func register() {
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await authManager.register(name: name, email: email, password: password)
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