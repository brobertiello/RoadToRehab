import Foundation

class SymptomViewModel: ObservableObject {
    @Published var symptoms: [Symptom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let authManager: AuthManager
    private let baseURL = "https://roadtorehab-f3497696e3ef.herokuapp.com/api/symptoms"
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func fetchSymptoms() {
        isLoading = true
        errorMessage = nil
        
        guard let token = authManager.authToken else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }
        
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    // Create a decoder with flexible date handling
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    decoder.dateDecodingStrategy = .formatted(formatter)
                    
                    let symptoms = try decoder.decode([Symptom].self, from: data)
                    self?.symptoms = symptoms
                } catch {
                    print("Decoding error: \(error)")
                    self?.errorMessage = "Failed to decode symptoms data"
                }
            }
        }.resume()
    }
    
    func addSymptom(bodyPart: String, severity: Int, notes: String? = nil) {
        guard let token = authManager.authToken else {
            errorMessage = "Not authenticated"
            return
        }
        
        guard let url = URL(string: baseURL) else {
            errorMessage = "Invalid URL"
            return
        }
        
        // Create the request body
        let bodyDict: [String: Any] = [
            "bodyPart": bodyPart,
            "severities": [
                [
                    "value": severity,
                    "date": ISO8601DateFormatter().string(from: Date()),
                    "notes": notes as Any
                ]
            ],
            "notes": notes as Any
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            errorMessage = "Failed to encode request"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized"
                    return
                }
                
                if httpResponse.statusCode == 201 {
                    self?.successMessage = "Symptom added successfully"
                    self?.fetchSymptoms() // Refresh the list
                } else {
                    self?.errorMessage = "Failed to add symptom (Status: \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
    
    func updateSymptom(id: String, newSeverity: Int, notes: String? = nil) {
        guard let token = authManager.authToken else {
            errorMessage = "Not authenticated"
            return
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        // Create the request body with new severity
        let bodyDict: [String: Any] = [
            "severities": [
                [
                    "value": newSeverity,
                    "date": ISO8601DateFormatter().string(from: Date()),
                    "notes": notes as Any
                ]
            ],
            "notes": notes as Any
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            errorMessage = "Failed to encode request"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self?.successMessage = "Symptom updated successfully"
                    self?.fetchSymptoms() // Refresh the list
                } else {
                    self?.errorMessage = "Failed to update symptom (Status: \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
    
    func deleteSymptom(id: String) {
        guard let token = authManager.authToken else {
            errorMessage = "Not authenticated"
            return
        }
        
        guard let url = URL(string: "\(baseURL)/\(id)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.errorMessage = "Unauthorized"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self?.successMessage = "Symptom deleted successfully"
                    self?.fetchSymptoms() // Refresh the list
                } else {
                    self?.errorMessage = "Failed to delete symptom (Status: \(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
} 