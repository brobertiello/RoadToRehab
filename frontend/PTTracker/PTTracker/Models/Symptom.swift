import Foundation

struct Severity: Codable, Identifiable {
    var id: String {
        return date.timeIntervalSince1970.description
    }
    let value: Int
    let date: Date
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case value
        case date
        case notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Int.self, forKey: .value)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Try different date formats that MongoDB might return
        if let dateString = try? container.decode(String.self, forKey: .date) {
            // Try ISO8601 first
            if let isoDate = ISO8601DateFormatter().date(from: dateString) {
                date = isoDate
            } else {
                // Try MongoDB format as fallback
                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                    "yyyy-MM-dd'T'HH:mm:ssZ"
                ]
                
                var parsedDate: Date?
                for format in formats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        parsedDate = date
                        break
                    }
                }
                
                if let parsedDate = parsedDate {
                    date = parsedDate
                } else {
                    print("Failed to parse date string: \(dateString)")
                    date = Date() // Fallback to current date
                }
            }
        } else if let timestamp = try? container.decode(Double.self, forKey: .date) {
            // Handle MongoDB timestamp as milliseconds since epoch
            date = Date(timeIntervalSince1970: timestamp / 1000.0)
        } else {
            print("Unable to decode date in any format")
            date = Date() // Fallback
        }
    }
    
    // Regular initializer for creating severities locally
    init(value: Int, date: Date, notes: String? = nil) {
        self.value = value
        self.date = date
        self.notes = notes
    }
}

struct Symptom: Codable, Identifiable {
    let id: String
    var bodyPart: String
    var notes: String?
    var severities: [Severity]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case bodyPart
        case notes
        case severities
    }
    
    // For creating a new symptom locally
    init(bodyPart: String, severity: Int, notes: String? = nil) {
        self.id = UUID().uuidString  // Temporary ID until saved to DB
        self.bodyPart = bodyPart
        self.notes = notes
        self.severities = [
            Severity(value: severity, date: Date(), notes: notes)
        ]
    }
    
    // Helper to get the latest severity value
    var currentSeverity: Int {
        return self.severities.sorted(by: { $0.date > $1.date }).first?.value ?? 0
    }
    
    // Helper to get a formatted date for the latest severity
    var lastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        if let latestDate = self.severities.sorted(by: { $0.date > $1.date }).first?.date {
            return formatter.string(from: latestDate)
        }
        return "No data"
    }
} 