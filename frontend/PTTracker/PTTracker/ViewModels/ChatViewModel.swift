import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatService: ChatService
    
    init(authManager: AuthManager) {
        self.chatService = ChatService(authManager: authManager)
        
        // Add welcome message
        messages.append(ChatMessage.botMessage("Hello! I'm your PT assistant. How can I help with your recovery journey today?"))
    }
    
    func sendMessage() async {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        DispatchQueue.main.async {
            self.messages.append(ChatMessage.userMessage(userMessage))
            self.inputMessage = ""
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let response = try await chatService.sendMessage(userMessage)
            
            DispatchQueue.main.async {
                self.messages.append(ChatMessage.botMessage(response.response))
                self.isLoading = false
            }
        } catch APIError.requestFailed(let message) {
            DispatchQueue.main.async {
                self.errorMessage = message
                self.isLoading = false
                self.messages.append(ChatMessage.botMessage("Sorry, I encountered an error. Please try again."))
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.messages.append(ChatMessage.botMessage("Sorry, I encountered an error. Please try again."))
            }
        }
    }
    
    func clearChat() {
        messages.removeAll(where: { $0.isUserMessage })
        messages.removeAll(where: { !$0.isUserMessage && $0.message != "Hello! I'm your PT assistant. How can I help with your recovery journey today?" })
    }
} 