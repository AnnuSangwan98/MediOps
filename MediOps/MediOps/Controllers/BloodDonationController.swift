import Foundation
import SwiftUI

struct BloodRequest: Identifiable, Codable {
    let id: String
    let requestedByAdmin: String
    let bloodRequestedTime: Date
    let requestedActivityStatus: Bool
    let bloodRequestedFor: String
    var hospitalName: String?
    var hospitalAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestedByAdmin = "requested_by_admin"
        case bloodRequestedTime = "blood_requested_time"
        case requestedActivityStatus = "requested_activity_status"
        case bloodRequestedFor = "blood_requested_for"
        case hospitalName = "hospital_name"
        case hospitalAddress = "hospital_address"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        requestedByAdmin = try container.decode(String.self, forKey: .requestedByAdmin)
        requestedActivityStatus = try container.decode(Bool.self, forKey: .requestedActivityStatus)
        bloodRequestedFor = try container.decode(String.self, forKey: .bloodRequestedFor)
        hospitalName = try container.decodeIfPresent(String.self, forKey: .hospitalName)
        hospitalAddress = try container.decodeIfPresent(String.self, forKey: .hospitalAddress)
        
        // Handle date decoding with multiple formats
        let dateString = try container.decode(String.self, forKey: .bloodRequestedTime)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different date formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        var decodedDate: Date?
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                decodedDate = date
                break
            }
        }
        
        guard let date = decodedDate else {
            throw DecodingError.dataCorruptedError(
                forKey: .bloodRequestedTime,
                in: container,
                debugDescription: "Date string does not match any expected format"
            )
        }
        
        bloodRequestedTime = date
    }
}

class BloodDonationController: ObservableObject {
    static let shared = BloodDonationController()
    
    @Published var isBloodDonor: Bool = false
    @Published var error: Error?
    @Published var activeRequests: [BloodRequest] = []
    @Published var donationHistory: [BloodRequest] = []
    @Published var isLoadingRequests: Bool = false
    @Published var isLoadingHistory: Bool = false
    @Published var userBloodGroup: String?
    
    private init() {}
    
    func fetchUserBloodGroup(patientId: String) async {
        do {
            let response = try await SupabaseController.shared.client
                .from("patients")
                .select("bloodGroup")
                .eq("id", value: patientId)
                .single()
                .execute()
            
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
               let bloodGroup = json["bloodGroup"] as? String {
                await MainActor.run {
                    self.userBloodGroup = bloodGroup
                }
            }
        } catch {
            print("Error fetching blood group: \(error)")
        }
    }
    
    func fetchBloodDonorStatus(patientId: String) async {
        do {
            let response = try await SupabaseController.shared.client
                .from("patients")
                .select("is_blood_donor, bloodGroup")
                .eq("id", value: patientId)
                .execute()
            
            do {
                let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]]
                
                await MainActor.run {
                    if let firstRecord = json?.first {
                        self.isBloodDonor = firstRecord["is_blood_donor"] as? Bool ?? false
                        self.userBloodGroup = firstRecord["bloodGroup"] as? String
                        
                        // If user is a blood donor, fetch active requests and history
                        if self.isBloodDonor {
                            Task {
                                await self.fetchActiveBloodRequests()
                                await self.fetchDonationHistory()
                            }
                        }
                    } else {
                        self.isBloodDonor = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isBloodDonor = false
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isBloodDonor = false
            }
        }
    }
    
