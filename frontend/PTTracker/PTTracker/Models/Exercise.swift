import Foundation

struct Exercise: Codable, Identifiable {
    let id: String
    var exerciseType: String
    var description: String
    var scheduledDate: Date
    var duration: String?
    var sets: Int?
    var repetitions: Int?
    var completed: Bool
    var symptomId: String
    var difficulty: Int
    var notes: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case exerciseType
        case description
        case scheduledDate
        case duration
        case sets
        case repetitions
        case completed
        case symptomId = "symptom"
        case difficulty
        case notes
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        exerciseType = try container.decode(String.self, forKey: .exerciseType)
        description = try container.decode(String.self, forKey: .description)
        completed = try container.decode(Bool.self, forKey: .completed)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        
        // Handle optional fields
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        // Handle symptom (could be a string ID or a nested object)
        if let symptomObject = try? container.decode([String: String].self, forKey: .symptomId),
           let symptomId = symptomObject["_id"] {
            self.symptomId = symptomId
        } else {
            symptomId = try container.decode(String.self, forKey: .symptomId)
        }
        
        // Try different date formats for scheduled date
        if let dateString = try? container.decode(String.self, forKey: .scheduledDate) {
            // Try ISO8601
            if let isoDate = ISO8601DateFormatter().date(from: dateString) {
                scheduledDate = isoDate
            } else {
                // Try MongoDB formats
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
                    scheduledDate = parsedDate
                } else {
                    print("Failed to parse scheduled date string: \(dateString)")
                    scheduledDate = Date() // Fallback
                }
            }
        } else if let timestamp = try? container.decode(Double.self, forKey: .scheduledDate) {
            // Handle timestamp in milliseconds
            scheduledDate = Date(timeIntervalSince1970: timestamp / 1000.0)
        } else {
            print("Unable to decode scheduled date in any format")
            scheduledDate = Date() // Fallback
        }
        
        // Parse createdAt date using the same approach
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            if let isoDate = ISO8601DateFormatter().date(from: dateString) {
                createdAt = isoDate
            } else {
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
                    createdAt = parsedDate
                } else {
                    print("Failed to parse createdAt date string: \(dateString)")
                    createdAt = Date() // Fallback
                }
            }
        } else if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp / 1000.0)
        } else {
            print("Unable to decode createdAt date in any format")
            createdAt = Date() // Fallback
        }
    }
    
    // Local initializer for creating exercises in the app
    init(exerciseType: String, description: String, scheduledDate: Date, duration: String? = nil, sets: Int? = nil, repetitions: Int? = nil, symptomId: String, difficulty: Int = 1, notes: String? = nil) {
        self.id = UUID().uuidString // Temporary ID until saved
        self.exerciseType = exerciseType
        self.description = description
        self.scheduledDate = scheduledDate
        self.duration = duration
        self.sets = sets
        self.repetitions = repetitions
        self.completed = false
        self.symptomId = symptomId
        self.difficulty = difficulty
        self.notes = notes
        self.createdAt = Date()
    }
    
    // Computed properties
    var formattedScheduledDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDate)
    }
    
    var formattedDuration: String {
        if let sets = sets, let repetitions = repetitions {
            return "\(sets) sets × \(repetitions) reps"
        } else if let duration = duration {
            return duration
        } else {
            return "As prescribed"
        }
    }
    
    var difficultyText: String {
        let stars = String(repeating: "★", count: difficulty)
        let emptyStars = String(repeating: "☆", count: 5 - difficulty)
        return stars + emptyStars
    }
} 