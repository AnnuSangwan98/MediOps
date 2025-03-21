import Foundation

class PatientController {
    static let shared = PatientController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    
    private init() {}
    
    // MARK: - Patient Management
    
    /// Register a new patient
    func registerPatient(email: String, password: String, name: String, age: Int, gender: String) async throws -> (Patient, String) {
        // 1. First register the base user
        let authResponse = try await userController.register(
            email: email,
            password: password,
            username: name,
            role: .patient
        )
        
        // 2. Create patient record
        let patientId = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        // Create a dictionary with String values for insertion
        var patientData: [String: String] = [
            "id": patientId,
            "user_id": authResponse.user.id,
            "name": name,
            "age": String(age),
            "gender": gender,
            "email": email.lowercased(),
            "email_verified": "false",
            "created_at": createdAt,
            "updated_at": createdAt,
            "password": password  // Adding plaintext password for testing
        ]
        
        try await supabase.insert(into: "patients", data: patientData)
        
        // 3. Return the patient object and token
        let patient = Patient(
            id: patientId,
            userId: authResponse.user.id,
            name: name,
            age: age,
            gender: gender,
            createdAt: now,
            updatedAt: now,
            email: email,
            emailVerified: false
        )
        
        return (patient, authResponse.token)
    }
    
    /// Get patient by ID
    func getPatient(id: String) async throws -> Patient {
        let patients = try await supabase.select(
            from: "patients", 
            where: "id", 
            equals: id
        )
        
        guard let patientData = patients.first else {
            throw PatientError.patientNotFound
        }
        
        return try parsePatientData(patientData)
    }
    
    /// Get patient by user ID
    func getPatientByUserId(userId: String) async throws -> Patient {
        let patients = try await supabase.select(
            from: "patients", 
            where: "user_id", 
            equals: userId
        )
        
        guard let patientData = patients.first else {
            throw PatientError.patientNotFound
        }
        
        return try parsePatientData(patientData)
    }
    
    /// Update patient profile
    func updatePatient(id: String, name: String? = nil, age: Int? = nil, gender: String? = nil) async throws -> Patient {
        // 1. Get current patient data
        let patient = try await getPatient(id: id)
        
        // 2. Prepare update data - convert everything to strings for the API
        var updateData: [String: String] = [:]
        if let name = name {
            updateData["name"] = name
        }
        if let age = age {
            updateData["age"] = String(age)
        }
        if let gender = gender {
            updateData["gender"] = gender
        }
        
        // Add updated_at timestamp
        let dateFormatter = ISO8601DateFormatter()
        updateData["updated_at"] = dateFormatter.string(from: Date())
        
        // 3. Update patient
        try await supabase.update(
            table: "patients", 
            data: updateData, 
            where: "id", 
            equals: id
        )
        
        // 4. Return updated patient
        return try await getPatient(id: id)
    }
    
    /// Verify patient email
    func verifyPatientEmail(patientId: String) async throws {
        let updateData: [String: String] = [
            "email_verified": "true",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await supabase.update(
            table: "patients", 
            data: updateData, 
            where: "id", 
            equals: patientId
        )
    }
    
    // MARK: - Helper Methods
    
    /// Parse patient data from dictionary
    private func parsePatientData(_ data: [String: Any]) throws -> Patient {
        guard
            let id = data["id"] as? String,
            let userId = data["user_id"] as? String,
            let name = data["name"] as? String,
            let gender = data["gender"] as? String,
            let createdAtString = data["created_at"] as? String,
            let updatedAtString = data["updated_at"] as? String
        else {
            throw PatientError.invalidPatientData
        }
        
        // Handle age which might come back as different types from the database
        let age: Int
        if let ageInt = data["age"] as? Int {
            age = ageInt
        } else if let ageString = data["age"] as? String, let ageInt = Int(ageString) {
            age = ageInt
        } else {
            age = 0 // Default value
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        let email = data["email"] as? String
        
        // Handle email_verified which might come as different types
        let emailVerified: Bool
        if let verified = data["email_verified"] as? Bool {
            emailVerified = verified
        } else if let verifiedString = data["email_verified"] as? String {
            emailVerified = verifiedString.lowercased() == "true"
        } else {
            emailVerified = false // Default value
        }
        
        return Patient(
            id: id,
            userId: userId,
            name: name,
            age: age,
            gender: gender,
            createdAt: createdAt,
            updatedAt: updatedAt,
            email: email,
            emailVerified: emailVerified
        )
    }
}

// MARK: - Patient Errors
enum PatientError: Error, LocalizedError {
    case patientNotFound
    case invalidPatientData
    
    var errorDescription: String? {
        switch self {
        case .patientNotFound:
            return "Patient not found"
        case .invalidPatientData:
            return "Invalid patient data"
        }
    }
} 