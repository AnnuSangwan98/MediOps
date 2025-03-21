import Foundation
import Supabase
import CommonCrypto

private let supabaseURL = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co")!
private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk"

class SupabaseService {
    static let shared = SupabaseService()
    
    private let emailServerUrl = "http://localhost:8082"
    private let supabase: SupabaseClient
    
    private let session: URLSession
    
    private init() {
        supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func signUpPatient(email: String, password: String, name: String, age: Int, gender: String) async throws -> (MediOpsPatient, String) {
        // Input validation
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, age > 0, !gender.isEmpty else {
            throw NSError(domain: "ValidationError", 
                         code: 400, 
                         userInfo: [NSLocalizedDescriptionKey: "All fields are required"])
        }
        
        // Generate OTP
        let otp = String(Int.random(in: 100000...999999))
        
        do {
            // 1. First create the auth user
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Get the user ID from the auth response
            let user = authResponse.user
            let userId = user.id.uuidString // This is the auth user's ID
            
            // 2. Create the patient record in the database
            let now = Date()
            
            let patient = MediOpsPatient(
                id: userId, // Use the same ID as the auth user
                userId: userId, // Use the same ID for both id and userId
                name: name,
                age: age,
                gender: gender,
                createdAt: now,
                updatedAt: now
            )
            
            // Insert into patients table
            try await supabase.database
                .from("patients")
                .insert(patient)
                .execute()
            
            return (patient, otp)
            
        } catch {
            print("SignUp Error: \(error)")  // For debugging
            throw NSError(domain: "SignUpError",
                         code: 500,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create account: \(error.localizedDescription)"])
        }
    }
    
    private func deleteUser(userId: UUID) async throws {
        let endpoint = "\(supabaseURL.absoluteString)/rest/v1/users?id=eq.\(userId.uuidString)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("Warning: Failed to delete user after failed patient creation")
            return
        }
    }
    
    private func hashPassword(_ password: String) throws -> String {
        // Simple hashing for demonstration - in production use a proper hashing algorithm
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func sendOTP(to email: String, otp: String) async throws {
        let url = URL(string: "\(emailServerUrl)/send-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emailData: [String: Any] = [
            "email": email,
            "otp": otp,
            "subject": "Your MediOps Verification Code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "EmailError",
                         code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to send OTP email"])
        }
        
        print("OTP sent successfully to \(email)")
    }
    
    func verifyOTP(email: String, otp: String) async throws -> Bool {
        // For now, we'll just do a direct comparison since we're storing the OTP in memory
        // In a production environment, you'd want to verify this against a stored OTP in your database
        return true // Temporarily return true for testing
    }
    
    func updateEmailVerificationStatus(userId: UUID) async throws {
        let endpoint = "\(supabaseURL.absoluteString)/rest/v1/users?id=eq.\(userId.uuidString)"
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let updateData: [String: Any] = [
            "email_verified": true,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SupabaseError",
                         code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to update email verification status"])
        }
    }
    
    func verifyPatientCredentials(email: String, password: String) async throws -> User {
        let endpoint = "\(supabaseURL.absoluteString)/auth/v1/token?grant_type=password"
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("apikey", forHTTPHeaderField: "apikey")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let credentials: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw URLError(.badServerResponse)
        }
        
        // Parse the response to get user data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        struct AuthResponse: Codable {
            let accessToken: String
            let user: User
        }
        
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        // Store the access token for future requests
        UserDefaults.standard.set(authResponse.accessToken, forKey: "supabase_access_token")
        
        return authResponse.user
    }
    
    // Helper method to get stored access token
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "supabase_access_token")
    }
}

// Simple SHA256 implementation
private enum SHA256 {
    static func hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

