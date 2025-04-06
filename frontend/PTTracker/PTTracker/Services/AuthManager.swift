import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    // Shared singleton instance
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api"
    private let keychainHelper = KeychainHelper.standard
    private let accountKey = "PTTracker" // Generic account name for keychain
    
    init() {
        // Try to restore session from keychain on initialization
        restoreSession()
    }
    
    private func restoreSession() {
        // Try to get token from keychain
        if let token = keychainHelper.getToken(account: accountKey) {
            self.authToken = token
            
            // Try to get user data from keychain
            if let userData = keychainHelper.getUserData(account: accountKey) {
                do {
                    let decoder = JSONDecoder()
                    
                    // Set up date decoding strategy for proper date parsing
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let user = try decoder.decode(User.self, from: userData)
                    self.currentUser = user
                    self.isAuthenticated = true
                    print("Session restored for user: \(user.name)")
                } catch {
                    print("Failed to decode saved user data: \(error)")
                    // Clear invalid data
                    keychainHelper.clearAuthData(account: accountKey)
                }
            }
        }
    }
    
    private func saveSession(user: User, token: String) {
        // Print diagnostic information
        printDateDiagnostics(user: user)
        
        // Save token to keychain
        keychainHelper.saveToken(token, account: accountKey)
        
        // Save user data to keychain
        do {
            let encoder = JSONEncoder()
            
            // Set up date encoding strategy to match our decoding strategy
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            let userData = try encoder.encode(user)
            keychainHelper.saveUser(userData, account: accountKey)
            print("Session saved for user: \(user.name)")
        } catch {
            print("Failed to encode user data: \(error)")
        }
    }
    
    private func printDateDiagnostics(user: User) {
        print("--- USER DATE DIAGNOSTICS ---")
        print("User: \(user.name) - \(user.email)")
        print("Date Joined Raw: \(user.dateJoined)")
        print("Date Joined Timestamp: \(user.dateJoined.timeIntervalSince1970)")
        
        let joinedFormatter = DateFormatter()
        joinedFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("Date Joined Formatted: \(joinedFormatter.string(from: user.dateJoined))")
        
        print("Last Login Raw: \(user.lastLogin)")
        print("Last Login Timestamp: \(user.lastLogin.timeIntervalSince1970)")
        print("Last Login Formatted: \(joinedFormatter.string(from: user.lastLogin))")
        print("------------------------")
    }
    
    private func parseAPIDate(_ dateString: String) -> Date? {
        // Try ISO8601
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try common MongoDB date formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Log the failure
        print("Failed to parse API date string: \(dateString)")
        return nil
    }
    
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
            
            // Set up date decoding strategy for proper date parsing
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            // First try parsing the full auth response
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.currentUser = authResponse.user
                self.authToken = authResponse.token
                self.isAuthenticated = true
            }
            
            // Save session data to keychain
            saveSession(user: authResponse.user, token: authResponse.token)
            
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
                
                // Try to parse dates from the response
                var dateJoined = Date()
                var lastLogin = Date()
                
                // Try to extract dateJoined
                if let dateJoinedValue = userDict["dateJoined"] as? String {
                    if let parsedDate = parseAPIDate(dateJoinedValue) {
                        dateJoined = parsedDate
                    }
                } else if let dateJoinedTimestamp = userDict["dateJoined"] as? TimeInterval {
                    dateJoined = Date(timeIntervalSince1970: dateJoinedTimestamp / 1000.0)
                }
                
                // Try to extract lastLogin
                if let lastLoginValue = userDict["lastLogin"] as? String {
                    if let parsedDate = parseAPIDate(lastLoginValue) {
                        lastLogin = parsedDate
                    }
                } else if let lastLoginTimestamp = userDict["lastLogin"] as? TimeInterval {
                    lastLogin = Date(timeIntervalSince1970: lastLoginTimestamp / 1000.0)
                }
                
                // Create user with extracted or default dates
                let user = User(id: id, 
                                name: name, 
                                email: email, 
                                dateJoined: dateJoined, 
                                lastLogin: lastLogin)
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.authToken = token
                    self.isAuthenticated = true
                }
                
                // Save session data to keychain
                saveSession(user: user, token: token)
                
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
            
            // Set up date decoding strategy for proper date parsing
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            // First try parsing the full auth response
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.currentUser = authResponse.user
                self.authToken = authResponse.token
                self.isAuthenticated = true
            }
            
            // Save session data to keychain
            saveSession(user: authResponse.user, token: authResponse.token)
            
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
                
                // Try to parse dates from the response
                var dateJoined = Date()
                var lastLogin = Date()
                
                // Try to extract dateJoined
                if let dateJoinedValue = userDict["dateJoined"] as? String {
                    if let parsedDate = parseAPIDate(dateJoinedValue) {
                        dateJoined = parsedDate
                    }
                } else if let dateJoinedTimestamp = userDict["dateJoined"] as? TimeInterval {
                    dateJoined = Date(timeIntervalSince1970: dateJoinedTimestamp / 1000.0)
                }
                
                // Try to extract lastLogin
                if let lastLoginValue = userDict["lastLogin"] as? String {
                    if let parsedDate = parseAPIDate(lastLoginValue) {
                        lastLogin = parsedDate
                    }
                } else if let lastLoginTimestamp = userDict["lastLogin"] as? TimeInterval {
                    lastLogin = Date(timeIntervalSince1970: lastLoginTimestamp / 1000.0)
                }
                
                // Create user with extracted or default dates
                let user = User(id: id, 
                                name: name, 
                                email: email, 
                                dateJoined: dateJoined, 
                                lastLogin: lastLogin)
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.authToken = token
                    self.isAuthenticated = true
                }
                
                // Save session data to keychain
                saveSession(user: user, token: token)
                
                print("Login successful with manual JSON parsing for user: \(name)")
                return true
            }
            
            throw APIError.decodingFailed
        }
    }
    
    func logout() {
        // Clear keychain data
        keychainHelper.clearAuthData(account: accountKey)
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.authToken = nil
            self.isAuthenticated = false
            print("User logged out successfully")
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