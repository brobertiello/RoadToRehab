import Foundation
import SwiftUI

class DatabaseConfigService: ObservableObject {
    // Shared singleton instance
    static let shared = DatabaseConfigService()
    
    @Published var connectionStatus: ConnectionStatus?
    @Published var godaddyDomains: [GoDaddyDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/db-config"
    private let authManager = AuthManager.shared
    
    // Get MongoDB connection status
    func getConnectionStatus() async throws -> ConnectionStatus {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/status") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "Failed to get connection status"
            throw APIError.requestFailed(message: errorMessage)
        }
        
        let connectionStatus = try JSONDecoder().decode(ConnectionStatus.self, from: data)
        
        DispatchQueue.main.async {
            self.connectionStatus = connectionStatus
        }
        
        return connectionStatus
    }
    
    // Get all GoDaddy domains
    func getGoDaddyDomains() async throws -> [GoDaddyDomain] {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/godaddy/domains") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "Failed to get GoDaddy domains"
            throw APIError.requestFailed(message: errorMessage)
        }
        
        let domains = try JSONDecoder().decode([GoDaddyDomain].self, from: data)
        
        DispatchQueue.main.async {
            self.godaddyDomains = domains
        }
        
        return domains
    }
    
    // Setup MongoDB Atlas with GoDaddy DNS
    func setupGoDaddyDns(domain: String, subdomain: String, mongoIp: String) async throws -> SetupResult {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/godaddy/setup") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "domain": domain,
            "subdomain": subdomain,
            "mongoIp": mongoIp
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "Failed to setup GoDaddy DNS"
            throw APIError.requestFailed(message: errorMessage)
        }
        
        return try JSONDecoder().decode(SetupResult.self, from: data)
    }
}

// MARK: - Model Structures

struct ConnectionStatus: Codable {
    let isConnected: Bool
    let connectionString: String
}

struct GoDaddyDomain: Codable, Identifiable {
    let domain: String
    let status: String
    let expirationDate: String?
    
    var id: String {
        return domain
    }
}

struct DnsRecord: Codable {
    let name: String
    let type: String
    let data: String
    let ttl: Int
}

struct SetupResult: Codable {
    let success: Bool
    let message: String
    let details: Details?
    
    struct Details: Codable {
        let success: Bool
        let message: String
    }
} 