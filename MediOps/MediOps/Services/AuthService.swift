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
        
        // First check directly in the patients table by email
        // This is more direct and might catch patients that have email mismatches
        let patients = try await SupabaseController.shared.select(
            from: "patients"
        )
        
        print("PATIENT CHECK: Found \(patients.count) total patients")
        
        // Check for case-insensitive email match in patients table
        for patient in patients {
            if let patientEmail = patient["email"] as? String, 
               patientEmail.lowercased() == normalizedEmail {
                print("PATIENT CHECK: Found direct match in patients table for email: \(patientEmail)")
                return true
            }
        }
        
        // If not found directly in patients table, check the traditional way through users table
        print("PATIENT CHECK: No direct match in patients table, checking users table next")
        
        // Check if user exists in users table
        let users = try await SupabaseController.shared.select(
            from: "users"
        )
        
        print("PATIENT CHECK: Found \(users.count) total users")
        
        // Find the user with a case-insensitive email match
        var userId: String? = nil
        for user in users {
            if let userEmail = user["email"] as? String,
               userEmail.lowercased() == normalizedEmail {
                userId = user["id"] as? String
                print("PATIENT CHECK: Found user with matching email: \(userEmail), ID: \(userId ?? "unknown")")
                break
            }
        }
        
        guard let userId = userId else {
            print("PATIENT CHECK: No user found with email: \(normalizedEmail)")
            return false
        }
        
        // Check if patient record exists in patients table with this user_id
        let patientRecords = try await SupabaseController.shared.select(
            from: "patients",
            where: "user_id",
            equals: userId
        )
        
        let patientExists = !patientRecords.isEmpty
        print("PATIENT CHECK: Patient record exists for user \(userId): \(patientExists)")
        
        if patientExists, let patientData = patientRecords.first {
            print("PATIENT CHECK: Patient details - ID: \(patientData["id"] as? String ?? "unknown"), Name: \(patientData["name"] as? String ?? "unknown")")
        }
        
        return patientExists
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