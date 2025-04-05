import SwiftUI

struct DatabaseConfigView: View {
    @ObservedObject private var dbConfigService = DatabaseConfigService.shared
    @State private var selectedDomain: GoDaddyDomain?
    @State private var subdomain: String = "mongodb"
    @State private var mongoIp: String = ""
    @State private var isSubmitting: Bool = false
    @State private var setupResult: SetupResult?
    @State private var showSetupResult: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("MongoDB Connection")) {
                    if let status = dbConfigService.connectionStatus {
                        Label(
                            status.isConnected ? "Connected" : "Disconnected",
                            systemImage: status.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(status.isConnected ? .green : .red)
                        
                        Text("Connection String")
                            .font(.headline)
                        Text(status.connectionString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView()
                            .onAppear {
                                Task {
                                    await fetchConnectionStatus()
                                }
                            }
                    }
                }
                
                Section(header: Text("GoDaddy Domains")) {
                    if dbConfigService.godaddyDomains.isEmpty {
                        Text("No domains found")
                            .foregroundColor(.secondary)
                            .onAppear {
                                Task {
                                    await fetchGoDaddyDomains()
                                }
                            }
                    } else {
                        ForEach(dbConfigService.godaddyDomains) { domain in
                            VStack(alignment: .leading) {
                                Text(domain.domain)
                                    .font(.headline)
                                HStack {
                                    Text(domain.status)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let expiration = domain.expirationDate {
                                        Spacer()
                                        Text("Expires: \(formatDate(expiration))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDomain = domain
                            }
                            .background(selectedDomain?.domain == domain.domain ? Color.blue.opacity(0.1) : Color.clear)
                        }
                    }
                }
                
                Section(header: Text("Setup MongoDB with GoDaddy")) {
                    if let selectedDomain = selectedDomain {
                        Text("Selected Domain: \(selectedDomain.domain)")
                            .font(.headline)
                        
                        TextField("Subdomain", text: $subdomain)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        TextField("MongoDB IP Address", text: $mongoIp)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.numbersAndPunctuation)
                        
                        Button(action: {
                            Task {
                                await setupDns()
                            }
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Setup DNS for MongoDB")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSubmitting || mongoIp.isEmpty)
                        .padding(.vertical, 8)
                    } else {
                        Text("Please select a domain")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Database Configuration")
            .refreshable {
                await fetchConnectionStatus()
                await fetchGoDaddyDomains()
            }
            .alert(isPresented: $showSetupResult) {
                if let result = setupResult {
                    return Alert(
                        title: Text(result.success ? "Success" : "Error"),
                        message: Text(result.message),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text("Error"),
                        message: Text("Unknown error occurred"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    private func fetchConnectionStatus() async {
        do {
            _ = try await dbConfigService.getConnectionStatus()
        } catch {
            dbConfigService.errorMessage = "Failed to get connection status: \(error.localizedDescription)"
        }
    }
    
    private func fetchGoDaddyDomains() async {
        do {
            _ = try await dbConfigService.getGoDaddyDomains()
        } catch {
            dbConfigService.errorMessage = "Failed to get GoDaddy domains: \(error.localizedDescription)"
        }
    }
    
    private func setupDns() async {
        guard let domain = selectedDomain?.domain else { return }
        
        isSubmitting = true
        
        do {
            let result = try await dbConfigService.setupGoDaddyDns(
                domain: domain,
                subdomain: subdomain,
                mongoIp: mongoIp
            )
            
            setupResult = result
            showSetupResult = true
        } catch {
            setupResult = SetupResult(
                success: false,
                message: "Failed to setup DNS: \(error.localizedDescription)",
                details: nil
            )
            showSetupResult = true
        }
        
        isSubmitting = false
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

struct DatabaseConfigView_Previews: PreviewProvider {
    static var previews: some View {
        DatabaseConfigView()
    }
} 