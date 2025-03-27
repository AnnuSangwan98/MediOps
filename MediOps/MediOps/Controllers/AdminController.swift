import Foundation

class AdminController {
    static let shared = AdminController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    private let hospitalController = HospitalController.shared
    
    private init() {}
    
    // MARK: - Hospital Admin Management
    
    /// Register a new hospital admin
    func registerHospitalAdmin(email: String, password: String, name: String, hospitalName: String) async throws -> (HospitalAdmin, String) {
        // 1. Register the base user
        let authResponse = try await userController.register(
            email: email,
            password: password,
            username: name,
            role: .hospitalAdmin
        )
        
        // 2. Create hospital admin record
        let adminId = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        let adminData: [String: String] = [
            "id": adminId,
            "user_id": authResponse.user.id,
            "name": name,
            "hospital_name": hospitalName,
            "created_at": createdAt,
            "updated_at": createdAt
        ]
        
        try await supabase.insert(into: "hospital_admins", data: adminData)
        
        // 3. Create associated hospital record
        let hospital = Hospital(
            id: Hospital.generateUniqueID(),
            name: hospitalName,
            adminName: name,
            licenseNumber: "", // Will be set later by super admin
            hospitalPhone: "", // Will be set later by super admin
            street: "",
            city: "",
            state: "",
            zipCode: "",
            phone: "", // Will be set later
            email: email,
            status: .pending,
            registrationDate: now,
            lastModified: now,
            lastModifiedBy: "System",
            imageData: nil
        )
        
        try await hospitalController.createHospital(hospital)
        
        // 4. Return hospital admin object and token
        let admin = HospitalAdmin(
            id: adminId,
            userId: authResponse.user.id,
            name: name,
            hospitalName: hospitalName,
            createdAt: now,
            updatedAt: now
        )
        
        return (admin, authResponse.token)
    }
    
    /// Get hospital admin by ID
    func getHospitalAdmin(id: String) async throws -> HospitalAdmin {
        let admins = try await supabase.select(
            from: "hospital_admins", 
            where: "id", 
            equals: id
        )
        
        guard let adminData = admins.first else {
            throw AdminError.adminNotFound
        }
        
        return try parseHospitalAdminData(adminData)
    }
    
    /// Get hospital admin by user ID
    func getHospitalAdminByUserId(userId: String) async throws -> HospitalAdmin {
        let admins = try await supabase.select(
            from: "hospital_admins", 
            where: "user_id", 
            equals: userId
        )
        
        guard let adminData = admins.first else {
            throw AdminError.adminNotFound
        }
        
        return try parseHospitalAdminData(adminData)
    }
    
    // MARK: - Doctor Management
    
    /// Register a new doctor
    func createDoctor(email: String, password: String, name: String, specialization: String, hospitalAdminId: String) async throws -> (Doctor, String) {
        // 1. Register the base user
        let authResponse = try await userController.register(
            email: email,
            password: password,
            username: name,
            role: .doctor
        )
        
        // 2. Create doctor record
        let doctorId = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        let doctorData: [String: String] = [
            "id": doctorId,
            "user_id": authResponse.user.id,
            "name": name,
            "specialization": specialization,
            "hospital_admin_id": hospitalAdminId,
            "created_at": createdAt,
            "updated_at": createdAt
        ]
        
        try await supabase.insert(into: "doctors", data: doctorData)
        
        // 3. Return doctor object and token
        let doctor = Doctor(
            id: doctorId,
            userId: authResponse.user.id,
            name: name,
            specialization: specialization,
            hospitalAdminId: hospitalAdminId,
            createdAt: now,
            updatedAt: now
        )
        
        return (doctor, authResponse.token)
    }
    
    /// Get doctor by ID
    func getDoctor(id: String) async throws -> Doctor {
        let doctors = try await supabase.select(
            from: "doctors", 
            where: "id", 
            equals: id
        )
        
        guard let doctorData = doctors.first else {
            throw AdminError.doctorNotFound
        }
        
        return try parseDoctorData(doctorData)
    }
    
    /// Get doctors by hospital admin ID
    func getDoctorsByHospitalAdmin(hospitalAdminId: String) async throws -> [Doctor] {
        let doctors = try await supabase.select(
            from: "doctors", 
            where: "hospital_admin_id", 
            equals: hospitalAdminId
        )
        
        return try doctors.map { try parseDoctorData($0) }
    }
    
