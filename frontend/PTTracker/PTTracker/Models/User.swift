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
        // Try ISO8601
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try MongoDB format
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
} 