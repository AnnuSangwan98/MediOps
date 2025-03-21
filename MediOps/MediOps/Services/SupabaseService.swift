import Foundation
import Supabase
import CommonCrypto
import MediOps

private let supabaseURL = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co")!
private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk"

class SupabaseService {
    static let shared = SupabaseService()
    
    private let emailServerUrl = "http://127.0.0.1:8084"
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
            print("Attempting to sign up user with email: \(email)")
            
            // Hash the password
            let hashedPassword = try hashPassword(password)
            
            // Generate UUID for the user
            let userId = UUID().uuidString
            
            print("Generated user ID: \(userId)")
            
            // STEP 1: First create a user record
            try await supabase.database
                .from("users")
                .insert([
                    "id": userId,
                    "email": email,
                    "role": "patient",
                    "username": name,
                    "password_hash": hashedPassword
                ])
                .execute()
                
            print("Created user record with ID: \(userId)")
            
            // STEP 2: Then create the patient record that references the user
            try await supabase.database
                .from("patients")
                .insert([
                    "id": UUID().uuidString, // Generate a different UUID for the patient record
                    "user_id": userId, // Reference the user we just created
                    "name": name,
                    "age": String(age),
                    "gender": gender,
                    "email": email,
                    "password": hashedPassword,
                    "email_verified": "false"
                ])
                .execute()
            
            print("Created patient record for user ID: \(userId)")
            
            // Create the patient object to return
            let now = Date()
            let patient = MediOpsPatient(
                id: userId,
                userId: userId,
                name: name,
                age: age,
                gender: gender,
                createdAt: now,
                updatedAt: now
            )
            
            // Send OTP email
            try await sendOTP(to: email, otp: otp)
            
            // Store user ID in UserDefaults for session management
            UserDefaults.standard.set(userId, forKey: "supabase_access_token")
            
            return (patient, otp)
            
        } catch {
            print("SignUp Error: \(error)")
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
    
    func sendOTP(to email: String, otp: String = "") async throws {
        print("Sending OTP to \(email)")
        
        // If no OTP was provided, let EmailService generate one
        if otp.isEmpty {
            let _ = try await EmailService.shared.sendOTP(to: email, role: "Patient")
            print("OTP sent successfully to \(email)")
        } else {
            // Use the provided OTP
            let body: [String: Any] = [
                "email": email,
                "otp": otp,
                "subject": "Your MediOps Patient Verification Code"
            ]
            
            // Use EmailService for consistent handling
            guard let url = URL(string: "\(EmailService.shared.baseServerUrl)/send-otp") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            print("OTP sent successfully to \(email)")
        }
    }
    
    func verifyOTP(email: String, otp: String) async throws -> Bool {
        // In a real application, we'd verify the OTP with a database record
        // Since we're sending actual OTPs by email, we need to verify them properly
        
        // For now, this will come directly from the emailService's generated OTP
        // that's passed from the login view to the OTP verification view
        // A more complete implementation would check against a stored OTP in the database
        
        // Mark email as verified if OTP is correct
        if let userId = getAccessToken(), let userUUID = UUID(uuidString: userId) {
            try await updateEmailVerificationStatus(userId: userUUID)
        }
        
        return true
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
        do {
            // Use lowercase email for case-insensitive matching
            let lowerEmail = email.lowercased()
            
            // First, query the patients table
            let patientQuery = supabase.database
                .from("patients")
                .select("*")
                .eq("email", value: lowerEmail)
            
            let patientResponse = try await patientQuery.execute()
            
            // Check if we found any patients
            guard let patientsList = patientResponse.data as? [[String: Any]], 
                  !patientsList.isEmpty else {
                throw NSError(domain: "AuthError",
                              code: 401,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"])
            }
            
            // Get the first patient record
            let patientData = patientsList[0]
            
            // Extract patient ID and user ID
            guard let patientId = patientData["id"] as? String else {
                throw NSError(domain: "AuthError",
                             code: 401,
                             userInfo: [NSLocalizedDescriptionKey: "Patient ID not found"])
            }
            
            // Extract name with fallback
            let name = patientData["name"] as? String ?? "Patient"
            
            // Verify password
            let storedPassword = patientData["password"] as? String
            if let storedPassword = storedPassword, !password.isEmpty {
                // Verify with hashed password
                let hashedPassword = try hashPassword(password)
                if password != storedPassword && hashedPassword != storedPassword {
                    throw NSError(domain: "AuthError",
                                 code: 401,
                                 userInfo: [NSLocalizedDescriptionKey: "Invalid password"])
                }
            } else {
                throw NSError(domain: "AuthError",
                             code: 401,
                             userInfo: [NSLocalizedDescriptionKey: "Password not found for this account"])
            }
            
            // Check if there's a user_id reference
            let userId = patientData["user_id"] as? String ?? patientId
            
            // Store the patient ID for future requests
            UserDefaults.standard.set(userId, forKey: "supabase_access_token")
            
            // Create a User object with the data we have
            let userUUID = UUID(uuidString: userId) ?? UUID()
            return User(
                id: userUUID,
                email: email,
                role: .patient,
                username: name,
                createdAt: Date(),
                updatedAt: Date()
            )
        } catch let error as NSError {
            if error.domain == "NSURLErrorDomain" {
                throw NSError(domain: "AuthError",
                             code: 401,
                             userInfo: [NSLocalizedDescriptionKey: "Network error: Unable to connect to the server. Please check your internet connection."])
            }
            
            // Properly propagate authentication errors
            if error.domain == "AuthError" {
                throw error
            }
            
            // For any other errors, provide a generic message
            throw NSError(domain: "AuthError",
                         code: 401,
                         userInfo: [NSLocalizedDescriptionKey: "Authentication failed: \(error.localizedDescription)"])
        }
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