    // MARK: - Lab Admin Management
    
    /// Register a new lab admin (independent of users table)
    func createLabAdmin(email: String, password: String, name: String, labName: String, hospitalAdminId: String, contactNumber: String = "", department: String = "Pathology & Laboratory") async throws -> (LabAdmin, String) {
        // Generate a LAB-prefixed ID
        let labAdminId = "LAB" + String(format: "%03d", Int.random(in: 1...999))
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        // Create lab admin record directly (no user record)
        let labAdminData: [String: String] = [
            "id": labAdminId,
            "hospital_id": hospitalAdminId,
            "password": password,
            "name": name,
            "email": email,
            "contact_number": contactNumber,
            "department": department,
            "Address": "", // Default empty address
            "created_at": createdAt,
            "updated_at": createdAt
        ]
        
        try await supabase.insert(into: "lab_admins", data: labAdminData)
        
        // Return lab admin object with a dummy token
        let labAdmin = LabAdmin(
            id: labAdminId,
            hospitalId: hospitalAdminId,
            name: name,
            email: email,
            contactNumber: contactNumber,
            department: department,
            address: "",
            createdAt: now,
            updatedAt: now
        )
        
        return (labAdmin, "lab-admin-token") // Return a dummy token
    }
    
    /// Get lab admin by ID
    func getLabAdmin(id: String) async throws -> LabAdmin {
        let labAdmins = try await supabase.select(
            from: "lab_admins", 
            where: "id", 
            equals: id
        )
        
        guard let labAdminData = labAdmins.first else {
            throw AdminError.labAdminNotFound
        }
        
        return try parseLabAdminData(labAdminData)
    }
    
    /// Get lab admins by hospital admin ID
    func getLabAdmins(hospitalAdminId: String) async throws -> [LabAdmin] {
        let labAdmins = try await supabase.select(
            from: "lab_admins",
            where: "hospital_id",
            equals: hospitalAdminId
        )
        
        return try labAdmins.map { try parseLabAdminData($0) }
    }
    
    /// Update lab admin
    func updateLabAdmin(_ labAdmin: LabAdmin) async throws {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let updatedAt = dateFormatter.string(from: now)
        
        let labAdminData: [String: String] = [
            "name": labAdmin.name,
            "email": labAdmin.email,
            "contact_number": labAdmin.contactNumber,
            "department": labAdmin.department,
            "Address": labAdmin.address,
            "updated_at": updatedAt
        ]
        
        try await supabase.update(
            table: "lab_admins",
            data: labAdminData,
            where: "id",
            equals: labAdmin.id
        )
    }
    
    /// Delete lab admin
    func deleteLabAdmin(id: String) async throws {
        try await supabase.delete(
            from: "lab_admins",
            where: "id",
            equals: id
        )
    }
    
    // MARK: - Activity Management
    
    /// Create a new activity
    func createActivity(type: String, title: String, doctorId: String? = nil, labAdminId: String? = nil) async throws -> Activity {
        let activityId = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.string(from: now)
        
        // Create a base dictionary with required values
        var activityData: [String: String] = [
            "id": activityId,
            "type": type,
            "title": title,
            "timestamp": timestamp,
            "status": "pending"
        ]
        
        // Add optional values if present
        if let doctorId = doctorId {
            activityData["doctor_id"] = doctorId
        }
        
        if let labAdminId = labAdminId {
            activityData["lab_admin_id"] = labAdminId
        }
        
        try await supabase.insert(into: "activities", data: activityData)
        
        return Activity(
            id: activityId,
            type: type,
            title: title,
            timestamp: now,
            status: "pending",
            doctorId: doctorId,
            labAdminId: labAdminId
        )
    }
    
    /// Get activities by status
    func getActivities(status: String? = nil) async throws -> [Activity] {
        var activities: [[String: Any]]
        
        if let status = status {
            activities = try await supabase.select(
                from: "activities", 
                where: "status", 
                equals: status
            )
        } else {
            activities = try await supabase.select(from: "activities")
        }
        
        return try activities.map { try parseActivityData($0) }
    }
    
