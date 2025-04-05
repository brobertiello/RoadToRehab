import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let baseURL = "http://localhost:3001/api"
    
    func register(name: String, email: String, password: String) async throws -> Bool {
        print("Attempting to register user: \(email)")
        
        guard let url = URL(string: "\(baseURL)/users/register") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Sending registration request to \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response")
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Registration response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 201 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "Registration failed"
            print("Registration failed: \(errorMessage)")
            throw APIError.requestFailed(message: errorMessage)
        }
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Registration response data: \(responseString)")
        }
        
        do {
            // Try to handle MongoDB's specific response format
            let decoder = JSONDecoder()
            // Don't use snake case conversion since MongoDB uses camelCase already
            
            // First try parsing the full auth response
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.currentUser = authResponse.user
                self.authToken = authResponse.token
                self.isAuthenticated = true
            }
            print("Registration successful for user: \(authResponse.user.name)")
            return true
        } catch {
            print("Failed to decode auth response: \(error)")
            
            // Try to parse the JSON manually as a fallback
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userDict = json["user"] as? [String: Any],
               let token = json["token"] as? String,
               let id = userDict["_id"] as? String,
               let name = userDict["name"] as? String,
               let email = userDict["email"] as? String {
                
                // Create user manually if JSON parsing fails
                let user = User(id: id, 
                                name: name, 
                                email: email, 
                                dateJoined: Date(), 
                                lastLogin: Date())
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.authToken = token
                    self.isAuthenticated = true
                }
                print("Registration successful with manual JSON parsing for user: \(name)")
                return true
            }
            
            throw APIError.decodingFailed
        }
    }
    
    func login(email: String, password: String) async throws -> Bool {
        print("Attempting to login user: \(email)")
        
        guard let url = URL(string: "\(baseURL)/users/login") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Sending login request to \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response")
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Login response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "Login failed"
            print("Login failed: \(errorMessage)")
            throw APIError.requestFailed(message: errorMessage)
        }
        
        // Print response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("Login response data: \(responseString)")
        }
        
        do {
            // Try to handle MongoDB's specific response format
            let decoder = JSONDecoder()
            // Don't use snake case conversion since MongoDB uses camelCase already
            
            // First try parsing the full auth response
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.currentUser = authResponse.user
                self.authToken = authResponse.token
                self.isAuthenticated = true
            }
            print("Login successful for user: \(authResponse.user.name)")
            return true
        } catch {
            print("Failed to decode auth response: \(error)")
            
            // Try to parse the JSON manually as a fallback
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userDict = json["user"] as? [String: Any],
               let token = json["token"] as? String,
               let id = userDict["_id"] as? String,
               let name = userDict["name"] as? String,
               let email = userDict["email"] as? String {
                
                // Create user manually if JSON parsing fails
                let user = User(id: id, 
                                name: name, 
                                email: email, 
                                dateJoined: Date(), 
                                lastLogin: Date())
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.authToken = token
                    self.isAuthenticated = true
                }
                print("Login successful with manual JSON parsing for user: \(name)")
                return true
            }
            
            throw APIError.decodingFailed
        }
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.authToken = nil
            self.isAuthenticated = false
        }
    }
}

enum APIError: Error {
    case invalidURL
    case requestFailed(message: String)
    case decodingFailed
}

struct ErrorResponse: Codable {
    let error: String
}

struct AuthResponse: Codable {
    let user: User
    let token: String
} 