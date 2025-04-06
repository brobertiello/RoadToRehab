import Foundation

class ChatService {
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/gemini"
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func sendMessage(_ message: String, 
                    userName: String = "User", 
                    symptomsContext: String = "", 
                    exercisesContext: String = "") async throws -> ChatResponse {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            throw APIError.invalidURL
        }
        
        // Create system context
        let contextString = """
        USER PROFILE:
        Name: \(userName)
        
        CURRENT SYMPTOMS:
        \(symptomsContext)
        
        RECOVERY PLAN FOR THE COMING WEEK:
        \(exercisesContext)
        
        Please remember this information and refer to it in your responses as appropriate.
        Respond in plain text only.
        """
        
        // Combine context and message for the backend
        // This ensures the context is processed as part of the message
        let combinedMessage = """
        [SYSTEM INFORMATION]
        You are a professional physical therapy assistant AI for the RoadToRehab application. Your purpose is to provide supportive, educational guidance to users recovering from injuries or managing chronic conditions.

        Guidelines:
        1. Be compassionate, encouraging, and supportive in your responses.
        2. Provide scientifically accurate information about physical therapy, recovery, and exercises.
        3. Explain complex medical concepts in simple, easy-to-understand language.
        4. Do not make specific medical diagnoses - instead, guide users to seek professional medical advice when appropriate.
        5. Acknowledge the user's symptoms and recovery progress in your responses ONLY when directly relevant to their question.
        6. Suggest general motivation and adherence strategies to help users stick with their recovery plan.
        7. Always respond in plain text without formatting.
        8. Keep responses concise and focused on the user's question.
        9. If you don't know an answer, be honest and suggest consulting their physical therapist.
        10. Maintain a professional, friendly tone.
        
        IMPORTANT: The information in [USER INFORMATION] section is provided as background context ONLY. Do NOT repeat or mention this information in your responses unless:
        - The user specifically asks about their symptoms, exercises, or profile
        - Your response directly requires referencing this information to answer the user's question
        - It is contextually appropriate and natural to mention a specific detail
        
        DO NOT start your responses by listing or summarizing the user's information.
        DO NOT acknowledge that you've been provided with this information.
        DO focus on directly answering what the user is asking about.
        
        [USER INFORMATION]
        \(contextString)

        [USER MESSAGE]
        \(message)
        """
        
        // The backend only expects the raw message 
        let body: [String: Any] = [
            "message": combinedMessage
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
            let chatResponse = try decoder.decode(ChatResponse.self, from: data)
            return ChatResponse(response: chatResponse.response)
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
    let isHTML: Bool
    
    static func userMessage(_ text: String) -> ChatMessage {
        return ChatMessage(message: text, isUserMessage: true, timestamp: Date(), isHTML: false)
    }
    
    static func botMessage(_ text: String) -> ChatMessage {
        // Always treat responses as plain text now
        return ChatMessage(message: text, isUserMessage: false, timestamp: Date(), isHTML: false)
    }
} 