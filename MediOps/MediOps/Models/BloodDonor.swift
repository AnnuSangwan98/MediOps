import Foundation

struct BloodDonor: Identifiable, Codable {
    let id: String
    let name: String
    let bloodGroup: String
    let contactNumber: String
    let email: String
    var requestStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "patient_id"
        case name
        case bloodGroup
        case contactNumber = "phoneNumber"
        case email
        case requestStatus
    }
    
    // Helper properties for status checks
    var hasPendingRequest: Bool { requestStatus == "Pending" }
    var hasCompletedRequest: Bool { requestStatus == "Completed" }
    var hasRejectedRequest: Bool { requestStatus == "Rejected" || requestStatus == "Cancelled" }
    var hasActiveRequest: Bool { hasPendingRequest || requestStatus == "Accepted" }
    
    // Only allow requesting donors that don't have active requests
    // Donors with pending or accepted requests should be locked
    var canBeRequested: Bool {
        return !hasActiveRequest  // Can request if NOT active
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
        case completed = "Completed"
        case cancelled = "Cancelled"
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