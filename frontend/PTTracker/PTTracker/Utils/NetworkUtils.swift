import Foundation

class NetworkUtils {
    static func configureForLocalDevelopment() {
        // Allow insecure local connections for development
        if #available(iOS 9.0, *) {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 30.0
            URLSession.shared.configuration.timeoutIntervalForRequest = 30.0
            
            // For local development only (never use in production)
            if let appTransportSecurityDict = Bundle.main.object(forInfoDictionaryKey: "NSAppTransportSecurity") as? [String: Any],
               let allowArbitraryLoads = appTransportSecurityDict["NSAllowsArbitraryLoads"] as? Bool,
               !allowArbitraryLoads {
                print("Warning: NSAllowsArbitraryLoads should be set to YES for local development")
            }
        }
    }
}

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
} 