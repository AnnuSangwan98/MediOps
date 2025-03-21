import Foundation

// MARK: - MediOpsPatient Model
struct MediOpsPatient {  // Renamed from Patient to MediOpsPatient
    let id: String
    let userId: String  // Added to match user_id in database
    let name: String
    let age: Int
    let gender: String
    let createdAt: Date
    let updatedAt: Date  // Added to match updated_at in database
}

// MARK: - Codable
extension MediOpsPatient: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"  // Map to user_id in database
        case name
        case age
        case gender
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Identifiable
extension MediOpsPatient: Identifiable {}

// MARK: - Equatable
extension MediOpsPatient: Equatable {
    static func == (lhs: MediOpsPatient, rhs: MediOpsPatient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension MediOpsPatient: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 