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
            let chatResponse = try decoder.decode(ChatResponse.self, from: data)
            
            // Convert markdown to HTML if needed
            let htmlResponse = markdownToHTML(chatResponse.response)
            return ChatResponse(response: htmlResponse)
        } catch {
            print("Failed to decode chat response: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    /// Converts markdown text to HTML
    /// - Parameter markdown: The markdown text to convert
    /// - Returns: HTML representation of the markdown
    private func markdownToHTML(_ markdown: String) -> String {
        var html = markdown
        
        // Simplify the HTML for better AttributedString compatibility
        
        // Handle code blocks
        html = html.replacingOccurrences(
            of: "```([\\s\\S]*?)```",
            with: "<pre>$1</pre>",
            options: .regularExpression
        )
        
        // Handle inline code
        html = html.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
            options: .regularExpression
        )
        
        // Handle headers - use a different approach without line anchors
        // Split the text into lines and process each line
        var processedLines = html.components(separatedBy: "\n")
        
        for i in 0..<processedLines.count {
            let line = processedLines[i]
            if line.hasPrefix("# ") {
                processedLines[i] = "<h1>\(line.dropFirst(2))</h1>"
            } else if line.hasPrefix("## ") {
                processedLines[i] = "<h2>\(line.dropFirst(3))</h2>"
            } else if line.hasPrefix("### ") {
                processedLines[i] = "<h3>\(line.dropFirst(4))</h3>"
            }
        }
        
        html = processedLines.joined(separator: "\n")
        
        // Handle bold text
        html = html.replacingOccurrences(
            of: "\\*\\*([^\\*]+)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression
        )
        
        // Handle italic text
        html = html.replacingOccurrences(
            of: "\\*([^\\*]+)\\*",
            with: "<em>$1</em>",
            options: .regularExpression
        )
        
        // Handle links
        html = html.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression
        )
        
        // Handle unordered lists
        let lines = html.split(separator: "\n")
        var newLines: [String] = []
        var inList = false
        
        for line in lines {
            if line.hasPrefix("- ") {
                if !inList {
                    newLines.append("<ul>")
                    inList = true
                }
                let content = line.dropFirst(2)
                newLines.append("<li>\(content)</li>")
            } else {
                if inList {
                    newLines.append("</ul>")
                    inList = false
                }
                newLines.append(String(line))
            }
        }
        
        if inList {
            newLines.append("</ul>")
        }
        
        html = newLines.joined(separator: "\n")
        
        // Handle line breaks and paragraphs
        html = html.replacingOccurrences(of: "\n\n", with: "</p><p>")
        html = html.replacingOccurrences(of: "\n", with: "<br>")
        
        // Ensure the content is wrapped in paragraphs
        if !html.starts(with: "<") {
            html = "<p>\(html)</p>"
        }
        
        return html
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
        // Check if this looks like HTML content
        let isHTML = text.contains("<") && text.contains(">")
        return ChatMessage(message: text, isUserMessage: false, timestamp: Date(), isHTML: isHTML)
    }
} 