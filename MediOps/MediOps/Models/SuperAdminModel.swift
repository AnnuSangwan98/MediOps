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
    
    func addHospital(_ hospital: Hospital) {
        hospitals.append(hospital)
    }
    
    func updateHospital(_ hospital: Hospital) {
        if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
            hospitals[index] = hospital
        }
    }
    
    func deleteHospital(_ hospital: Hospital) {
        hospitals.removeAll { $0.id == hospital.id }
    }
} 