    func fetchActiveBloodRequests() async {
        guard isBloodDonor else {
            await MainActor.run {
                self.activeRequests = []
            }
            return
        }
        
        await MainActor.run { 
            self.isLoadingRequests = true 
        }
        
        do {
            // First get all active blood requests
            let response = try await SupabaseController.shared.client
                .from("blood_donor_requests")
                .select()
                .eq("requested_activity_status", value: true)
                .order("blood_requested_time", ascending: false)
                .execute()
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                var requests = try decoder.decode([BloodRequest].self, from: response.data)
                
                // Filter requests based on blood group compatibility
                if let userBloodGroup = self.userBloodGroup {
                    requests = requests.filter { request in
                        return isBloodCompatible(donorBloodGroup: userBloodGroup, 
                                               recipientBloodGroup: request.bloodRequestedFor)
                    }
                }
                
                // Fetch hospital details for each request
                for i in 0..<requests.count {
                    let hospitalId = requests[i].requestedByAdmin
                    
                    let hospitalResponse = try await SupabaseController.shared.client
                        .from("hospital_admins")
                        .select("hospitals (hospital_name, hospital_address)")
                        .eq("id", value: hospitalId)
                        .single()
                        .execute()
                    
                    if let json = try? JSONSerialization.jsonObject(with: hospitalResponse.data, options: []) as? [String: Any],
                       let hospital = json["hospitals"] as? [String: Any] {
                        requests[i].hospitalName = hospital["hospital_name"] as? String
                        requests[i].hospitalAddress = hospital["hospital_address"] as? String
                    }
                }
                
                await MainActor.run {
                    self.activeRequests = requests
                    self.isLoadingRequests = false
                }
            } catch {
                print("Error decoding blood requests: \(error)")
                await MainActor.run {
                    self.error = error
                    self.activeRequests = []
                    self.isLoadingRequests = false
                }
            }
        } catch {
            print("Error fetching blood requests: \(error)")
            await MainActor.run {
                self.error = error
                self.activeRequests = []
                self.isLoadingRequests = false
            }
        }
    }
    
    @MainActor
    func fetchDonationHistory() async {
        isLoadingHistory = true
        
        do {
            guard let patientId = UserDefaults.standard.string(forKey: "current_patient_id") else {
                print("Error: No patient ID found")
                isLoadingHistory = false
                return
            }
            
            // First get all completed donations for this donor
            let response = try await SupabaseController.shared.client.database
                .from("blood_donor_requests")
                .select()
                .eq("donor_id", value: patientId)
                .eq("request_status", value: "Accepted")
                .order("blood_requested_time", ascending: false)
                .execute()
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                var history = try decoder.decode([BloodRequest].self, from: response.data)
                
                // Fetch hospital details for each donation
                for i in 0..<history.count {
                    let hospitalId = history[i].requestedByAdmin
                    
                    let hospitalResponse = try await SupabaseController.shared.client
                        .from("hospital_admins")
                        .select("hospitals (hospital_name, hospital_address)")
                        .eq("id", value: hospitalId)
                        .single()
                        .execute()
                    
                    if let json = try? JSONSerialization.jsonObject(with: hospitalResponse.data, options: []) as? [String: Any],
                       let hospital = json["hospitals"] as? [String: Any] {
                        history[i].hospitalName = hospital["hospital_name"] as? String
                        history[i].hospitalAddress = hospital["hospital_address"] as? String
                    }
                }
                
                self.donationHistory = history
            } catch {
                print("Error decoding donation history: \(error)")
                self.donationHistory = []
            }
        } catch {
            print("Error fetching donation history: \(error)")
            self.donationHistory = []
        }
        
        isLoadingHistory = false
    }
    
    private func isBloodCompatible(donorBloodGroup: String, recipientBloodGroup: String) -> Bool {
        // Blood compatibility chart
        let compatibilityChart: [String: Set<String>] = [
            "O-": ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"],
            "O+": ["O+", "A+", "B+", "AB+"],
            "A-": ["A-", "A+", "AB-", "AB+"],
            "A+": ["A+", "AB+"],
            "B-": ["B-", "B+", "AB-", "AB+"],
            "B+": ["B+", "AB+"],
            "AB-": ["AB-", "AB+"],
            "AB+": ["AB+"]
        ]
        
        if let compatibleRecipients = compatibilityChart[donorBloodGroup] {
            return compatibleRecipients.contains(recipientBloodGroup)
        }
        return false
    }
    
    func updateBloodDonorStatus(patientId: String, isDonor: Bool) async {
        do {
            let response = try await SupabaseController.shared.client
                .from("patients")
                .update(["is_blood_donor": isDonor])
                .eq("id", value: patientId)
                .execute()
            
            if response.status == 200 {
                await MainActor.run {
                    self.isBloodDonor = isDonor
                    if !isDonor {
                        self.activeRequests = []
                    }
                }
                
                // If becoming a donor, fetch active requests
                if isDonor {
                    await fetchActiveBloodRequests()
                }
            } else {
                await MainActor.run {
                    self.error = NSError(domain: "BloodDonationController", code: response.status, userInfo: [NSLocalizedDescriptionKey: "Failed to update blood donor status"])
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
} 
