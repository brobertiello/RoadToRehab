import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let dateJoined: Date
    let lastLogin: Date
    
    // Manual initializer for creating User objects directly
    init(id: String, name: String, email: String, dateJoined: Date, lastLogin: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.dateJoined = dateJoined
        self.lastLogin = lastLogin
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
        case dateJoined
        case lastLogin
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Initialize all properties first
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        
        // Initialize with default values first
        var dateJoinedValue = Date()
        var lastLoginValue = Date()
        
        // Then try different parsing options
        if let dateJoinedString = try? container.decode(String.self, forKey: .dateJoined) {
            if let parsedDate = User.parseDate(dateJoinedString) {
                dateJoinedValue = parsedDate
            }
        } else if let dateTimestamp = try? container.decode(TimeInterval.self, forKey: .dateJoined) {
            dateJoinedValue = Date(timeIntervalSince1970: dateTimestamp / 1000.0)
        }
        
        if let lastLoginString = try? container.decode(String.self, forKey: .lastLogin) {
            if let parsedDate = User.parseDate(lastLoginString) {
                lastLoginValue = parsedDate
            }
        } else if let loginTimestamp = try? container.decode(TimeInterval.self, forKey: .lastLogin) {
            lastLoginValue = Date(timeIntervalSince1970: loginTimestamp / 1000.0)
        }
        
        // Assign the final values
        dateJoined = dateJoinedValue
        lastLogin = lastLoginValue
    }
    
    // Helper function to parse date strings in various formats
    private static func parseDate(_ dateString: String) -> Date? {
        // Try ISO8601 with extended format
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try standard ISO8601
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try MongoDB formats
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
        
        // If all else fails, try to parse a numeric value (for timestamps)
        if let timestampValue = Double(dateString) {
            // MongoDB timestamps are in milliseconds
            return Date(timeIntervalSince1970: timestampValue / 1000.0)
        }
        
        // Log the failure for debugging
        print("Failed to parse date string: \(dateString)")
        return nil
    }
} 