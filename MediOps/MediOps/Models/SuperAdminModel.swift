import Foundation
import SwiftUI

// Super Admin Model
struct SuperAdmin: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var phone: String
    var lastLogin: Date
    var createdDate: Date
    var isActive: Bool
    
    static func generateUniqueID() -> String {
        return "SA" + UUID().uuidString.prefix(8)
    }
}

// View Model for SuperAdmin Dashboard
class SuperAdminDashboardViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = []
    @Published var searchText: String = ""
    @Published var selectedCity: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let supabase = SupabaseController.shared
    
    init() {
        fetchHospitals()
    }
    
    var filteredHospitals: [Hospital] {
        var filtered = hospitals
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { hospital in
                hospital.name.localizedCaseInsensitiveContains(searchText) ||
                hospital.adminName.localizedCaseInsensitiveContains(searchText) ||
                hospital.licenseNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply city filter
        if let city = selectedCity {
            filtered = filtered.filter { $0.city == city }
        }
        
        return filtered
    }
    
    var uniqueCities: [String] {
        Array(Set(hospitals.map { $0.city })).sorted()
    }
    
    var totalHospitals: Int {
        hospitals.count
    }
    
    // MARK: - Hospital Management
    
    func fetchHospitals() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let fetchedHospitals = try await supabase.fetchHospitals()
                
                await MainActor.run {
                    self.hospitals = fetchedHospitals
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func addHospital(_ hospital: Hospital) {
        // For the SuperAdmin dashboard, we don't directly add hospitals here
        // AddHospitalForm handles this with its own Supabase calls
        // This is just for local state management
        hospitals.append(hospital)
    }
    
    func updateHospital(_ hospital: Hospital) {
        // For Supabase updates, we'll use the existing SupabaseController methods
        Task {
            do {
                // Create a simple struct for encoding hospital data
                struct HospitalUpdateData: Encodable {
                    let hospital_name: String
                    let hospital_address: String
                    let hospital_state: String
                    let hospital_city: String
                    let area_pincode: String
                    let email: String
                    let contact_number: String
                    let emergency_contact_number: String
                    let licence: String
                    let status: String
                }
                
                // Create the update data
                let updateData = HospitalUpdateData(
                    hospital_name: hospital.name,
                    hospital_address: hospital.street,
                    hospital_state: hospital.state,
                    hospital_city: hospital.city,
                    area_pincode: hospital.zipCode,
                    email: hospital.email,
                    contact_number: hospital.phone,
                    emergency_contact_number: hospital.hospitalPhone,
                    licence: hospital.licenseNumber,
                    status: hospital.status.rawValue.lowercased()
                )
                
                // Update in Supabase
                try await supabase.update(table: "hospitals", data: updateData, where: "id", equals: hospital.id)
                
                // Update local state
                await MainActor.run {
                    if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
                        hospitals[index] = hospital
                    }
                }
            } catch {
                print("Failed to update hospital in Supabase: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteHospital(_ hospital: Hospital) {
        Task {
            do {
                try await supabase.delete(from: "hospitals", where: "id", equals: hospital.id)
                
                await MainActor.run {
                    hospitals.removeAll { $0.id == hospital.id }
                }
            } catch {
                print("Failed to delete hospital: \(error.localizedDescription)")
            }
        }
    }
} 