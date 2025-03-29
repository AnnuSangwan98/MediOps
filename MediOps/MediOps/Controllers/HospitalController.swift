import Foundation

class HospitalController {
    static let shared = HospitalController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    
    private init() {}
    
    // MARK: - Hospital Management
    
    /// Create a new hospital
    func createHospital(_ hospital: Hospital) async throws {
        let dateFormatter = ISO8601DateFormatter()
        let now = Date()
        
        struct HospitalData: Encodable {
            let id: String
            let hospital_name: String
            let admin_name: String
            let licence: String
            let contact_number: String
            let hospital_address: String
            let hospital_city: String
            let hospital_state: String
            let area_pincode: String
            let email: String
            let status: String
            let created_at: String
            let updated_at: String
            let description: String?
            let hospital_profile_image: String?
            let last_modified_by: String?
            let hospital_accreditation: String?
            let type: String?
            let departments: [String]?
        }
        
        // Convert image data to base64 string if available
        let imageBase64: String? = {
            if let imageData = hospital.imageData {
                return imageData.base64EncodedString()
            }
            return nil
        }()
        
        let hospitalData = HospitalData(
            id: hospital.id,
            hospital_name: hospital.name,
            admin_name: hospital.adminName,
            licence: hospital.licenseNumber,
            contact_number: hospital.hospitalPhone,
            hospital_address: hospital.street,
            hospital_city: hospital.city,
            hospital_state: hospital.state,
            area_pincode: hospital.zipCode,
            email: hospital.email,
            status: hospital.status.rawValue.lowercased(),
            created_at: dateFormatter.string(from: now),
            updated_at: dateFormatter.string(from: now),
            description: "Hospital created by Super Admin",
            hospital_profile_image: imageBase64,
            last_modified_by: hospital.lastModifiedBy,
            hospital_accreditation: "General",
            type: "General",
            departments: ["General"]
        )
        
        try await supabase.insert(into: "hospitals", data: hospitalData)
    }
    
    /// Get hospital by ID
    func getHospital(id: String) async throws -> Hospital {
        let hospitals = try await supabase.select(
            from: "hospitals",
            where: "id",
            equals: id
        )
        
        guard let hospitalData = hospitals.first else {
            throw HospitalError.hospitalNotFound
        }
        
        return try parseHospitalData(hospitalData)
    }
    
    /// Update existing hospital
    func updateHospital(_ hospital: Hospital) async throws {
        let dateFormatter = ISO8601DateFormatter()
        let now = Date()
        
        struct HospitalUpdateData: Encodable {
            let hospital_name: String
            let admin_name: String
            let licence: String
            let contact_number: String
            let hospital_address: String
            let hospital_city: String
            let hospital_state: String
            let area_pincode: String
            let email: String
            let status: String
            let updated_at: String
            let last_modified_by: String?
            let hospital_profile_image: String?
        }
        
        // Convert image data to base64 string if available
        let imageBase64: String? = {
            if let imageData = hospital.imageData {
                return imageData.base64EncodedString()
            }
            return nil
        }()
        
        let hospitalData = HospitalUpdateData(
            hospital_name: hospital.name,
            admin_name: hospital.adminName,
            licence: hospital.licenseNumber,
            contact_number: hospital.hospitalPhone,
            hospital_address: hospital.street,
            hospital_city: hospital.city,
            hospital_state: hospital.state,
            area_pincode: hospital.zipCode,
            email: hospital.email,
            status: hospital.status.rawValue.lowercased(),
            updated_at: dateFormatter.string(from: now),
            last_modified_by: hospital.lastModifiedBy,
            hospital_profile_image: imageBase64
        )
        
        try await supabase.update(
            table: "hospitals",
            data: hospitalData,
            where: "id",
            equals: hospital.id
        )
    }
    
    /// Delete hospital
    func deleteHospital(id: String) async throws {
        try await supabase.delete(
            from: "hospitals",
            where: "id",
            equals: id
        )
    }
    
    /// Get all hospitals
    func getAllHospitals() async throws -> [Hospital] {
        let hospitalsData = try await supabase.select(from: "hospitals")
        return try hospitalsData.map { try parseHospitalData($0) }
    }
    
    /// Get hospitals by city
    func getHospitalsByCity(_ city: String) async throws -> [Hospital] {
        let hospitalsData = try await supabase.select(
            from: "hospitals",
            where: "city",
            equals: city
        )
        return try hospitalsData.map { try parseHospitalData($0) }
    }
    
    // MARK: - Helper Methods
    
    private func parseHospitalData(_ data: [String: Any]) throws -> Hospital {
        // Print raw data for debugging
        print("Raw hospital data: \(data)")
        
        guard
            let id = data["id"] as? String,
            let name = data["hospital_name"] as? String,
            let adminName = data["admin_name"] as? String,
            let licenseNumber = data["licence"] as? String,
            let hospitalPhone = data["contact_number"] as? String,
            let street = data["hospital_address"] as? String,
            let city = data["hospital_city"] as? String,
            let state = data["hospital_state"] as? String,
            let zipCode = data["area_pincode"] as? String,
            let email = data["email"] as? String,
            let statusString = data["status"] as? String,
            let createdAtString = data["created_at"] as? String,
            let updatedAtString = data["updated_at"] as? String
        else {
            print("Missing required fields in hospital data")
            throw HospitalError.invalidData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard
            let registrationDate = dateFormatter.date(from: createdAtString),
            let lastModified = dateFormatter.date(from: updatedAtString)
        else {
            print("Invalid date format in hospital data")
            throw HospitalError.invalidData
        }
        
        // Status validation with case-insensitive comparison
        let status: HospitalStatus
        switch statusString.lowercased() {
        case "active":
            status = .active
        case "pending":
            status = .pending
        case "inactive":
            status = .inactive
        default:
            print("Invalid status value: \(statusString)")
            throw HospitalError.invalidData
        }
        
        let lastModifiedBy = data["last_modified_by"] as? String ?? "System"
        let imageData = data["hospital_profile_image"] as? Data
        
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
            phone: hospitalPhone, // Use the same phone number
            email: email,
            status: status,
            registrationDate: registrationDate,
            lastModified: lastModified,
            lastModifiedBy: lastModifiedBy,
            imageData: imageData
        )
    }
}

// MARK: - Hospital Errors
enum HospitalError: Error {
    case hospitalNotFound
    case invalidData
    case networkError
    case databaseError
    
    var localizedDescription: String {
        switch self {
        case .hospitalNotFound:
            return "Hospital not found"
        case .invalidData:
            return "Invalid hospital data"
        case .networkError:
            return "Network error occurred"
        case .databaseError:
            return "Database error occurred"
        }
    }
} 
