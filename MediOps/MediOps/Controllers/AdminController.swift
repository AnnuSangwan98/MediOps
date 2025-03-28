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
        print("GET HOSPITAL ADMIN: Finding hospital admin for user ID: \(userId)")
        
        // First try to find the admin in the hospital_admins table
        let admins = try await supabase.select(
            from: "hospital_admins", 
            where: "user_id", 
            equals: userId
        )
        
        // If not found by user_id, try using the email from the users table
        if admins.isEmpty {
            let users = try await supabase.select(
                from: "users",
                where: "id",
                equals: userId
            )
            
            guard let user = users.first, let email = user["email"] as? String else {
                print("GET HOSPITAL ADMIN: User not found with ID: \(userId)")
                throw AdminError.adminNotFound
            }
            
            // Now try to find admin by email
            let adminsByEmail = try await supabase.select(
                from: "hospital_admins",
                where: "email",
                equals: email
            )
            
            guard let adminData = adminsByEmail.first else {
                print("GET HOSPITAL ADMIN: Admin not found with email: \(email)")
                throw AdminError.adminNotFound
            }
            
            print("GET HOSPITAL ADMIN: Found admin via email")
            return try parseHospitalAdminData(adminData)
        }
        
        guard let adminData = admins.first else {
            print("GET HOSPITAL ADMIN: Admin not found")
            throw AdminError.adminNotFound
        }
        
        print("GET HOSPITAL ADMIN: Found admin via user_id")
        return try parseHospitalAdminData(adminData)
    }
    
    // MARK: - Doctor Management
    
    /// Register a new doctor
    func createDoctor(
        email: String,
        password: String,
        name: String,
        specialization: String,
        hospitalId: String,
        qualifications: [String],
        licenseNo: String,
        experience: Int,
        addressLine: String,
        state: String,
        city: String,
        pincode: String,
        contactNumber: String,
        emergencyContactNumber: String? = nil,
        doctorStatus: String = "active"
    ) async throws -> (Doctor, String) {
        // 1. Register the base user
        let authResponse = try await userController.register(
            email: email,
            password: password,
            username: name,
            role: .doctor
        )
        
        // 2. Generate a doctor ID with DOC prefix
        let doctorId = "DOC" + String(format: "%03d", Int.random(in: 1...999))
        
        // 3. Prepare creation timestamp
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        // 4. Create an Encodable struct for doctor data
        struct DoctorData: Encodable {
            let id: String
            let name: String
            let specialization: String
            let hospital_id: String
            let qualifications: [String]
            let license_no: String
            let experience: Int
            let address_line: String
            let state: String
            let city: String
            let pincode: String
            let email: String
            let doctor_status: String
            let password: String
            let created_at: String
            let updated_at: String
            var contact_number: String?
            var emergency_contact_number: String?
        }
        
        // Create the doctor data
        var doctorData = DoctorData(
            id: doctorId,
            name: name,
            specialization: specialization,
            hospital_id: hospitalId,
            qualifications: qualifications,
            license_no: licenseNo,
            experience: experience,
            address_line: addressLine,
            state: state,
            city: city,
            pincode: pincode,
            email: email,
            doctor_status: doctorStatus,
            password: password,
            created_at: createdAt,
            updated_at: createdAt,
            contact_number: nil,
            emergency_contact_number: nil
        )
        
        // Add optional fields only if they have values
        if !contactNumber.isEmpty {
            doctorData.contact_number = contactNumber
        }
        
        if let emergencyNumber = emergencyContactNumber, !emergencyNumber.isEmpty {
            doctorData.emergency_contact_number = emergencyNumber
        }
        
        // Print the final structure for debugging
        print("DOCTOR DATA: Attempting to insert doctor with ID: \(doctorId)")
        print("DOCTOR DATA: Hospital ID: \(hospitalId)")
        
        try await supabase.insert(into: "doctors", data: doctorData)
        
        // 5. Return doctor object and token
        let doctor = Doctor(
            id: doctorId,
            userId: nil, // User ID is not stored in the doctors table
            name: name,
            specialization: specialization,
            hospitalId: hospitalId,
            qualifications: qualifications,
            licenseNo: licenseNo,
            experience: experience,
            addressLine: addressLine,
            state: state,
            city: city,
            pincode: pincode,
            email: email,
            contactNumber: contactNumber.isEmpty ? nil : contactNumber,
            emergencyContactNumber: emergencyContactNumber,
            doctorStatus: doctorStatus,
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
        print("GET DOCTORS: Fetching doctors for hospital ID: \(hospitalAdminId)")
        
        do {
            let doctors = try await supabase.select(
                from: "doctors", 
                where: "hospital_id", 
                equals: hospitalAdminId
            )
            
            print("GET DOCTORS: Retrieved \(doctors.count) doctor records from database")
            
            var parsedDoctors: [Doctor] = []
            for (index, doctorData) in doctors.enumerated() {
                do {
                    let doctor = try parseDoctorData(doctorData)
                    parsedDoctors.append(doctor)
                    print("GET DOCTORS: Successfully parsed doctor \(index+1) of \(doctors.count): \(doctor.id)")
                } catch {
                    print("GET DOCTORS WARNING: Failed to parse doctor at index \(index): \(error.localizedDescription)")
                    // Continue with other records
                }
            }
            
            print("GET DOCTORS: Successfully parsed \(parsedDoctors.count) out of \(doctors.count) doctor records")
            return parsedDoctors
            
        } catch {
            print("GET DOCTORS ERROR: Failed to fetch doctors from database: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update doctor information
    func updateDoctor(
        doctorId: String,
        name: String,
        specialization: String,
        qualifications: [String],
        licenseNo: String,
        experience: Int,
        addressLine: String,
        email: String,
        contactNumber: String
    ) async throws {
        print("UPDATE DOCTOR: Updating doctor with ID: \(doctorId)")
        
        // Create an Encodable struct for doctor data
        struct DoctorUpdateData: Encodable {
            let name: String
            let specialization: String
            let qualifications: [String]
            let license_no: String
            let experience: Int
            let address_line: String
            let email: String
            let contact_number: String
            let updated_at: String
        }
        
        // Prepare the update data with fields that can be updated
        let doctorData = DoctorUpdateData(
            name: name,
            specialization: specialization,
            qualifications: qualifications,
            license_no: licenseNo,
            experience: experience,
            address_line: addressLine,
            email: email,
            contact_number: contactNumber,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        // Update the doctor record in Supabase
        try await supabase.update(
            table: "doctors",
            data: doctorData,
            where: "id",
            equals: doctorId
        )
        
        print("UPDATE DOCTOR: Successfully updated doctor with ID: \(doctorId)")
    }
    
    /// Delete a doctor
    func deleteDoctor(id: String) async throws {
        print("DELETE DOCTOR: Attempting to delete doctor with ID: \(id)")
        
        // First try direct deletion (most reliable)
        do {
            print("DELETE DOCTOR: Attempting full deletion first")
            try await supabase.delete(
                from: "doctors",
                where: "id",
                equals: id
            )
            print("DELETE DOCTOR: Successfully deleted doctor with ID: \(id)")
            return // Exit if deletion was successful
        } catch {
            print("DELETE DOCTOR ERROR on full deletion: \(error.localizedDescription)")
            // If direct deletion fails, try status updates
        }
        
        // Create an Encodable struct for the status update
        struct DoctorStatusUpdate: Encodable {
            let doctor_status: String
            let updated_at: String
        }
        
        // Try various possible status values that might be allowed by the check constraint
        let possibleStatuses = ["inactive", "deleted", "disabled", "removed", "deactivated", "closed"]
        
        for status in possibleStatuses {
            do {
                print("DELETE DOCTOR: Trying status update to '\(status)'")
                let doctorData = DoctorStatusUpdate(
                    doctor_status: status,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                try await supabase.update(
                    table: "doctors",
                    data: doctorData,
                    where: "id",
                    equals: id
                )
                
                print("DELETE DOCTOR: Successfully updated doctor status to '\(status)' with ID: \(id)")
                return // Exit the function if this status update works
            } catch {
                print("DELETE DOCTOR: Status '\(status)' update failed: \(error.localizedDescription)")
                // Continue trying other statuses
            }
        }
        
        // If we reach here, none of our approaches worked
        throw AdminError.doctorDeleteFailed
    }
    
    // MARK: - Lab Admin Management
    
    /// Register a new lab admin (independent of users table)
    func createLabAdmin(email: String, password: String, name: String, labName: String, hospitalAdminId: String, contactNumber: String = "", department: String = "Pathology & Laboratory") async throws -> (LabAdmin, String) {
        print("CREATE LAB ADMIN: Creating lab admin with hospital ID: \(hospitalAdminId)")
        
        // Verify that the hospital admin exists and get their correct ID
        var verifiedHospitalId = hospitalAdminId
        
        // Try to verify hospital admin exists
        do {
            let hospitalAdmin = try await getHospitalAdmin(id: hospitalAdminId)
            // Use the verified hospital_id from the admin record
            verifiedHospitalId = hospitalAdmin.id
            print("CREATE LAB ADMIN: Verified hospital admin ID: \(verifiedHospitalId)")
        } catch {
            print("CREATE LAB ADMIN WARNING: Could not verify hospital admin ID: \(error.localizedDescription)")
            // Continue with the provided ID, but log the warning
        }
        
        // Generate a LAB-prefixed ID
        let labAdminId = "LAB" + String(format: "%03d", Int.random(in: 1...999))
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        
        // Create lab admin record directly (no user record)
        let labAdminData: [String: String] = [
            "id": labAdminId,
            "hospital_id": verifiedHospitalId,
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
            hospitalId: verifiedHospitalId,
            name: name,
            email: email,
            contactNumber: contactNumber,
            department: department,
            address: "",
            createdAt: now,
            updatedAt: now
        )
        
        print("CREATE LAB ADMIN: Successfully created lab admin with ID: \(labAdminId)")
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
        print("GET LAB ADMINS: Retrieving lab admins for hospital ID: \(hospitalAdminId)")
        
        // Verify that the hospital admin exists
        var verifiedHospitalId = hospitalAdminId
        
        // Try to verify hospital admin exists and get the correct ID
        do {
            let hospitalAdmin = try await getHospitalAdmin(id: hospitalAdminId)
            // Use the verified hospital_id from the admin record
            verifiedHospitalId = hospitalAdmin.id
            print("GET LAB ADMINS: Verified hospital admin ID: \(verifiedHospitalId)")
        } catch {
            print("GET LAB ADMINS WARNING: Could not verify hospital admin ID: \(error.localizedDescription)")
            // Continue with the provided ID, but log the warning
        }
        
        // Fetch lab admins with the verified ID
        let labAdmins = try await supabase.select(
            from: "lab_admins",
            where: "hospital_id",
            equals: verifiedHospitalId
        )
        
        print("GET LAB ADMINS: Found \(labAdmins.count) lab admins for hospital ID: \(verifiedHospitalId)")
        
        // If no lab admins are found, it's not necessarily an error, could just be an empty list
        if labAdmins.isEmpty {
            print("GET LAB ADMINS: No lab admins found for hospital ID: \(verifiedHospitalId)")
            return []
        }
        
        // Parse each lab admin record
        var parsedLabAdmins: [LabAdmin] = []
        for labAdminData in labAdmins {
            do {
                let labAdmin = try parseLabAdminData(labAdminData)
                parsedLabAdmins.append(labAdmin)
            } catch {
                print("GET LAB ADMINS WARNING: Failed to parse lab admin: \(error.localizedDescription)")
                // Continue with other records
            }
        }
        
        return parsedLabAdmins
    }
    
    /// Update lab admin
    func updateLabAdmin(_ labAdmin: LabAdmin) async throws {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let updatedAt = dateFormatter.string(from: now)
        
        // Create an Encodable struct for lab admin updates
        struct LabAdminUpdateData: Encodable {
            let name: String
            let email: String
            let contact_number: String
            let department: String
            let Address: String
            let updated_at: String
        }
        
        let labAdminData = LabAdminUpdateData(
            name: labAdmin.name,
            email: labAdmin.email,
            contact_number: labAdmin.contactNumber,
            department: labAdmin.department,
            Address: labAdmin.address,
            updated_at: updatedAt
        )
        
        try await supabase.update(
            table: "lab_admins",
            data: labAdminData,
            where: "id",
            equals: labAdmin.id
        )
    }
    
    /// Delete lab admin
    func deleteLabAdmin(id: String) async throws {
        print("DELETE LAB ADMIN: Attempting to delete lab admin with ID: \(id)")
        
        // First try direct deletion
        do {
            try await supabase.delete(
                from: "lab_admins",
                where: "id",
                equals: id
            )
            print("DELETE LAB ADMIN: Successfully deleted lab admin with ID: \(id)")
            return
        } catch {
            print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
            
            // If there are foreign key constraints preventing deletion,
            // we could implement a soft delete by updating a status field
            // (if such a field exists in the lab_admins table)
            
            // For now, just rethrow the error
            throw error
        }
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
        print("PARSE HOSPITAL ADMIN: Raw data: \(data)")
        
        // The schema states that id and hospital_id should be the same
        var id: String
        var hospitalId: String
        var userId: String = ""
        
        // Check for id field
        if let adminId = data["id"] as? String, !adminId.isEmpty {
            id = adminId
        } else {
            print("PARSE HOSPITAL ADMIN ERROR: Missing id field")
            throw AdminError.invalidData
        }
        
        // Check for hospital_id field - according to the schema, this should match the id
        if let hId = data["hospital_id"] as? String, !hId.isEmpty {
            hospitalId = hId
            
            // Validate that id and hospital_id match as per the schema constraint
            if hospitalId != id {
                print("PARSE HOSPITAL ADMIN WARNING: hospital_id (\(hospitalId)) doesn't match id (\(id))")
                // Use id as the definitive value to satisfy constraint
                hospitalId = id
            }
        } else {
            // If hospital_id is missing, use id as per schema constraint
            print("PARSE HOSPITAL ADMIN WARNING: Missing hospital_id field, using id instead")
            hospitalId = id
        }
        
        // Get user_id if available
        if let uId = data["user_id"] as? String {
            userId = uId
        }
        
        // Name field (admin_name in schema)
        let name: String
        if let adminName = data["admin_name"] as? String, !adminName.isEmpty {
            name = adminName
        } else if let userName = data["name"] as? String, !userName.isEmpty {
            name = userName
        } else {
            print("PARSE HOSPITAL ADMIN ERROR: Missing name field")
            throw AdminError.invalidData
        }
        
        // Email field
        guard let email = data["email"] as? String, !email.isEmpty else {
            print("PARSE HOSPITAL ADMIN ERROR: Missing email field")
            throw AdminError.invalidData
        }
        
        // Hospital name field - this could be missing in the schema
        var hospitalName = "Unknown Hospital"
        if let hName = data["hospital_name"] as? String, !hName.isEmpty {
            hospitalName = hName
        }
        
        // Handle date fields with better error recovery
        let dateFormatter = ISO8601DateFormatter()
        let now = Date() // Default to current date if parsing fails
        
        var createdAt = now
        if let createdAtString = data["created_at"] as? String {
            createdAt = dateFormatter.date(from: createdAtString) ?? now
        } else {
            print("PARSE HOSPITAL ADMIN WARNING: Missing created_at field, using current date")
        }
        
        var updatedAt = now
        if let updatedAtString = data["updated_at"] as? String {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? now
        } else {
            print("PARSE HOSPITAL ADMIN WARNING: Missing updated_at field, using current date")
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
        print("PARSE DOCTOR: Raw data: \(data)")
        
        // Required fields with fallbacks for more resilience
        guard let id = data["id"] as? String else {
            print("PARSE DOCTOR ERROR: Missing id field")
            throw AdminError.invalidData
        }
        
        // Optional user_id
        let userId = data["user_id"] as? String
                
        guard let name = data["name"] as? String else {
            print("PARSE DOCTOR ERROR: Missing name field")
            throw AdminError.invalidData
        }
        
        guard let specialization = data["specialization"] as? String else {
            print("PARSE DOCTOR ERROR: Missing specialization field")
            throw AdminError.invalidData
        }
        
        guard let hospitalId = data["hospital_id"] as? String else {
            print("PARSE DOCTOR ERROR: Missing hospital_id field")
            throw AdminError.invalidData
        }
        
        // Handle qualifications with fallback
        let qualifications: [String]
        if let quals = data["qualifications"] as? [String], !quals.isEmpty {
            qualifications = quals
        } else {
            print("PARSE DOCTOR WARNING: Missing or invalid qualifications field, using default")
            qualifications = ["MBBS"]
        }
        
        // Handle license with fallback
        let licenseNo: String
        if let license = data["license_no"] as? String, !license.isEmpty {
            licenseNo = license
        } else {
            print("PARSE DOCTOR WARNING: Missing license_no field, using default")
            licenseNo = "AB12345"
        }
        
        // Handle experience with fallback
        let experience: Int
        if let exp = data["experience"] as? Int {
            experience = exp
        } else if let expString = data["experience"] as? String, let exp = Int(expString) {
            experience = exp
        } else {
            print("PARSE DOCTOR WARNING: Missing or invalid experience field, using default")
            experience = 0
        }
        
        // Handle address fields with fallbacks
        let addressLine = data["address_line"] as? String ?? "No Address"
        let state = data["state"] as? String ?? "Unknown State"
        let city = data["city"] as? String ?? "Unknown City"
        let pincode = data["pincode"] as? String ?? "000000"
        
        // Handle email with fallback
        let email = data["email"] as? String ?? "unknown@example.com"
        
        // Handle doctor status with fallback
        let doctorStatus = data["doctor_status"] as? String ?? "active"
        
        // Optional fields
        let contactNumber = data["contact_number"] as? String
        let emergencyContactNumber = data["emergency_contact_number"] as? String
        
        // Handle date fields with fallback
        let dateFormatter = ISO8601DateFormatter()
        let now = Date() // Default to current date if parsing fails
        
        var createdAt = now
        if let createdAtString = data["created_at"] as? String {
            createdAt = dateFormatter.date(from: createdAtString) ?? now
        }
        
        var updatedAt = now
        if let updatedAtString = data["updated_at"] as? String {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? now
        }
        
        print("PARSE DOCTOR: Successfully parsed doctor with ID: \(id)")
        
        return Doctor(
            id: id,
            userId: userId,
            name: name,
            specialization: specialization,
            hospitalId: hospitalId,
            qualifications: qualifications,
            licenseNo: licenseNo,
            experience: experience,
            addressLine: addressLine,
            state: state,
            city: city,
            pincode: pincode,
            email: email,
            contactNumber: contactNumber,
            emergencyContactNumber: emergencyContactNumber,
            doctorStatus: doctorStatus,
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
    case doctorDeleteFailed
    
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
        case .doctorDeleteFailed:
            return "Failed to delete doctor"
        }
    }
} 
