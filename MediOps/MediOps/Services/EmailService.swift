import Foundation

class EmailService {
    static let shared = EmailService()
    private let serverUrl = "http://172.20.2.50:8082"  // Update with your email server URL
    
    private init() {}
    
    func sendOTP(to email: String, role: String) async throws -> String {
        let otp = String(Int.random(in: 100000...999999))
        
        guard let url = URL(string: "\(serverUrl)/send-email") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "to": email,
            "role": role.lowercased(),
            "otp": otp
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return otp
    }
} 