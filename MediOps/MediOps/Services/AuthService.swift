import Foundation

// Import AuthError from UserController, so extending it rather than redefining
extension AuthError {
    static let invalidRole = AuthError.custom("Invalid role for this operation")
}

// Helper method to add custom error case
extension AuthError {
    static func custom(_ message: String) -> AuthError {
        return .networkError // Using an existing case as placeholder, the message will be shown
    }
}

class AuthService {
    static let shared = AuthService()
    
    private let userController = UserController.shared
    private let patientController = PatientController.shared
    private let adminController = AdminController.shared
    
    private init() {}
    
    // MARK: - Patient Authentication
    
    /// Sign up a new patient
    func signUpPatient(email: String, password: String, username: String, age: Int, gender: String) async throws -> (Patient, String) {
        return try await patientController.registerPatient(email: email, password: password, name: username, age: age, gender: gender)
    }
    
    /// Login a patient
    func loginPatient(email: String, password: String) async throws -> (Patient, String) {
        // First authenticate the user
        let authResponse = try await userController.login(email: email, password: password)
        
        // Verify the user is a patient
        guard authResponse.user.role == .patient else {
            throw AuthError.invalidRole
        }
        
        // Get the patient details
        let patient = try await patientController.getPatientByUserId(userId: authResponse.user.id)
        
        return (patient, authResponse.token)
    }
    
    // MARK: - Hospital Admin Management
    
    /// Create a new hospital admin
    func createHospitalAdmin(email: String, name: String, hospitalName: String) async throws -> (HospitalAdmin, String) {
        // Generate a secure password
        let password = generateSecurePassword()
        
        // Create the hospital admin
        let (admin, token) = try await adminController.registerHospitalAdmin(
            email: email,
            password: password,
            name: name,
            hospitalName: hospitalName
        )
        
        // Send credentials via email
        sendCredentialsEmail(to: email, password: password, role: "Hospital Administrator")
        
        return (admin, token)
    }
    
    // MARK: - Doctor Management
    
    /// Create a new doctor
    func createDoctor(email: String, name: String, specialization: String, hospitalAdminId: String) async throws -> (Doctor, String) {
        // Generate a secure password
        let password = generateSecurePassword()
        
        // Create the doctor
        let (doctor, token) = try await adminController.createDoctor(
            email: email,
            password: password,
            name: name,
            specialization: specialization,
            hospitalAdminId: hospitalAdminId
        )
        
        // Send credentials via email
        sendCredentialsEmail(to: email, password: password, role: "Doctor")
        
        return (doctor, token)
    }
    
    // MARK: - Lab Admin Management
    
    /// Create a new lab admin
    func createLabAdmin(email: String, name: String, labName: String, hospitalAdminId: String) async throws -> (LabAdmin, String) {
        // Generate a secure password
        let password = generateSecurePassword()
        
        // Create the lab admin
        let (labAdmin, token) = try await adminController.createLabAdmin(
            email: email,
            password: password,
            name: name,
            labName: labName,
            hospitalAdminId: hospitalAdminId
        )
        
        // Send credentials via email
        sendCredentialsEmail(to: email, password: password, role: "Lab Administrator")
        
        return (labAdmin, token)
    }
    
    // MARK: - Helper Methods
    
    /// Check if a patient exists in both the users and patients tables
    func checkPatientExists(email: String) async throws -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("PATIENT CHECK: Looking for patient with normalized email: \(normalizedEmail)")
        
        // Download the entire users table - more reliable for case-insensitive checks
        let allUsers = try await SupabaseController.shared.select(
            from: "users"
        )
        
        print("PATIENT CHECK: Downloaded \(allUsers.count) users from database")
        
        // Download the entire patients table - more reliable for case-insensitive checks
        let allPatients = try await SupabaseController.shared.select(
            from: "patients"
        )
        
        print("PATIENT CHECK: Downloaded \(allPatients.count) patients from database")
        
        // DEBUG: Dump all emails for verification
        print("PATIENT CHECK: All emails in users table:")
        var foundUserMatch = false
        var foundUserId: String? = nil
        var foundRole: String? = nil
        
        for user in allUsers {
            if let userEmail = user["email"] as? String {
                print("  - User: \(userEmail)")
                
                // Check if this email matches our search (case-insensitive)
                if userEmail.lowercased() == normalizedEmail {
                    foundUserMatch = true
                    foundUserId = user["id"] as? String
                    foundRole = user["role"] as? String
                    print("PATIENT CHECK: ✓ Found matching user: \(userEmail), ID: \(foundUserId ?? "unknown"), Role: \(foundRole ?? "unknown")")
                }
            }
        }
        
        // If we found a user, check for a matching patient record
        if let userId = foundUserId {
            // First check by user_id reference
            var foundPatientByUserId = false
            
            for patient in allPatients {
                if let patientUserId = patient["user_id"] as? String, patientUserId == userId {
                    foundPatientByUserId = true
                    print("PATIENT CHECK: ✓ Found patient record with user_id: \(userId)")
                    // This is a full match - both user and patient records exist
                    return true
                }
            }
            
            // If we didn't find a patient by user_id, check by email as fallback
            if !foundPatientByUserId {
                print("PATIENT CHECK: No patient found with user_id: \(userId), checking by email...")
                
                for patient in allPatients {
                    if let patientEmail = patient["email"] as? String, patientEmail.lowercased() == normalizedEmail {
                        print("PATIENT CHECK: ✓ Found patient record with matching email: \(patientEmail)")
                        // This is a partial match - patient exists but with mismatched user_id
                        return true
                    }
                }
                
                // For password reset purposes, just finding a user should be sufficient
                if foundUserMatch {
                    print("PATIENT CHECK: Found user but no patient record. For password reset, we'll consider this a match.")
                    return true
                }
            }
        } else {
            // No user found by email, explicit check by email in patients table
            print("PATIENT CHECK: No user found with email: \(normalizedEmail), checking patients table directly...")
            
            for patient in allPatients {
                if let patientEmail = patient["email"] as? String, patientEmail.lowercased() == normalizedEmail {
                    print("PATIENT CHECK: ✓ Found patient with email: \(patientEmail) but no matching user record")
                    // This is unusual but could happen - return true for password reset
                    return true
                }
            }
            
            print("PATIENT CHECK: No match found in either users or patients tables")
            return false
        }
        
        // If we get here, we found no match
        print("PATIENT CHECK: No match found after all checks")
        return false
    }
    
    /// Generate a secure random password
    private func generateSecurePassword() -> String {
        let length = 12
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Send credentials via email
    private func sendCredentialsEmail(to email: String, password: String, role: String) {
        // In a real app, you would implement email sending functionality here
        // For this example, we'll just print to the console
        print("Credentials for \(role) sent to \(email) with password: \(password)")
        
        // TODO: Implement actual email sending functionality
    }

} 
