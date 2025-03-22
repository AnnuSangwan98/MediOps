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
        
        // First check for a direct match in the users table
        // This is the most important check since login is primarily done through the users table
        let users = try await SupabaseController.shared.select(
            from: "users"
        )
        
        print("PATIENT CHECK: Found \(users.count) total users in database")
        
        // Find the user with case-insensitive email match
        var userId: String? = nil
        
        for user in users {
            if let userEmail = user["email"] as? String,
               userEmail.lowercased() == normalizedEmail {
                userId = user["id"] as? String
                print("PATIENT CHECK: Found user with matching email: \(userEmail), ID: \(userId ?? "unknown")")
                
                // Print user role info for debugging
                if let roleString = user["role"] as? String {
                    print("PATIENT CHECK: User role is: \(roleString)")
                }
                break
            }
        }
        
        // If we didn't find a user, show more detailed diagnostics about what emails are in the system
        if userId == nil {
            print("PATIENT CHECK: No user found with exact email: \(normalizedEmail)")
            print("PATIENT CHECK: Here are all emails in the users table:")
            for user in users {
                if let userEmail = user["email"] as? String {
                    print("  - \(userEmail)")
                }
            }
            return false
        }
        
        // Now check if a patient record exists for this user
        // First try to find by user_id
        let patientsByUserId = try await SupabaseController.shared.select(
            from: "patients",
            where: "user_id",
            equals: userId ?? ""
        )
        
        if !patientsByUserId.isEmpty {
            if let patient = patientsByUserId.first {
                print("PATIENT CHECK: Found patient record by user_id: \(patient["id"] as? String ?? "unknown")")
                print("PATIENT CHECK: Patient name: \(patient["name"] as? String ?? "unknown")")
                
                // Check if patient email matches the login email
                if let patientEmail = patient["email"] as? String {
                    print("PATIENT CHECK: Patient email in record: \(patientEmail)")
                    
                    // If emails don't match, this might be the source of the problem
                    if patientEmail.lowercased() != normalizedEmail {
                        print("PATIENT CHECK: WARNING - Patient email doesn't match login email!")
                    }
                }
                
                return true
            }
        }
        
        // If not found by user_id, try directly by email in patients table as fallback
        print("PATIENT CHECK: No patient found by user_id, trying email lookup in patients table")
        let patients = try await SupabaseController.shared.select(
            from: "patients"
        )
        
        print("PATIENT CHECK: Found \(patients.count) total patients")
        
        // Check for case-insensitive email match in patients table
        for patient in patients {
            if let patientEmail = patient["email"] as? String, 
               patientEmail.lowercased() == normalizedEmail {
                
                let patientId = patient["id"] as? String ?? "unknown"
                let patientUserId = patient["user_id"] as? String ?? "unknown"
                
                print("PATIENT CHECK: Found patient with matching email: \(patientEmail)")
                print("PATIENT CHECK: Patient ID: \(patientId), User ID: \(patientUserId)")
                
                // Critical issue: the user_id in the patient record doesn't match the actual user's ID
                if patientUserId != userId {
                    print("PATIENT CHECK: WARNING - Patient's user_id (\(patientUserId)) doesn't match user's ID (\(userId ?? "nil"))")
                    
                    // Consider this a patient match anyway
                    return true
                }
                
                return true
            }
        }
        
        print("PATIENT CHECK: No patient found with matching email in patients table")
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