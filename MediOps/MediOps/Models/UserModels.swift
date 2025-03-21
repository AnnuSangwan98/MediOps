import Foundation

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
    let id: UUID
    let email: String
    let role: UserRole
    let username: String
    let createdAt: Date
    let updatedAt: Date
    
    // These properties might be needed for Supabase user
    var appMetadata: [String: String]? = nil
    var userMetadata: [String: String]? = nil
    var aud: String? = nil
}

// MARK: - Patient Model
struct MediOpsPatient: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let age: Int
    let gender: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Hospital Admin Model
struct HospitalAdmin: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let hospitalName: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Doctor Model
struct Doctor: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let specialization: String
    let hospitalAdminId: UUID
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Lab Admin Model
struct LabAdmin: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let labName: String
    let hospitalAdminId: UUID
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Auth Response for login/signup
struct AuthResponse: Codable {
    let user: User
    let token: String
} 