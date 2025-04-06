import Foundation

class SymptomService {
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/symptoms"
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func getSymptoms() async throws -> [Symptom] {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching symptoms from: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Symptoms response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to fetch symptoms")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            // We no longer need to specify .iso8601 since our model handles date parsing directly
            return try decoder.decode([Symptom].self, from: data)
        } catch {
            print("Failed to decode symptoms: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func createSymptom(bodyPart: String, severity: Int) async throws -> Symptom {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        // Use a format MongoDB will accept
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        let body: [String: Any] = [
            "bodyPart": bodyPart,
            "severities": [
                ["value": severity, "date": currentDate]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Creating symptom at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Create symptom response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 201 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to create symptom")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            // We no longer need to specify .iso8601 since our model handles date parsing directly
            return try decoder.decode(Symptom.self, from: data)
        } catch {
            print("Failed to decode created symptom: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func updateSymptom(id: String, severity: Int) async throws -> Symptom {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }
        
        // Use a format MongoDB will accept
        let currentDate = ISO8601DateFormatter().string(from: Date())
        
        // Adding a new severity to the existing ones
        let body: [String: Any] = [
            "severities": [
                ["value": severity, "date": currentDate]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Updating symptom at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Update symptom response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to update symptom")
        }
        
        // For debugging
        print("Response data: \(String(data: data, encoding: .utf8) ?? "unable to convert to string")")
        
        do {
            let decoder = JSONDecoder()
            // We no longer need to specify .iso8601 since our model handles date parsing directly
            return try decoder.decode(Symptom.self, from: data)
        } catch {
            print("Failed to decode updated symptom: \(error)")
            throw APIError.decodingFailed
        }
    }
    
    func deleteSymptom(id: String) async throws {
        guard let token = authManager.authToken else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("Deleting symptom at: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed(message: "Invalid HTTP response")
        }
        
        print("Delete symptom response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.requestFailed(message: errorResponse?.error ?? "Failed to delete symptom")
        }
    }
}

// Extend the APIError enum to add unauthorized error
extension APIError {
    static var unauthorized: APIError {
        return .requestFailed(message: "You are not authorized to perform this action")
    }
} 