import Foundation

class RecoveryPlanService {
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/gemini"
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func generateRecoveryPlan() async throws -> RecoveryPlan {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/recovery-plan") else {
            throw APIError.invalidURL
        }
        
        // Get user's symptoms to include in the request
        let symptomService = SymptomService(authManager: authManager)
        let userSymptoms = try await symptomService.getSymptoms()
        
        if userSymptoms.isEmpty {
            throw APIError.requestFailed(message: "No symptoms found. Please add symptoms before generating a recovery plan.")
        }
        
        // Create a simplified symptoms list for the API request
        let simplifiedSymptoms = userSymptoms.map { symptom in
            return [
                "bodyPart": symptom.bodyPart,
                "severity": symptom.currentSeverity
            ]
        }
        
        let body: [String: Any] = [
            "symptoms": simplifiedSymptoms
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Requesting recovery plan from: \(url.absoluteString)")
        print("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "none")")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed(message: "Invalid HTTP response")
            }
            
            print("Recovery plan response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode != 200 {
                // Print response for debugging
                print("Error response: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
                
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to generate recovery plan: HTTP \(httpResponse.statusCode)")
            }
            
            // For debugging
            print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
            
            // Try to decode the response
            let decoder = JSONDecoder()
            do {
                let apiResponse = try decoder.decode(ExerciseResponse.self, from: data)
                
                // Convert the API response to our RecoveryPlan format
                return createRecoveryPlanFromExercises(apiResponse.exercises)
            } catch {
                print("Failed to decode recovery plan: \(error)")
                
                // Create a fallback recovery plan if decoding fails
                return createFallbackRecoveryPlan(for: userSymptoms[0].bodyPart)
            }
        } catch {
            print("Network error: \(error)")
            throw error
        }
    }
    
    func saveRecoveryPlan(_ plan: RecoveryPlan) async throws -> Bool {
        // Count completed exercises for debugging
        var completedCount = 0
        for week in plan.plan.weeks {
            for exercise in week.exercises {
                if exercise.isCompleted {
                    completedCount += 1
                }
            }
        }
        print("Saving recovery plan with \(completedCount) completed exercises")
        
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/save-recovery-plan") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "plan": [
                "title": plan.plan.title,
                "description": plan.plan.description,
                "weeks": plan.plan.weeks.map { week in
                    return [
                        "weekNumber": week.weekNumber,
                        "focus": week.focus,
                        "exercises": week.exercises.map { exercise in
                            return [
                                "exerciseType": exercise.name,
                                "description": exercise.description,
                                "duration": exercise.frequency,
                                "difficulty": 3, // Default difficulty
                                "precautions": "Consult with a physical therapist if pain increases",
                                "bodyPart": exercise.bodyPart,
                                "isCompleted": exercise.isCompleted // Add completion status
                            ]
                        }
                    ]
                }
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Saving recovery plan to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Save recovery plan response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to save recovery plan")
        }
        
        return true
    }
    
    func getSavedRecoveryPlan() async throws -> RecoveryPlan? {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/recovery-plan") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching saved recovery plan from: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Get recovery plan response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 404 {
            return nil // No plan found, not an error
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to get recovery plan")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            
            // Try a more flexible date decoding strategy to handle MongoDB date formats
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let savedPlanResponse = try decoder.decode(SavedPlanResponse.self, from: data)
            
            // Count completed exercises for debugging
            var completedCount = 0
            for week in savedPlanResponse.plan.weeks {
                for exercise in week.exercises {
                    if exercise.isCompleted {
                        completedCount += 1
                    }
                }
            }
            print("Loaded recovery plan with \(completedCount) completed exercises")
            
            return convertSavedPlanToRecoveryPlan(savedPlanResponse.plan)
        } catch {
            print("Failed to decode saved recovery plan: \(error)")
            
            // Try an alternative decoding approach if the first one fails
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let savedPlanResponse = try decoder.decode(SavedPlanResponse.self, from: data)
                return convertSavedPlanToRecoveryPlan(savedPlanResponse.plan)
            } catch {
                print("Second attempt to decode saved recovery plan failed: \(error)")
                throw APIError.decodingFailed
            }
        }
    }
    
    // Helper method to convert API exercise data to our RecoveryPlan format
    private func createRecoveryPlanFromExercises(_ exercises: [APIExercise]) -> RecoveryPlan {
        // Group exercises by bodyPart
        let groupedExercises = Dictionary(grouping: exercises) { $0.exerciseType }
        
        // Create weeks (divide exercises into 4-week program)
        let weeks: [RecoveryWeek] = [
            RecoveryWeek(
                weekNumber: 1,
                focus: "Foundation & Pain Reduction",
                exercises: createExercises(from: exercises.prefix(exercises.count / 4))
            ),
            RecoveryWeek(
                weekNumber: 2,
                focus: "Mobility & Basic Strength",
                exercises: createExercises(from: exercises.dropFirst(exercises.count / 4).prefix(exercises.count / 4))
            ),
            RecoveryWeek(
                weekNumber: 3,
                focus: "Progressive Strengthening",
                exercises: createExercises(from: exercises.dropFirst(exercises.count / 2).prefix(exercises.count / 4))
            ),
            RecoveryWeek(
                weekNumber: 4,
                focus: "Advanced Rehabilitation",
                exercises: createExercises(from: exercises.suffix(exercises.count / 4))
            )
        ]
        
        // Create the recovery plan
        let planDetails = RecoveryPlanDetails(
            title: "Personalized Recovery Program",
            description: "This 4-week program is based on your symptoms and will help you recover progressively. Start with Week 1 exercises and advance as your strength and comfort improve.",
            weeks: weeks
        )
        
        return RecoveryPlan(plan: planDetails)
    }
    
    private func createExercises(from apiExercises: some Collection<APIExercise>) -> [RecoveryExercise] {
        return apiExercises.map { exercise in
            let bodyPart = exercise.bodyPart ?? "General"
            let name = exercise.exerciseType
            
            print("Creating new exercise: \(name), bodyPart: \(bodyPart), explicitly setting isCompleted=false")
            
            return RecoveryExercise(
                bodyPart: bodyPart,
                name: name,
                description: exercise.description,
                frequency: "\(exercise.duration) (Difficulty: \(exercise.difficulty)/5)",
                isCompleted: false // Explicitly set to false for new exercises
            )
        }
    }
    
    private func convertSavedPlanToRecoveryPlan(_ savedPlan: SavedPlan) -> RecoveryPlan {
        // Count completed exercises before conversion
        var beforeCount = 0
        for week in savedPlan.weeks {
            for exercise in week.exercises {
                if exercise.isCompleted {
                    beforeCount += 1
                    print("Before conversion - Completed exercise: \(exercise.exerciseType), bodyPart: \(exercise.bodyPart ?? "Unknown")")
                }
            }
        }
        
        let weeks = savedPlan.weeks.map { week in
            return RecoveryWeek(
                weekNumber: week.weekNumber,
                focus: week.focus,
                exercises: week.exercises.map { exercise in
                    let isCompleted = exercise.isCompleted
                    let bodyPart = exercise.bodyPart ?? "General"
                    let exerciseName = exercise.exerciseType
                    
                    print("Converting exercise: \(exerciseName), bodyPart: \(bodyPart), isCompleted: \(isCompleted)")
                    
                    return RecoveryExercise(
                        bodyPart: bodyPart,
                        name: exerciseName,
                        description: exercise.description,
                        frequency: exercise.duration,
                        isCompleted: isCompleted
                    )
                }
            )
        }
        
        // Count completed exercises after conversion
        var afterCount = 0
        for week in weeks {
            for exercise in week.exercises {
                if exercise.isCompleted {
                    afterCount += 1
                    print("After conversion - Completed exercise: \(exercise.name), bodyPart: \(exercise.bodyPart), id: \(exercise.id)")
                }
            }
        }
        
        print("Conversion: Before = \(beforeCount) completed, After = \(afterCount) completed")
        
        let planDetails = RecoveryPlanDetails(
            title: savedPlan.title,
            description: savedPlan.description,
            weeks: weeks
        )
        
        return RecoveryPlan(plan: planDetails)
    }
    
    // Helper method to create a fallback recovery plan if API fails
    private func createFallbackRecoveryPlan(for bodyPart: String) -> RecoveryPlan {
        let exercises = [
            RecoveryExercise(
                bodyPart: bodyPart,
                name: "Gentle Stretching",
                description: "Slowly and gently stretch the \(bodyPart) area to improve mobility.",
                frequency: "3 sets of 30 seconds, twice daily (Difficulty: 2/5)",
                isCompleted: false // Explicitly set to false for new exercises
            ),
            RecoveryExercise(
                bodyPart: bodyPart,
                name: "Strengthening Exercise",
                description: "Basic resistance exercises for the \(bodyPart) using bodyweight or light resistance.",
                frequency: "2 sets of 10 repetitions, every other day (Difficulty: 3/5)",
                isCompleted: false // Explicitly set to false for new exercises
            )
        ]
        
        let weeks = [
            RecoveryWeek(
                weekNumber: 1,
                focus: "Pain Management & Mobility",
                exercises: exercises
            ),
            RecoveryWeek(
                weekNumber: 2,
                focus: "Building Strength",
                exercises: exercises
            ),
            RecoveryWeek(
                weekNumber: 3,
                focus: "Functional Recovery",
                exercises: exercises
            ),
            RecoveryWeek(
                weekNumber: 4,
                focus: "Return to Activity",
                exercises: exercises
            )
        ]
        
        let planDetails = RecoveryPlanDetails(
            title: "Emergency Recovery Program",
            description: "This is a basic recovery plan for your \(bodyPart). Please consult with a physical therapist for a more personalized program.",
            weeks: weeks
        )
        
        return RecoveryPlan(plan: planDetails)
    }
}

