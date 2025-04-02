import Foundation
import SwiftUI
import Supabase

class BloodDonationController: ObservableObject {
    static let shared = BloodDonationController()
    
    @Published var bloodRequests: [BloodDonationRequest] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase = SupabaseController.shared
    
    private init() {} // Make init private to enforce singleton pattern
    
    // MARK: - Blood Request Management
    
    func hasActiveRequest(patientId: String) async -> Bool {
        do {
            let requests = try await supabase.select(
                from: "blood_donation",
                where: "requested_by",
                equals: patientId
            )
            
            // Check if any request has activity_status = true
            let hasActive = requests.contains { request in
                request["activity_status"] as? Bool == true
            }
            
            return hasActive
        } catch {
            print("Error checking active request: \(error)")
            return false
        }
    }
    
    func createBloodDonationRequest(patientId: String, bloodGroup: String) async -> Bool {
        print("🩸 Creating blood request for patient: \(patientId), blood group: \(bloodGroup)")
        do {
            // First check if patient exists
            print("🩸 Checking if patient exists...")
            let patients = try await supabase.select(
                from: "patients",
                where: "id",
                equals: patientId
            )
            
            guard !patients.isEmpty else {
                print("❌ Patient not found with ID: \(patientId)")
                return false
            }
            print("✅ Patient found")
            
            // Check for existing active request
            print("🩸 Checking for existing active requests...")
            let hasActive = await hasActiveRequest(patientId: patientId)
            guard !hasActive else {
                print("❌ Patient already has an active request")
                return false
            }
            print("✅ No active requests found")
            
            // Create new request with UUID
            print("🩸 Creating new blood request...")
            let requestId = UUID().uuidString
            let dateFormatter = ISO8601DateFormatter()
            let requestData = BloodDonationRequestData(
                id: requestId,
                requested_by: patientId,
                blood_group: bloodGroup,
                activity_status: true,
                created_at: dateFormatter.string(from: Date()),
                required_date: dateFormatter.string(from: Date())
            )
            
            print("🩸 Request data prepared: \(requestData)")
            
            let result = try await supabase.insert(
                into: "blood_donation",
                data: requestData
            )
            
            print("✅ Successfully created blood request with ID: \(requestId)")
            
            // Update local state immediately
            await MainActor.run {
                let newRequest = BloodDonationRequest(
                    id: requestId,
                    bloodGroup: bloodGroup,
                    units: 0,
                    activityStatus: true,
                    createdAt: Date()
                )
                self.bloodRequests.append(newRequest)
            }
            
            // Refresh the blood requests to ensure consistency
            await fetchBloodRequests(patientId: patientId)
            return true
        } catch {
            print("❌ Error creating blood request: \(error)")
            print("❌ Error details: \(String(describing: error))")
            return false
        }
    }
    
    func cancelBloodRequest(requestId: String) async -> Bool {
        print("🩸 Cancelling blood request with ID: \(requestId)")
        do {
            let updateData = BloodDonationUpdateData(
                activity_status: false,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            print("🩸 Sending update request to Supabase...")
            let result = try await supabase.update(
                table: "blood_donation",
                data: updateData,
                where: "id",
                equals: requestId
            )
            
            print("✅ Successfully cancelled blood request")
            
            // Update local state immediately
            await MainActor.run {
                if let index = bloodRequests.firstIndex(where: { $0.id == requestId }) {
                    bloodRequests[index] = BloodDonationRequest(
                        id: bloodRequests[index].id,
                        bloodGroup: bloodRequests[index].bloodGroup,
                        units: bloodRequests[index].units,
                        activityStatus: false,
                        createdAt: bloodRequests[index].createdAt
                    )
                }
            }
            
            return true
        } catch {
            print("❌ Error cancelling blood request: \(error)")
            return false
        }
    }
    
    func fetchBloodRequests(patientId: String) async {
        do {
            let requests = try await supabase.select(
                from: "blood_donation",
                where: "requested_by",
                equals: patientId
            )
            
            // Convert to BloodDonationRequest objects
            let bloodRequests = requests.compactMap { request -> BloodDonationRequest? in
                guard let id = request["id"] as? String,
                      let bloodGroup = request["blood_group"] as? String,
                      let activityStatus = request["activity_status"] as? Bool,
                      let createdAt = request["created_at"] as? String else {
                    return nil
                }
                
                return BloodDonationRequest(
                    id: id,
                    bloodGroup: bloodGroup,
                    units: 0, // Assuming units are not available in the response
                    activityStatus: activityStatus,
                    createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date()
                )
            }
            
            await MainActor.run {
                self.bloodRequests = bloodRequests
                self.isLoading = false
                self.error = nil
            }
        } catch {
            print("Error fetching blood requests: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

// MARK: - Models
struct BloodDonationRequest: Identifiable {
    let id: String
    let bloodGroup: String
    let units: Int
    let activityStatus: Bool
    let createdAt: Date
}

// Data model for creating a new blood donation request
struct BloodDonationRequestData: Encodable {
    let id: String
    let requested_by: String
    let blood_group: String
    let activity_status: Bool
    let created_at: String
    let required_date: String
}

// Data model for updating a blood donation request
struct BloodDonationUpdateData: Encodable {
    let activity_status: Bool
    let updated_at: String
}