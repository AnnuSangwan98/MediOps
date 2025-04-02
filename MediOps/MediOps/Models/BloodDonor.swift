import Foundation

struct BloodDonor: Identifiable, Codable {
    let id: String
    let name: String
    let bloodGroup: String
    let contactNumber: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "patient_id"
        case name
        case bloodGroup
        case contactNumber = "phoneNumber"
        case email
    }
}

// Blood Donation Request Model
struct BloodDonorRequest: Identifiable, Codable {
    let id: UUID
    let donorId: String
    let requestedByAdmin: String
    let bloodRequestedTime: Date
    let requestedActivityStatus: Bool
    let bloodRequestedFor: String
    let requestStatus: RequestStatus
    
    enum RequestStatus: String, Codable {
        case accepted = "Accepted"
        case rejected = "Rejected"
        case pending = "Pending"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case donorId = "donor_id"
        case requestedByAdmin = "requested_by_admin"
        case bloodRequestedTime = "blood_requested_time"
        case requestedActivityStatus = "requested_activity_status"
        case bloodRequestedFor = "blood_requested_for"
        case requestStatus = "request_status"
    }
} 