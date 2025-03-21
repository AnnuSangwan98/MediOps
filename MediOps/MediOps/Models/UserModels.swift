import Foundation

enum UserRole: String, Codable {
    case superAdmin = "super_admin"
    case hospitalAdmin = "hospital_admin"
    case doctor = "doctor"
    case labAdmin = "lab_admin"
    case patient = "patient"
}

struct User: Codable {
    let id: UUID
    let email: String
    let role: UserRole
    let username: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case username
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Patient: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let age: Int
    let gender: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case age
        case gender
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct HospitalAdmin: Codable {
    let id: UUID
    let userId: UUID
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

struct Doctor: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let specialization: String
    let hospitalAdminId: UUID
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

struct LabAdmin: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let labName: String
    let hospitalAdminId: UUID
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