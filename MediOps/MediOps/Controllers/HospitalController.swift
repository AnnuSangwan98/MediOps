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
            let name: String
            let admin_name: String
            let license_number: String
            let hospital_phone: String
            let street: String
            let city: String
            let state: String
            let zip_code: String
            let phone: String
            let email: String
            let status: String
            let registration_date: String
            let last_modified: String
            let last_modified_by: String
            let image_data: Data?
        }
        
        let hospitalData = HospitalData(
            id: hospital.id,
            name: hospital.name,
            admin_name: hospital.adminName,
            license_number: hospital.licenseNumber,
            hospital_phone: hospital.hospitalPhone,
            street: hospital.street,
            city: hospital.city,
            state: hospital.state,
            zip_code: hospital.zipCode,
            phone: hospital.phone,
            email: hospital.email,
            status: hospital.status.rawValue,
            registration_date: dateFormatter.string(from: hospital.registrationDate),
            last_modified: dateFormatter.string(from: now),
            last_modified_by: hospital.lastModifiedBy,
            image_data: hospital.imageData
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
            let name: String
            let admin_name: String
            let license_number: String
            let hospital_phone: String
            let street: String
            let city: String
            let state: String
            let zip_code: String
            let phone: String
            let email: String
            let status: String
            let last_modified: String
            let last_modified_by: String
            let image_data: Data?
        }
        
        let hospitalData = HospitalUpdateData(
            name: hospital.name,
            admin_name: hospital.adminName,
            license_number: hospital.licenseNumber,
            hospital_phone: hospital.hospitalPhone,
            street: hospital.street,
            city: hospital.city,
            state: hospital.state,
            zip_code: hospital.zipCode,
            phone: hospital.phone,
            email: hospital.email,
            status: hospital.status.rawValue,
            last_modified: dateFormatter.string(from: now),
            last_modified_by: hospital.lastModifiedBy,
            image_data: hospital.imageData
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
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let adminName = data["admin_name"] as? String,
            let licenseNumber = data["license_number"] as? String,
            let hospitalPhone = data["hospital_phone"] as? String,
            let street = data["street"] as? String,
            let city = data["city"] as? String,
            let state = data["state"] as? String,
            let zipCode = data["zip_code"] as? String,
            let phone = data["phone"] as? String,
            let email = data["email"] as? String,
            let statusString = data["status"] as? String,
            let registrationDateString = data["registration_date"] as? String,
            let lastModifiedString = data["last_modified"] as? String,
            let lastModifiedBy = data["last_modified_by"] as? String
        else {
            throw HospitalError.invalidData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        guard
            let registrationDate = dateFormatter.date(from: registrationDateString),
            let lastModified = dateFormatter.date(from: lastModifiedString),
            let status = HospitalStatus(rawValue: statusString)
        else {
            throw HospitalError.invalidData
        }
        
        let imageData = data["image_data"] as? Data
        
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
            phone: phone,
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