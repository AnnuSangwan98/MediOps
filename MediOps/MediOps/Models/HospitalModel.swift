import Foundation

extension Models {
    // MARK: - Hospital Model
    struct Hospital: Codable, Identifiable {
        let id: String
        let name: String
        let adminName: String
        let licenseNumber: String
        let street: String
        let city: String
        let state: String
        let zipCode: String
        let phone: String
        let email: String
        let status: String
        let registrationDate: Date
        let lastModified: Date
        let lastModifiedBy: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case adminName = "admin_name"
            case licenseNumber = "license_number"
            case street
            case city
            case state
            case zipCode = "zip_code"
            case phone
            case email
            case status
            case registrationDate = "registration_date"
            case lastModified = "last_modified"
            case lastModifiedBy = "last_modified_by"
        }
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
    var status: String = "active"
} 