// MARK: - API Response Model
struct ExerciseResponse: Codable {
    let exercises: [APIExercise]
}

struct APIExercise: Codable {
    let exerciseType: String
    let description: String
    let duration: String
    let difficulty: Int
    let precautions: String
    let bodyPart: String?
    
    enum CodingKeys: String, CodingKey {
        case exerciseType
        case description
        case duration
        case difficulty
        case precautions
        case bodyPart
        case _id, user, symptom, __v // Additional fields from MongoDB that we don't need
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseType = try container.decode(String.self, forKey: .exerciseType)
        description = try container.decode(String.self, forKey: .description)
        duration = try container.decode(String.self, forKey: .duration)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        precautions = try container.decode(String.self, forKey: .precautions)
        bodyPart = try container.decodeIfPresent(String.self, forKey: .bodyPart)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(description, forKey: .description)
        try container.encode(duration, forKey: .duration)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(precautions, forKey: .precautions)
        if let bodyPart = bodyPart {
            try container.encode(bodyPart, forKey: .bodyPart)
        }
        // We don't encode _id, user, symptom, and __v fields as they're only for decoding
    }
}

// MARK: - Saved Plan Response Model
struct SavedPlanResponse: Codable {
    let plan: SavedPlan
}

struct SavedPlan: Codable {
    let id: String
    let user: String
    let title: String
    let description: String
    let createdAt: Date
    let weeks: [SavedWeek]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case title
        case description
        case createdAt
        case weeks
        case __v // MongoDB version field (not needed)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(String.self, forKey: .user)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        weeks = try container.decode([SavedWeek].self, forKey: .weeks)
        
