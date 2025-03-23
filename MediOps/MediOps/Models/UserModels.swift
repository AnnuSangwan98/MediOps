import Foundation

// Create a namespace for our models
enum Models {
    // MARK: - User Role
    enum UserRole: String, Codable {
        case patient
        case doctor
        case hospitalAdmin
        case labAdmin
        case superAdmin
    }

    // MARK: - Base User Model
    struct User: Codable, Identifiable {
        let id: String
        let email: String
        let role: UserRole
        let username: String
        let createdAt: Date
        let updatedAt: Date
        let passwordHash: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case email
            case role
            case username
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case passwordHash = "password_hash"
        }
    }

    // MARK: - Patient Model
    struct Patient: Codable, Identifiable {
        let id: String
        let userId: String
        let name: String
        let age: Int
        let gender: String
        let createdAt: Date
        let updatedAt: Date
        let email: String?
        let emailVerified: Bool?
        let bloodGroup: String
        let address: String?
        let phoneNumber: String
        let emergencyContactName: String?
        let emergencyContactNumber: String
        let emergencyRelationship: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name
            case age
            case gender
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case email
            case emailVerified = "email_verified"
            case bloodGroup
            case address
            case phoneNumber
            case emergencyContactName
            case emergencyContactNumber
            case emergencyRelationship
        }
    }

    // MARK: - Hospital Admin Model
    struct HospitalAdmin: Codable, Identifiable {
        let id: String
        let userId: String
        let name: String
        let hospitalName: String
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name
            case hospitalName = "hospital_name"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Doctor Model
    struct Doctor: Codable, Identifiable {
        let id: String
        let userId: String
        let name: String
        let specialization: String
        let hospitalAdminId: String
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name
            case specialization
            case hospitalAdminId = "hospital_admin_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Lab Admin Model
    struct LabAdmin: Codable, Identifiable {
        let id: String
        let userId: String
        let name: String
        let labName: String
        let hospitalAdminId: String
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name
            case labName = "lab_name"
            case hospitalAdminId = "hospital_admin_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Activity Model
    struct Activity: Codable, Identifiable {
        let id: String
        let type: String
        let title: String
        let timestamp: Date
        let status: String
        let doctorId: String?
        let labAdminId: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case title
            case timestamp
            case status
            case doctorId = "doctor_id"
            case labAdminId = "lab_admin_id"
        }
    }

    // MARK: - Auth Response for login/signup
    struct AuthResponse: Codable {
        let user: User
        let token: String
        
        enum CodingKeys: String, CodingKey {
            case user
            case token
        }
    }
}

// Re-expose types globally to minimize refactoring for now
typealias UserRole = Models.UserRole
typealias User = Models.User
typealias Patient = Models.Patient
typealias HospitalAdmin = Models.HospitalAdmin
typealias Doctor = Models.Doctor
typealias LabAdmin = Models.LabAdmin
typealias Activity = Models.Activity
typealias AuthResponse = Models.AuthResponse 