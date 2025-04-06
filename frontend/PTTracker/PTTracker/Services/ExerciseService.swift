import Foundation

class ExerciseService {
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/exercises"
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func getExercises() async throws -> [Exercise] {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching exercises from: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Exercises response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to fetch exercises")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Exercise].self, from: data)
        } catch {
            print("Failed to decode exercises: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func getExercisesBySymptom(symptomId: String) async throws -> [Exercise] {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/symptom/\(symptomId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching exercises for symptom from: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Exercises by symptom response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to fetch exercises for symptom")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Exercise].self, from: data)
        } catch {
            print("Failed to decode exercises by symptom: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func createExercise(exercise: Exercise) async throws -> Exercise {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        // Format date for API
        let dateFormatter = ISO8601DateFormatter()
        
        // Build the request body
        var body: [String: Any] = [
            "exerciseType": exercise.exerciseType,
            "description": exercise.description,
            "scheduledDate": dateFormatter.string(from: exercise.scheduledDate),
            "symptomId": exercise.symptomId,
            "difficulty": exercise.difficulty,
            "completed": exercise.completed
        ]
        
        // Add optional fields if present
        if let duration = exercise.duration {
            body["duration"] = duration
        }
        
        if let sets = exercise.sets {
            body["sets"] = sets
        }
        
        if let repetitions = exercise.repetitions {
            body["repetitions"] = repetitions
        }
        
        if let notes = exercise.notes {
            body["notes"] = notes
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Creating exercise at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Create exercise response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 201 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to create exercise")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Exercise.self, from: data)
        } catch {
            print("Failed to decode created exercise: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func updateExercise(id: String, completed: Bool? = nil, scheduledDate: Date? = nil, notes: String? = nil) async throws -> Exercise {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }
        
        // Build the update data with only fields that need updating
        var body: [String: Any] = [:]
        
        if let completed = completed {
            body["completed"] = completed
        }
        
        if let scheduledDate = scheduledDate {
            let dateFormatter = ISO8601DateFormatter()
            body["scheduledDate"] = dateFormatter.string(from: scheduledDate)
        }
        
        if let notes = notes {
            body["notes"] = notes
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Updating exercise at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Update exercise response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to update exercise")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Exercise.self, from: data)
        } catch {
            print("Failed to decode updated exercise: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func deleteExercise(id: String) async throws {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Deleting exercise at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Delete exercise response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to delete exercise")
        }
    }
    
    func generateExercises(symptomIds: [String], startDate: Date? = nil, durationDays: Int? = nil) async throws -> [Exercise] {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/generate") else {
            throw APIError.invalidURL
        }
        
        // Build request body
        var body: [String: Any] = [
            "symptomIds": symptomIds
        ]
        
        // Add optional parameters if specified
        if let startDate = startDate {
            let dateFormatter = ISO8601DateFormatter()
            body["startDate"] = dateFormatter.string(from: startDate)
        }
        
        if let durationDays = durationDays {
            body["durationDays"] = durationDays
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Generating exercises at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Generate exercises response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 201 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to generate exercises")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Exercise].self, from: data)
        } catch {
            print("Failed to decode generated exercises: \(error)")
            throw APIError.decodingFailed
        }
    }
} 