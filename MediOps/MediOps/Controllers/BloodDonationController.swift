import Foundation
import SwiftUI

class BloodDonationController: ObservableObject {
    static let shared = BloodDonationController()
    
    @Published var isBloodDonor: Bool = false
    @Published var error: Error?
    
    private init() {}
    
    func fetchBloodDonorStatus(patientId: String) async {
        do {
            let response = try await SupabaseController.shared.client
                .from("patients")
                .select("is_blood_donor")
                .eq("id", value: patientId)
                .execute()
            
            if let responseData = response.data as? Data {
                do {
                    let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                    
                    if let dataArray = json as? [[String: Any]] {
                        if let firstRecord = dataArray.first,
                           let isDonor = firstRecord["is_blood_donor"] as? Bool {
                            await MainActor.run {
                                self.isBloodDonor = isDonor
                            }
                            return
                        }
                    } else if let singleRecord = json as? [String: Any] {
                        if let isDonor = singleRecord["is_blood_donor"] as? Bool {
                            await MainActor.run {
                                self.isBloodDonor = isDonor
                            }
                            return
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.error = error
                        self.isBloodDonor = false
                    }
                }
            }
            
            await MainActor.run {
                self.isBloodDonor = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isBloodDonor = false
            }
        }
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
                }
                
                // Verify the update by fetching the latest status
                await fetchBloodDonorStatus(patientId: patientId)
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
