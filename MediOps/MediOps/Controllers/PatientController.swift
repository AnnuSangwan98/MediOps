import Foundation

class PatientController {
    static let shared = PatientController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    
    private init() {}
    
    // MARK: - Patient Management
    
    /// Register a new patient
    func registerPatient(email: String, password: String, name: String, age: Int, gender: String, bloodGroup: String = "Not Specified", address: String? = nil, phoneNumber: String = "9999999999") async throws -> (Patient, String) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("REGISTRATION: Starting process for \(normalizedEmail)")
        
        // Check if user or patient already exists
        let existingUsers = try await supabase.select(
            from: "users",
            where: "email",
            equals: normalizedEmail
        )
        
        if !existingUsers.isEmpty {
            print("REGISTRATION: User with email \(normalizedEmail) already exists in users table")
            throw AuthError.emailAlreadyExists
        }
        
        // Check if email exists in patients table too (as a safety check)
        let existingPatients = try await supabase.select(
            from: "patients",
            where: "email",
            equals: normalizedEmail
        )
        
        if !existingPatients.isEmpty {
            print("REGISTRATION: Email \(normalizedEmail) already exists in patients table")
            throw AuthError.emailAlreadyExists
        }
        
        print("REGISTRATION: No existing user found, proceeding with registration")
        
        var userId: String = ""
        var patientId: String = ""
        
        do {
            // 1. First register the base user
            let authResponse = try await userController.register(
                email: normalizedEmail,
                password: password,
                username: name,
                role: .patient
            )
            
            userId = authResponse.user.id
            print("REGISTRATION: User created with ID: \(userId)")
            
            // 2. Create patient record
            patientId = UUID().uuidString
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
                "email": normalizedEmail,
                "email_verified": "false", 
                "created_at": createdAt,
                "updated_at": createdAt,
                "bloodGroup": bloodGroup,  // Use the passed parameter
                "phoneNumber": phoneNumber, // Default phone number
                "emergencyContactNumber": "9999999999", // Default emergency number
                "emergencyRelationship": "Daughter", // Default relationship
                "password": password  // Store the raw password in patients table as per schema
            ]
            
            // Add optional fields if provided
            if let address = address {
                patientData["address"] = address
            }
            
            // Include default emergency contact name if not provided
            patientData["emergencyContactName"] = "Astha" // Default emergency contact name
            
            try await supabase.insert(into: "patients", data: patientData)
            print("REGISTRATION: Patient record created with ID: \(patientId)")
            
            // 3. Return the patient object and token
            let patient = Patient(
                id: patientId,
                userId: authResponse.user.id,
                name: name,
                age: age,
                gender: gender,
                createdAt: now,
                updatedAt: now,
                email: normalizedEmail,
                emailVerified: false,
                bloodGroup: bloodGroup,
                address: address,
                phoneNumber: phoneNumber,
                emergencyContactName: "Astha", // Default emergency contact
                emergencyContactNumber: "9999999999",
                emergencyRelationship: "Daughter"
            )
            
            print("REGISTRATION: Complete! User and patient records created successfully")
            return (patient, authResponse.token)
            
        } catch let error as AuthError {
            print("REGISTRATION ERROR: \(error.localizedDescription)")
            
            // If we created a user but failed to create the patient, try to rollback the user
            if !userId.isEmpty {
                print("REGISTRATION: Rolling back user record due to failed patient creation")
                await supabase.deleteRollback(from: "users", where: "id", equals: userId)
            }
            
            throw error
        } catch {
            print("REGISTRATION ERROR: Unexpected error: \(error.localizedDescription)")
            
            // Attempt rollback of any created records
            if !userId.isEmpty {
                print("REGISTRATION: Rolling back user record due to error")
                await supabase.deleteRollback(from: "users", where: "id", equals: userId)
            }
            
            if !patientId.isEmpty {
                print("REGISTRATION: Rolling back patient record due to error")
                await supabase.deleteRollback(from: "patients", where: "id", equals: patientId)
            }
            
            throw error
        }
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
        // 1. Get current patient data to verify it exists
        _ = try await getPatient(id: id)
        
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
        
        // Handle bloodGroup field - use a default if not present
        let bloodGroup = data["bloodGroup"] as? String ?? "Not Specified"
        
        // Handle new fields with default values from the schema if not present
        let address = data["address"] as? String
        let phoneNumber = data["phoneNumber"] as? String ?? "9999999999"
        let emergencyContactName = data["emergencyContactName"] as? String
        let emergencyContactNumber = data["emergencyContactNumber"] as? String ?? "9999999999"
        let emergencyRelationship = data["emergencyRelationship"] as? String ?? "Daughter"
        
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
            emailVerified: emailVerified,
            bloodGroup: bloodGroup,
            address: address,
            phoneNumber: phoneNumber,
            emergencyContactName: emergencyContactName,
            emergencyContactNumber: emergencyContactNumber,
            emergencyRelationship: emergencyRelationship
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