        // Try multiple approaches to decode the date
        do {
            // First try decoding directly as a Date (if decoder has a dateDecodingStrategy set)
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        } catch {
            // If that fails, try to decode as a string and convert
            let dateString = try container.decode(String.self, forKey: .createdAt)
            
            // Try ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                createdAt = date
                return
            }
            
            // Try MongoDB format
            let mongoFormatter = DateFormatter()
            mongoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            mongoFormatter.locale = Locale(identifier: "en_US_POSIX")
            mongoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = mongoFormatter.date(from: dateString) {
                createdAt = date
                return
            }
            
            // Try another common format
            let alternativeFormatter = DateFormatter()
            alternativeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            alternativeFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = alternativeFormatter.date(from: dateString) {
                createdAt = date
                return
            }
            
            // If all else fails, use current date
            print("Failed to parse date: \(dateString), using current date instead")
            createdAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(weeks, forKey: .weeks)
        
        // Format the date as ISO8601 for encoding
        let iso8601DateFormatter = ISO8601DateFormatter()
        let dateString = iso8601DateFormatter.string(from: createdAt)
        try container.encode(dateString, forKey: .createdAt)
    }
}

struct SavedWeek: Codable {
    let weekNumber: Int
    let focus: String
    let exercises: [SavedExercise]
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case weekNumber
        case focus
        case exercises
        case id = "_id"
    }
}

struct SavedExercise: Codable {
    let exerciseType: String
    let description: String
    let duration: String
    let difficulty: Int
    let precautions: String
    let bodyPart: String?
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case exerciseType
        case description
        case duration
        case difficulty
        case precautions
        case bodyPart
        case isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exerciseType = try container.decode(String.self, forKey: .exerciseType)
        description = try container.decode(String.self, forKey: .description)
        duration = try container.decode(String.self, forKey: .duration)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        precautions = try container.decode(String.self, forKey: .precautions)
        bodyPart = try container.decodeIfPresent(String.self, forKey: .bodyPart)
        
        // Handle the case where isCompleted might not be in older data
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
}

// MARK: - App Model
struct RecoveryPlan: Codable {
    let plan: RecoveryPlanDetails
}

struct RecoveryPlanDetails: Codable {
    let title: String
    let description: String
    var weeks: [RecoveryWeek]
}

struct RecoveryWeek: Codable, Identifiable {
    var id: String { return "week\(weekNumber)" }
    let weekNumber: Int
    let focus: String
    var exercises: [RecoveryExercise]
}

struct RecoveryExercise: Codable, Identifiable {
    var id: String { 
        // Create a more stable ID that isn't affected by case or whitespace
        return "\(bodyPart.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))-\(name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }
    let bodyPart: String
    let name: String
    let description: String
    let frequency: String // e.g., "3 sets of 10 reps, daily"
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case bodyPart
        case name
        case description
        case frequency
        case isCompleted
    }
} 