    /// Update activity status
    func updateActivityStatus(id: String, status: String) async throws -> Activity {
        let updateData: [String: String] = [
            "status": status,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await supabase.update(
            table: "activities", 
            data: updateData, 
            where: "id", 
            equals: id
        )
        
        // Get updated activity
        let activities = try await supabase.select(
            from: "activities", 
            where: "id", 
            equals: id
        )
        
        guard let activityData = activities.first else {
            throw AdminError.activityNotFound
        }
        
        return try parseActivityData(activityData)
    }
    
    // MARK: - Hospital Management
    
    /// Create a new hospital
    func createHospital(name: String, adminName: String, licenseNumber: String, 
                       street: String, city: String, state: String, zipCode: String,
                       phone: String, email: String) async throws -> Hospital {
        let now = Date()
        let createdAt = ISO8601DateFormatter().string(from: now)
        
        // Generate a unique hospital ID 
        let hospitalId = "HOS\(UUID().uuidString.prefix(8))"
        
        let hospitalData: [String: String] = [
            "id": hospitalId,
            "name": name,
            "admin_name": adminName,
            "license_number": licenseNumber,
            "street": street,
            "city": city,
            "state": state,
            "zip_code": zipCode,
            "phone": phone,
            "email": email,
            "status": "active",
            "registration_date": createdAt,
            "last_modified": createdAt,
            "last_modified_by": "system" // This should ideally be the current admin's name
        ]
        
        try await supabase.insert(into: "hospitals", data: hospitalData)
        
        return Hospital(
            id: hospitalId,
            name: name,
            adminName: adminName,
            licenseNumber: licenseNumber,
            hospitalPhone: phone,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode, 
            phone: phone,
            email: email,
            status: .active,
            registrationDate: now,
            lastModified: now,
            lastModifiedBy: "system",
            imageData: nil
        )
    }
    
    /// Get hospital by ID
    func getHospital(id: String) async throws -> Hospital {
        let hospitals = try await supabase.select(
            from: "hospitals", 
            where: "id", 
            equals: id
        )
        
        guard let hospitalData = hospitals.first else {
            throw AdminError.hospitalNotFound
        }
        
        return try parseHospitalData(hospitalData)
    }
    
    /// Get all hospitals
    func getAllHospitals() async throws -> [Hospital] {
        let hospitals = try await supabase.select(from: "hospitals")
        return try hospitals.map { try parseHospitalData($0) }
    }
    
    // MARK: - Helper Methods
    
    private func parseHospitalAdminData(_ data: [String: Any]) throws -> HospitalAdmin {
        guard
            let id = data["id"] as? String,
            let userId = data["user_id"] as? String,
            let name = data["name"] as? String,
            let hospitalName = data["hospital_name"] as? String,
            let createdAtString = data["created_at"] as? String,
            let updatedAtString = data["updated_at"] as? String
        else {
            throw AdminError.invalidData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        guard
            let createdAt = dateFormatter.date(from: createdAtString),
            let updatedAt = dateFormatter.date(from: updatedAtString)
        else {
            throw AdminError.invalidData
        }
        
        return HospitalAdmin(
            id: id,
            userId: userId,
            name: name,
            hospitalName: hospitalName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func parseDoctorData(_ data: [String: Any]) throws -> Doctor {
        guard
            let id = data["id"] as? String,
            let userId = data["user_id"] as? String,
            let name = data["name"] as? String,
            let specialization = data["specialization"] as? String,
            let hospitalAdminId = data["hospital_admin_id"] as? String,
            let createdAtString = data["created_at"] as? String,
            let updatedAtString = data["updated_at"] as? String
        else {
            throw AdminError.invalidData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        guard
            let createdAt = dateFormatter.date(from: createdAtString),
            let updatedAt = dateFormatter.date(from: updatedAtString)
        else {
            throw AdminError.invalidData
        }
        
        return Doctor(
            id: id,
            userId: userId,
            name: name,
            specialization: specialization,
            hospitalAdminId: hospitalAdminId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func parseLabAdminData(_ data: [String: Any]) throws -> LabAdmin {
        // Print the raw data for debugging
        print("PARSE LAB ADMIN: Raw data: \(data)")
        
        // Check for required fields
        guard let id = data["id"] as? String else {
            print("PARSE LAB ADMIN ERROR: Missing id field")
            throw AdminError.invalidData
        }
        
        guard let hospitalId = data["hospital_id"] as? String else {
            print("PARSE LAB ADMIN ERROR: Missing hospital_id field")
            throw AdminError.invalidData
        }
        
        guard let name = data["name"] as? String else {
            print("PARSE LAB ADMIN ERROR: Missing name field")
            throw AdminError.invalidData
        }
        
        guard let email = data["email"] as? String else {
            print("PARSE LAB ADMIN ERROR: Missing email field")
            throw AdminError.invalidData
        }
        
        // Department might be stored as lab_name in some records
        let department: String
        if let dept = data["department"] as? String {
            department = dept
        } else if let labName = data["lab_name"] as? String {
            department = labName
        } else {
            print("PARSE LAB ADMIN ERROR: Missing department/lab_name field")
            department = "Unknown Department" // Provide a default value
        }
        
        // Handle date fields with better error recovery
        let dateFormatter = ISO8601DateFormatter()
        let now = Date() // Default to current date if parsing fails
        
        var createdAt = now
        if let createdAtString = data["created_at"] as? String {
            createdAt = dateFormatter.date(from: createdAtString) ?? now
        } else {
            print("PARSE LAB ADMIN WARNING: Missing created_at field, using current date")
        }
        
        var updatedAt = now
        if let updatedAtString = data["updated_at"] as? String {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? now
        } else {
            print("PARSE LAB ADMIN WARNING: Missing updated_at field, using current date")
        }
        
        // Optional fields
        let contactNumber = data["contact_number"] as? String ?? ""
        
        // Handle address field which might have inconsistent capitalization
        let address: String
        if let addr = data["Address"] as? String {
            address = addr
        } else if let addr = data["address"] as? String {
            address = addr
        } else {
            address = ""
        }
        
        return LabAdmin(
            id: id,
            hospitalId: hospitalId,
            name: name,
            email: email,
            contactNumber: contactNumber,
            department: department,
            address: address,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func parseActivityData(_ data: [String: Any]) throws -> Activity {
        guard
            let id = data["id"] as? String,
            let type = data["type"] as? String,
            let title = data["title"] as? String,
            let timestampString = data["timestamp"] as? String,
            let status = data["status"] as? String
        else {
            throw AdminError.invalidActivityData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: timestampString) ?? Date()
        
        let doctorId = data["doctor_id"] as? String
        let labAdminId = data["lab_admin_id"] as? String
        
        return Activity(
            id: id,
            type: type,
            title: title,
            timestamp: timestamp,
            status: status,
            doctorId: doctorId,
            labAdminId: labAdminId
        )
    }
    
    private func parseHospitalData(_ data: [String: Any]) throws -> Hospital {
        guard 
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let adminName = data["admin_name"] as? String,
            let licenseNumber = data["license_number"] as? String,
            let street = data["street"] as? String,
            let city = data["city"] as? String,
            let state = data["state"] as? String,
            let zipCode = data["zip_code"] as? String,
            let phone = data["phone"] as? String,
            let email = data["email"] as? String,
            let statusString = data["status"] as? String
        else {
            throw AdminError.invalidData
        }
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        
        let registrationDateString = data["registration_date"] as? String ?? ""
        let registrationDate = dateFormatter.date(from: registrationDateString) ?? Date()
        
        let lastModifiedString = data["last_modified"] as? String ?? ""
        let lastModified = dateFormatter.date(from: lastModifiedString) ?? Date()
        
        let lastModifiedBy = data["last_modified_by"] as? String ?? "unknown"
        
        // Convert status string to enum
        guard let status = HospitalStatus(rawValue: statusString) else {
            throw AdminError.invalidData
        }
        
        return Hospital(
            id: id,
            name: name,
            adminName: adminName,
            licenseNumber: licenseNumber,
            hospitalPhone: phone,
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
            imageData: nil
        )
    }
}

// MARK: - Admin Errors
enum AdminError: Error, LocalizedError {
    case adminNotFound
    case doctorNotFound
    case labAdminNotFound
    case activityNotFound
    case invalidAdminData
    case invalidDoctorData
    case invalidLabAdminData
    case invalidActivityData
    case hospitalNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .adminNotFound:
            return "Hospital admin not found"
        case .doctorNotFound:
            return "Doctor not found"
        case .labAdminNotFound:
            return "Lab admin not found"
        case .activityNotFound:
            return "Activity not found"
        case .invalidAdminData:
            return "Invalid hospital admin data"
        case .invalidDoctorData:
            return "Invalid doctor data"
        case .invalidLabAdminData:
            return "Invalid lab admin data"
        case .invalidActivityData:
            return "Invalid activity data"
        case .hospitalNotFound:
            return "Hospital not found"
        case .invalidData:
            return "Invalid data"
        }
    }
} 
