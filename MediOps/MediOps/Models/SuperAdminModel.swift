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
                // First try to fetch hospitals from the controller
                let fetchedHospitals = try await HospitalController.shared.getAllHospitals()
                
                await MainActor.run {
                    self.hospitals = fetchedHospitals
                    self.isLoading = false
                }
            } catch {
                // If that fails, try a direct Supabase query with more detailed error handling
                do {
                    print("First attempt failed, trying direct query: \(error.localizedDescription)")
                    
                    // Direct query to Supabase
                    let hospitalsData = try await supabase.select(from: "hospitals")
                    print("Successfully fetched \(hospitalsData.count) hospitals")
                    
                    var parsedHospitals: [Hospital] = []
                    
                    // Try to parse each hospital separately so one bad record doesn't break everything
                    for hospitalData in hospitalsData {
                        do {
                            let hospital = try parseHospitalData(hospitalData)
                            parsedHospitals.append(hospital)
                        } catch {
                            print("Error parsing hospital: \(error.localizedDescription)")
                            // Continue with next hospital
                        }
                    }
                    
                    await MainActor.run {
                        self.hospitals = parsedHospitals
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                        self.isLoading = false
                        print("Fetch hospitals error: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseHospitalData(_ data: [String: Any]) throws -> Hospital {
        // Print the raw data for debugging
        print("Parsing hospital data: \(data)")
        
        guard
            let id = data["id"] as? String,
            let name = data["hospital_name"] as? String
        else {
            throw NSError(domain: "HospitalError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid hospital data"])
        }
        
        // Set defaults for non-critical fields to prevent parsing failures
        let adminName = data["admin_name"] as? String ?? "Unknown"
        let licenseNumber = data["licence"] as? String ?? ""
        let hospitalPhone = data["contact_number"] as? String ?? ""
        let street = data["hospital_address"] as? String ?? ""
        let city = data["hospital_city"] as? String ?? ""
        let state = data["hospital_state"] as? String ?? ""
        let zipCode = data["area_pincode"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let statusString = data["status"] as? String ?? "pending"
        
        // Parse dates with fallback to current date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = data["created_at"] as? String
        let registrationDate: Date
        if let createdAtString = createdAtString, let date = dateFormatter.date(from: createdAtString) {
            registrationDate = date
        } else {
            registrationDate = Date()
        }
        
        let updatedAtString = data["updated_at"] as? String
        let lastModified: Date
        if let updatedAtString = updatedAtString, let date = dateFormatter.date(from: updatedAtString) {
            lastModified = date
        } else {
            lastModified = Date()
        }
        
        // Parse status enum with default value
        let status: HospitalStatus
        switch statusString.lowercased() {
        case "active":
            status = .active
        case "inactive":
            status = .inactive
        default:
            status = .pending
        }
        
        let lastModifiedBy = data["last_modified_by"] as? String ?? "System"
        
        // Parse image data if available
        let imageData: Data?
        if let imageBase64 = data["hospital_profile_image"] as? String, !imageBase64.isEmpty {
            imageData = Data(base64Encoded: imageBase64)
        } else {
            imageData = nil
        }
        
        return Hospital(
            id: id,
            name: name,
            adminName: adminName,
            licenseNumber: licenseNumber,
            hospitalPhone: hospitalPhone,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            phone: hospitalPhone,
            email: email,
            status: status,
            registrationDate: registrationDate,
            lastModified: lastModified,
            lastModifiedBy: lastModifiedBy,
            imageData: imageData
        )
    }
    
    func addHospital(_ hospital: Hospital) {
        // For the SuperAdmin dashboard, we don't directly add hospitals here
        // AddHospitalForm handles this with its own Supabase calls
        // This is just for local state management
        hospitals.append(hospital)
    }
    
    func updateHospital(_ hospital: Hospital) async throws {
        // For Supabase updates, we'll use the existing SupabaseController methods
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
        
        // Update local state after successful update
        if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
            hospitals[index] = hospital
        }
    }
    
    func deleteHospital(_ hospital: Hospital) async throws {
        // Delete from Supabase
        try await supabase.delete(from: "hospitals", where: "id", equals: hospital.id)
        
        // After successful deletion, update the local state
        hospitals.removeAll { $0.id == hospital.id }
    }
} 