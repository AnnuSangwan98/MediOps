import Foundation
import SwiftUI

// Hospital Status Enum
enum HospitalStatus: String, Codable {
    case pending = "Pending"
    case active = "Active"
    case inactive = "Inactive"
    
    var color: Color {
        switch self {
        case .active:
            return .green
        case .pending:
            return .orange
        case .inactive:
            return .red
        }
    }
}

// Hospital Model
struct Hospital: Identifiable, Codable {
    let id: String // This will store the hospital ID entered by superadmin (e.g., HOS001)
    var name: String
    var adminName: String
    var licenseNumber: String // This will store the state license (e.g., UP1234)
    var hospitalPhone: String // Hospital's emergency contact number
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var phone: String // Admin's phone number
    var email: String
    var status: HospitalStatus
    var registrationDate: Date
    var lastModified: Date
    var lastModifiedBy: String
    var imageData: Data?
    
    private static var lastUsedNumber = 1
    
    static func generateUniqueID() -> String {
        let id = String(format: "HOS%03d", lastUsedNumber)
        lastUsedNumber += 1
        return id
    }
    
    static func resetIDCounter() {
        lastUsedNumber = 1
    }
    
    // Coding Keys for Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, adminName, licenseNumber, hospitalPhone
        case street, city, state, zipCode, phone, email
        case status, registrationDate, lastModified, lastModifiedBy
        case imageData
    }
}

// UI representation for the list and add views
struct UIHospital: Identifiable {
    var id = UUID()
    var name: String
    var adminName: String
    var licenseNumber: String
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var phone: String
    var email: String
    var status: HospitalStatus = .active
    var hospitalPhone: String
    var imageData: Data?
} 
