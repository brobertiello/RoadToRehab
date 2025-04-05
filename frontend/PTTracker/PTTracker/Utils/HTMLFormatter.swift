import SwiftUI
import UIKit
import WebKit

struct HTMLText: UIViewRepresentable {
    let htmlString: String
    var linkColor: UIColor = UIColor.systemBlue
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let header = """
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 15px;
                    line-height: 1.4;
                    margin: 0;
                    padding: 0;
                    color: #000000;
                }
                a {
                    color: \(hexString(from: linkColor));
                    text-decoration: none;
                }
                pre {
                    background-color: #f0f0f0;
                    padding: 10px;
                    border-radius: 5px;
                    overflow-x: auto;
                }
                code {
                    font-family: Menlo, Monaco, 'Courier New', monospace;
                    font-size: 13px;
                    background-color: #f0f0f0;
                    padding: 2px 4px;
                    border-radius: 3px;
                }
                pre code {
                    background-color: transparent;
                    padding: 0;
                }
                ul, ol {
                    padding-left: 20px;
                }
                p {
                    margin-top: 0;
                    margin-bottom: 8px;
                }
            </style>
        </head>
        """
        
        let html = """
        <!DOCTYPE html>
        <html>
        \(header)
        <body>
        \(htmlString)
        </body>
        </html>
        """
        
        uiView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLText
        
        init(_ parent: HTMLText) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Handle link clicks
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Adjust WebView height to content height
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { height, _ in
                if let height = height as? CGFloat {
                    DispatchQueue.main.async {
                        webView.heightAnchor.constraint(equalToConstant: height).isActive = true
                    }
                }
            }
        }
    }
    
    private func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r) * 255),
            lroundf(Float(g) * 255),
            lroundf(Float(b) * 255)
        )
    }
} 