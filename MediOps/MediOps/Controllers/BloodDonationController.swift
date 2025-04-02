import Foundation

class BloodDonationController {
    static let shared = BloodDonationController()
    private let supabase = SupabaseController.shared
    
    private init() {}
    
    /// Create a new blood donation request
    func createBloodDonationRequest(patientId: String, bloodType: String) async throws -> BloodDonation {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        
        // Create the request data
        let requestData: [String: String] = [
            "id": patientId,
            "blood_type": bloodType,
            "donation_date": dateFormatter.string(from: now),
            "created_at": dateFormatter.string(from: now),
            "updated_at": dateFormatter.string(from: now)
        ]
        
        // Insert into blood_donation table
        try await supabase.insert(into: "blood_donation", data: requestData)
        
        // Return the created blood donation request
        return BloodDonation(
            id: patientId,
            donationDate: now,
            bloodType: bloodType,
            createdAt: now,
            updatedAt: now
        )
    }
    
    /// Check if patient has an active blood donation request
    func hasActiveRequest(patientId: String) async throws -> Bool {
        let requests = try await supabase.select(
            from: "blood_donation",
            where: "id",
            equals: patientId
        )
        return !requests.isEmpty
    }
} 