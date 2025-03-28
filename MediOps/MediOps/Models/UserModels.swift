import Foundation

// Create a namespace for our models
enum Models {
    // MARK: - User Role
    enum UserRole: String, Codable {
        case patient
        case doctor
        case hospitalAdmin = "HOSPITAL_ADMIN"
        case labAdmin
        case superAdmin
        
        // Add initializer to handle case variations
        init?(rawValue: String) {
            switch rawValue.lowercased() {
            case "patient":
                self = .patient
            case "doctor":
                self = .doctor
            case "hospitaladmin", "hospital_admin", "hospital admin":
                self = .hospitalAdmin
            case "labadmin", "lab_admin", "lab admin":
                self = .labAdmin
            case "superadmin", "super_admin", "super admin":
                self = .superAdmin
            default:
                return nil
            }
        }
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
        let userId: String?
        let name: String
        let specialization: String
        let hospitalId: String
        let qualifications: [String]
        let licenseNo: String
        let experience: Int
        let addressLine: String
        let state: String
        let city: String
        let pincode: String
        let email: String
        let contactNumber: String?
        let emergencyContactNumber: String?
        let doctorStatus: String
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case name
            case specialization
            case hospitalId = "hospital_id"
            case qualifications
            case licenseNo = "license_no"
            case experience
            case addressLine = "address_line"
            case state
            case city
            case pincode
            case email
            case contactNumber = "contact_number"
            case emergencyContactNumber = "emergency_contact_number"
            case doctorStatus = "doctor_status"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    // MARK: - Lab Admin Model
    struct LabAdmin: Codable, Identifiable {
        let id: String
        let hospitalId: String
        let name: String
        let email: String
        let contactNumber: String
        let department: String
        let address: String
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case hospitalId = "hospital_id"
            case name
            case email
            case contactNumber = "contact_number"
            case department
            case address = "Address"
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