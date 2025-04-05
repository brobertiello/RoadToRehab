import Foundation

class RecoveryPlanService {
    private let baseURL = "http://localhost:3001/api/gemini"
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
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Recovery plan response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to generate recovery plan")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(ExerciseResponse.self, from: data)
            
            // Convert the API response to our RecoveryPlan format
            return createRecoveryPlanFromExercises(apiResponse.exercises)
        } catch {
            print("Failed to decode recovery plan: \(error)")
            throw APIError.decodingFailed
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
            RecoveryExercise(
                bodyPart: exercise.bodyPart ?? "General",
                name: exercise.exerciseType,
                description: exercise.description,
                frequency: "\(exercise.duration) (Difficulty: \(exercise.difficulty)/5)"
            )
        }
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

// MARK: - App Model
struct RecoveryPlan: Codable {
    let plan: RecoveryPlanDetails
}

struct RecoveryPlanDetails: Codable {
    let title: String
    let description: String
    let weeks: [RecoveryWeek]
}

struct RecoveryWeek: Codable, Identifiable {
    var id: String { return "week\(weekNumber)" }
    let weekNumber: Int
    let focus: String
    let exercises: [RecoveryExercise]
}

struct RecoveryExercise: Codable, Identifiable {
    var id: String { return "\(bodyPart)-\(name)" }
    let bodyPart: String
    let name: String
    let description: String
    let frequency: String // e.g., "3 sets of 10 reps, daily"
} 