import Foundation

class ChatService {
    private let baseURL = "http://localhost:3001/api/gemini"
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func sendMessage(_ message: String) async throws -> ChatResponse {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "message": message
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Sending chat message to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Chat response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to get chat response")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ChatResponse.self, from: data)
        } catch {
            print("Failed to decode chat response: \(error)")
            throw APIError.decodingFailed
        }
    }
}

struct ChatResponse: Codable {
    let response: String
    
    // Computed property to maintain compatibility with our view model
    var message: String {
        return response
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
    let isUserMessage: Bool
    let timestamp: Date
    
    static func userMessage(_ text: String) -> ChatMessage {
        return ChatMessage(message: text, isUserMessage: true, timestamp: Date())
    }
    
    static func botMessage(_ text: String) -> ChatMessage {
        return ChatMessage(message: text, isUserMessage: false, timestamp: Date())
    }
} 