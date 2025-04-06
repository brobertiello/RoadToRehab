import SwiftUI
import WebKit
// Import the HTMLText struct from the Utils folder
@_implementationOnly import UIKit

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("PT Assistant")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    viewModel.clearChat()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            TypingIndicator()
                                .id("loadingIndicator")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { isLoading in
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loadingIndicator", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.systemGray6).opacity(0.5))
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputMessage)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                    
                    Button {
                        Task {
                            isInputFocused = false
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.white)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUserMessage {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: 2) {
                if message.isHTML && !message.isUserMessage {
                    // Use AttributedString approach instead of WebView
                    FormattedTextView(htmlContent: message.message)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .frame(minWidth: 200, maxWidth: UIScreen.main.bounds.width * 0.8)
                } else {
                    Text(message.message)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.isUserMessage ? Color.blue : Color.white)
                        .foregroundColor(message.isUserMessage ? .white : .primary)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: message.isUserMessage ? UIScreen.main.bounds.width * 0.7 : .infinity, alignment: message.isUserMessage ? .trailing : .leading)
            
            if !message.isUserMessage {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

// A simpler approach using Text with AttributedString
struct FormattedTextView: View {
    let htmlContent: String
    @State private var attributedText: AttributedString = AttributedString("")
    
    var body: some View {
        Text(attributedText)
            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true) // Important for proper text wrapping
            .onAppear {
                attributedText = formatHtmlToAttributedString(htmlContent)
            }
    }
    
    private func formatHtmlToAttributedString(_ html: String) -> AttributedString {
        // First, process the HTML to make it more AttributedString-friendly
        let processedHtml = preprocessHtml(html)
        
        guard let data = processedHtml.data(using: .utf8) else {
            print("Failed to convert HTML to data")
            return AttributedString(html)
        }
        
        do {
            // Convert HTML to NSAttributedString
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            let nsAttributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            var attributedString = AttributedString(nsAttributedString)
            
            // Apply font to the entire string
            attributedString.font = .system(size: 15)
            
            return attributedString
        } catch {
            print("Error converting HTML to AttributedString: \(error)")
            // If HTML conversion fails, just return plain text
            if let plainText = try? NSAttributedString(data: html.data(using: .utf8) ?? Data(), 
                                                        options: [.documentType: NSAttributedString.DocumentType.plain],
                                                        documentAttributes: nil) {
                return AttributedString(plainText)
            }
            
            return AttributedString(html)
        }
    }
    
    private func preprocessHtml(_ html: String) -> String {
        // Add basic styling to ensure consistent rendering
        // The key CSS settings here ensure text wraps properly
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif; 
                    font-size: 15px; 
                    line-height: 1.4;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                pre { 
                    background-color: #f0f0f0; 
                    padding: 8px; 
                    border-radius: 4px; 
                    white-space: pre-wrap;
                    overflow-x: auto;
                    font-family: monospace;
                }
                code { 
                    font-family: monospace; 
                    background-color: #f0f0f0; 
                    padding: 2px 4px; 
                    border-radius: 3px;
                }
                ul, ol { padding-left: 20px; }
                li { margin-bottom: 8px; }
                p { margin-top: 0; margin-bottom: 8px; }
                br { line-height: 1.6; }
            </style>
        </head>
        <body>
        \(html)
        </body>
        </html>
        """
    }
}

struct TypingIndicator: View {
    @State private var animationValue = 0.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 7, height: 7)
                    .offset(y: sin(animationValue + Double(index) * 0.8) * 3)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .frame(width: 70, alignment: .leading)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationValue = 2 * .pi
            }
        }
    }
} 