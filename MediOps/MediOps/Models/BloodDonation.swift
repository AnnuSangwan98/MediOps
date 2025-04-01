import Foundation

struct BloodDonation: Identifiable, Codable {
    let id: String // This will be the patient_id
    let donationDate: Date
    let bloodType: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case donationDate = "donation_date"
        case bloodType = "blood_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 