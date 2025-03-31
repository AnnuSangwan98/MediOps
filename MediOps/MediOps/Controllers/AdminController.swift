import Foundation

class AdminController {
    static let shared = AdminController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    private let hospitalController = HospitalController.shared
    
    // Add accessor properties for supabase settings
    var supabaseURL: URL { 
        return supabase.supabaseURL 
    }
    
    var supabaseAnonKey: String { 
        return supabase.supabaseAnonKey 
    }
    
    // Create Encodable struct exactly matching the database schema
    private struct DoctorAvailabilityRecord: Encodable {
        let doctor_id: String
        let hospital_id: String
        let date: String
        let slot_time: String
        let slot_end_time: String
        let max_normal_patients: Int
        let max_premium_patients: Int
        let total_bookings: Int
    }
    
    // Create Encodable struct for the new efficient doctor availability table
    private struct DoctorAvailabilityEfficientRecord: Encodable {
        let doctor_id: String
        let hospital_id: String
        let weekly_schedule: [String: [TimeSlotJSON]]
        let effective_from: String
        let effective_until: String?
        let max_normal_patients: Int
        let max_premium_patients: Int
        
        // Custom encoding to handle the weekly_schedule JSON structure
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(doctor_id, forKey: .doctor_id)
            try container.encode(hospital_id, forKey: .hospital_id)
            try container.encode(effective_from, forKey: .effective_from)
            try container.encode(effective_until, forKey: .effective_until)
            try container.encode(max_normal_patients, forKey: .max_normal_patients)
            try container.encode(max_premium_patients, forKey: .max_premium_patients)
            
            // Create a nested container for the weekly schedule
            var scheduleContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .weekly_schedule)
            
            // For each day in the schedule, encode the slots array
            for (day, slots) in weekly_schedule {
                let dayKey = DynamicCodingKey(stringValue: day)
                try scheduleContainer.encode(slots, forKey: dayKey)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case doctor_id
            case hospital_id
            case weekly_schedule
            case effective_from
            case effective_until
            case max_normal_patients
            case max_premium_patients
        }
        
        // Dynamic coding key to handle string-based keys
        private struct DynamicCodingKey: CodingKey {
            var stringValue: String
            var intValue: Int?
            
            init(stringValue: String) {
                self.stringValue = stringValue
                self.intValue = nil
            }
            
            init?(intValue: Int) {
                self.stringValue = "\(intValue)"
                self.intValue = intValue
            }
        }
    }
    
    // JSON-encodable struct for time slot
    private struct TimeSlotJSON: Encodable {
        let start: String
        let end: String
        let available: Bool
        
        // Add custom encoding to ensure proper JSON serialization
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)
            try container.encode(available, forKey: .available)
        }
        
        enum CodingKeys: String, CodingKey {
            case start
            case end
            case available
        }
    }
    
    // Structure for time slot
    private struct TimeSlot: Encodable {
        let start: String
        let end: String
        let available: Bool
        
        init(start: String, end: String, available: Bool = true) {
            self.start = start
            self.end = end
            self.available = available
        }
        
        // Convert to JSON-friendly format
        func toJSON() -> TimeSlotJSON {
            return TimeSlotJSON(start: start, end: end, available: available)
        }
    }
    
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
            "admin_name": name,
            "hospital_name": hospitalName,
            "email": email,
            "contact_number": "",
            "street": "",
            "city": "",
            "state": "",
            "pincode": "",
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
            updatedAt: now,
            email: email,
            contact_number: "",
            street: "",
            city: "",
            state: "",
            pincode: ""
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
        
        // 5. Create initial empty availability schedule for the doctor
        do {
            // Initialize empty schedule for all days
            let emptySchedule: [String: [TimeSlot]] = [
                "monday": [],
                "tuesday": [],
                "wednesday": [],
                "thursday": [],
                "friday": [],
                "saturday": [],
                "sunday": []
            ]
            
            // Convert empty schedule to JSON format
            let jsonSchedule = convertToJsonSchedule(emptySchedule)
            
            // Create dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let effectiveFrom = dateFormatter.string(from: now)
            
            // Create the availability record
            let record = DoctorAvailabilityEfficientRecord(
                doctor_id: doctorId,
                hospital_id: hospitalId,
                weekly_schedule: jsonSchedule,
                effective_from: effectiveFrom,
                effective_until: nil,
                max_normal_patients: 6,
                max_premium_patients: 2
            )
            
            print("🔄 Creating initial empty availability schedule for new doctor \(doctorId)")
            
            // Save to database using Supabase
            do {
                // Try direct insertion which provides better error handling
                print("🔄 Attempting direct insertion for better error handling")
                await insertDoctorScheduleDirectly(record: record)
            } catch let error as SupabaseError {
                print("❌ Supabase error: \(error.localizedDescription)")
                print("🔄 Trying alternative insertion methods")
                await insertScheduleWithFunction(record: record)
            } catch {
                print("❌ Failed to insert schedule: \(error.localizedDescription)")
                print("❌ Error type: \(type(of: error))")
                print("🔄 Trying alternative insertion methods")
                await insertScheduleWithFunction(record: record)
            }
        } catch {
            print("⚠️ Could not create initial availability schedule: \(error.localizedDescription)")
            print("⚠️ Will continue with doctor creation, availability can be added later")
            // Don't throw here - we want the doctor creation to succeed even if availability fails
        }
        
        // 6. Return doctor object and token
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
        print("===== PARSE HOSPITAL ADMIN =====")
        print("Raw data: \(data)")
        
        // Check for id
        if let id = data["id"] as? String {
            print("ID: \(id)")
        } else {
            print("ERROR: Missing id field")
        }
        
        // Check for hospital_id
        if let hospitalId = data["hospital_id"] as? String {
            print("Hospital ID: \(hospitalId)")
        } else {
            print("ERROR: Missing hospital_id field")
        }
        
        // Check for admin_name
        if let adminName = data["admin_name"] as? String {
            print("Admin Name: \(adminName)")
        } else {
            print("ERROR: Missing admin_name field")
        }
        
        // Check for email
        if let email = data["email"] as? String {
            print("Email: \(email)")
        } else {
            print("ERROR: Missing email field")
        }
        
        // Check date fields
        if let createdAtString = data["created_at"] as? String {
            print("Created At: \(createdAtString)")
        } else {
            print("ERROR: Missing created_at field")
        }
        
        if let updatedAtString = data["updated_at"] as? String {
            print("Updated At: \(updatedAtString)")
        } else {
            print("ERROR: Missing updated_at field")
        }
        
        // Required fields
        guard let id = data["id"] as? String,
              let hospitalId = data["hospital_id"] as? String else {
            print("CRITICAL ERROR: Missing id or hospital_id fields")
            throw AdminError.invalidData
        }
        
        guard let adminName = data["admin_name"] as? String else {
            print("CRITICAL ERROR: Missing admin_name field")
            throw AdminError.invalidData
        }
        
        guard let email = data["email"] as? String else {
            print("CRITICAL ERROR: Missing email field")
            throw AdminError.invalidData
        }
        
        // Handle date fields with maximum resilience
        var createdAt = Date()
        var updatedAt = Date()
        
        if let createdAtString = data["created_at"] as? String {
            // Try ISO8601 format first
            let isoFormatter = ISO8601DateFormatter()
            if let parsedDate = isoFormatter.date(from: createdAtString) {
                createdAt = parsedDate
            } else {
                // Try other formats
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let parsedDate = dateFormatter.date(from: createdAtString) {
                    createdAt = parsedDate
                } else {
                    // Try another format
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let parsedDate = dateFormatter.date(from: createdAtString) {
                        createdAt = parsedDate
                    } else {
                        print("WARNING: Could not parse created_at date, using current date")
                    }
                }
            }
        } else {
            print("WARNING: Missing created_at field, using current date")
        }
        
        if let updatedAtString = data["updated_at"] as? String {
            // Try ISO8601 format first
            let isoFormatter = ISO8601DateFormatter()
            if let parsedDate = isoFormatter.date(from: updatedAtString) {
                updatedAt = parsedDate
            } else {
                // Try other formats
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let parsedDate = dateFormatter.date(from: updatedAtString) {
                    updatedAt = parsedDate
                } else {
                    // Try another format
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let parsedDate = dateFormatter.date(from: updatedAtString) {
                        updatedAt = parsedDate
                    } else {
                        print("WARNING: Could not parse updated_at date, using current date")
                    }
                }
            }
        } else {
            print("WARNING: Missing updated_at field, using current date")
        }
        
        // Verify id and hospital_id match (schema constraint)
        if id != hospitalId {
            print("WARNING: id (\(id)) and hospital_id (\(hospitalId)) don't match")
        }
        
        // Optional fields with defaults
        let userId = data["user_id"] as? String ?? ""
        print("User ID: \(userId)")
        
        let contactNumber = data["contact_number"] as? String ?? ""
        print("Contact Number: \(contactNumber)")
        
        let street = data["street"] as? String ?? ""
        print("Street: \(street)")
        
        let city = data["city"] as? String ?? ""
        print("City: \(city)")
        
        let state = data["state"] as? String ?? ""
        print("State: \(state)")
        
        let pincode = data["pincode"] as? String ?? ""
        print("Pincode: \(pincode)")
        
        // Parse hospital name - query the hospitals table to get the name if needed
        var hospitalName = "Unknown Hospital"
        if let hName = data["hospital_name"] as? String, !hName.isEmpty {
            hospitalName = hName
        }
        print("Hospital Name: \(hospitalName)")
        
        print("PARSE HOSPITAL ADMIN: Successfully parsed admin with id: \(id), name: \(adminName)")
        
        return HospitalAdmin(
            id: id,
            userId: userId,
            name: adminName,
            hospitalName: hospitalName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            email: email,
            contact_number: contactNumber,
            street: street,
            city: city,
            state: state,
            pincode: pincode
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
        guard let id = data["id"] as? String,
              let hospitalId = data["hospital_id"] as? String,
              let name = data["name"] as? String,
              let email = data["email"] as? String,
              let contactNumber = data["contact_number"] as? String,
              let department = data["department"] as? String,
              let createdAtString = data["created_at"] as? String,
              let updatedAtString = data["updated_at"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields in lab admin data"])
        }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let createdAt = dateFormatter.date(from: createdAtString),
              let updatedAt = dateFormatter.date(from: updatedAtString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
        }
        
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
    
    // Add doctor availability using the efficient JSON approach
    func addDoctorSchedule(doctorId: String, hospitalId: String, weekdaySlots: Set<String>, weekendSlots: Set<String>) async throws {
        print("🔍 Creating availability schedule for Doctor ID: \(doctorId) - Hospital ID: \(hospitalId)")
        
        // First, check if the doctor already has an availability record
        let existingRecords = try await supabase.select(
            from: "doctor_availability_efficient",
            where: "doctor_id",
            equals: doctorId
        )
        
        if !existingRecords.isEmpty {
            print("⚠️ Doctor already has an availability record. Using updateDoctorSchedule instead.")
            try await updateDoctorSchedule(doctorId: doctorId, hospitalId: hospitalId, weekdaySlots: weekdaySlots, weekendSlots: weekendSlots)
            return
        }
        
        // Initialize empty schedule for all days
        var weeklySchedule: [String: [TimeSlot]] = [
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": []
        ]
        
        // Parse and add weekday slots
        if !weekdaySlots.isEmpty {
            let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday"]
            
            // Add the same slots to all weekdays
            for slot in weekdaySlots {
                if let (startTime, endTime) = parseTimeSlot(slot) {
                    let timeSlot = TimeSlot(start: startTime, end: endTime)
                    
                    // Add to each weekday
                    for day in weekdays {
                        weeklySchedule[day]?.append(timeSlot)
                    }
                } else {
                    print("⚠️ Invalid time slot format: \(slot)")
                }
            }
        }
        
        // Parse and add weekend slots
        if !weekendSlots.isEmpty {
            let weekends = ["saturday", "sunday"]
            
            // Add the same slots to weekend days
            for slot in weekendSlots {
                if let (startTime, endTime) = parseTimeSlot(slot) {
                    let timeSlot = TimeSlot(start: startTime, end: endTime)
                    
                    // Add to each weekend day
                    for day in weekends {
                        weeklySchedule[day]?.append(timeSlot)
                    }
                } else {
                    print("⚠️ Invalid time slot format: \(slot)")
                }
            }
        }
        
        // Convert weekly schedule to JSON format
        let jsonSchedule = convertToJsonSchedule(weeklySchedule)
        
        // Create dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let effectiveFrom = dateFormatter.string(from: today)
        
        // Create the availability record
        let record = DoctorAvailabilityEfficientRecord(
            doctor_id: doctorId,
            hospital_id: hospitalId,
            weekly_schedule: jsonSchedule,
            effective_from: effectiveFrom,
            effective_until: nil,
            max_normal_patients: 6,
            max_premium_patients: 2
        )
        
        print("📅 Creating availability schedule starting from \(effectiveFrom)")
        print("📊 Doctor ID: \(record.doctor_id)")
        print("📊 Hospital ID: \(record.hospital_id)")
        
        // Log the schedule for debugging
        for (day, slots) in jsonSchedule {
            print("📊 \(day): \(slots.count) slots")
        }
        
        // Save to database using Supabase
        do {
            // Try direct insertion which provides better error handling
            print("🔄 Attempting direct insertion for better error handling")
            await insertDoctorScheduleDirectly(record: record)
        } catch let error as SupabaseError {
            print("❌ Supabase error: \(error.localizedDescription)")
            print("🔄 Trying alternative insertion methods")
            await insertScheduleWithFunction(record: record)
        } catch {
            print("❌ Failed to insert schedule: \(error.localizedDescription)")
            print("❌ Error type: \(type(of: error))")
            print("🔄 Trying alternative insertion methods")
            await insertScheduleWithFunction(record: record)
        }
    }
    
    // Helper function to parse time slot in format "HH:MM-HH:MM" or "HH:MM-HH:MM AM/PM"
    private func parseTimeSlot(_ slot: String) -> (String, String)? {
        // Remove AM/PM indicators for database storage
        let slotWithoutAMPM = slot.replacingOccurrences(of: " AM", with: "")
                                 .replacingOccurrences(of: " PM", with: "")
        
        let components = slotWithoutAMPM.split(separator: "-")
        guard components.count == 2 else { return nil }
        
        let startTimeString = String(components[0]).trimmingCharacters(in: .whitespaces)
        let endTimeString = String(components[1]).trimmingCharacters(in: .whitespaces)
        
        // Add seconds if not present
        let start = startTimeString.contains(":") && !startTimeString.contains(":00")
            ? startTimeString + ":00"
            : startTimeString
            
        let end = endTimeString.contains(":") && !endTimeString.contains(":00")
            ? endTimeString + ":00"
            : endTimeString
            
        return (start, end)
    }
    
    // Convert Swift dictionary to JSON format
    private func convertToJsonSchedule(_ schedule: [String: [TimeSlot]]) -> [String: [TimeSlotJSON]] {
        var jsonSchedule: [String: [TimeSlotJSON]] = [:]
        
        for (day, slots) in schedule {
            jsonSchedule[day] = slots.map { $0.toJSON() }
        }
        
        return jsonSchedule
    }
    
    // Method to convert schedule to a JSON-compatible dictionary
    private func scheduleToJsonDictionary(_ schedule: [String: [TimeSlotJSON]]) -> [String: [[String: Any]]] {
        var result: [String: [[String: Any]]] = [:]
        
        for (day, slots) in schedule {
            result[day] = slots.map { slot in
                return [
                    "start": slot.start,
                    "end": slot.end,
                    "available": slot.available
                ]
            }
        }
        
        return result
    }
    
    // Direct insertion method for the new format
    private func insertDoctorScheduleDirectly(record: DoctorAvailabilityEfficientRecord) async {
        print("🔄 Trying direct insertion of schedule to database")
        do {
            // Create direct URL request to Supabase using UPSERT (POST with Prefer: resolution=merge-duplicates)
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer") // This enables UPSERT behavior
            
            // Encode and send data
            let jsonData: Data
            do {
                // First convert the record to a dictionary with simple JSON types
                let recordDict: [String: Any] = [
                    "doctor_id": record.doctor_id,
                    "hospital_id": record.hospital_id,
                    "weekly_schedule": scheduleToJsonDictionary(record.weekly_schedule),
                    "effective_from": record.effective_from,
                    "effective_until": record.effective_until as Any,
                    "max_normal_patients": record.max_normal_patients,
                    "max_premium_patients": record.max_premium_patients
                ]
                
                // Now serialize the dictionary to JSON
                jsonData = try JSONSerialization.data(withJSONObject: recordDict)
            } catch {
                print("❌ JSON serialization error: \(error.localizedDescription)")
                print("❌ Error type: \(type(of: error))")
                await insertScheduleWithFunction(record: record)
                return
            }
            
            request.httpBody = jsonData
            
            // Log request for debugging
            print("📊 Request URL: \(url.absoluteString)")
            print("📊 Request payload: \(String(data: jsonData, encoding: .utf8) ?? "Unable to print payload")")
            
            // Send request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Direct insertion of schedule successful")
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Direct insertion failed with status code: \(httpResponse.statusCode)")
                print("❌ Response body: \(responseString)")
                
                // Try to interpret common error cases
                if responseString.contains("violates unique constraint") {
                    if responseString.contains("doctor_availability_efficient_doctor_id_key") {
                        print("🔍 Error details: Doctor ID already exists in the availability table")
                        // Try updating instead of inserting
                        await updateExistingSchedule(doctorId: record.doctor_id, newRecord: record)
                    } // Hospital ID unique constraint has been removed
                    // Keeping this code commented for reference
                    // else if responseString.contains("doctor_availability_efficient_hospital_id_key") {
                        // print("🔍 Error details: Hospital ID already exists in the availability table")
                    else if responseString.contains("unique_doctor_schedule") {
                        print("🔍 Error details: Combination of doctor_id, hospital_id, and effective_from already exists")
                    }
                } else if responseString.contains("violates foreign key constraint") {
                    if responseString.contains("doctor_availability_efficient_doctor_id_fkey") {
                        print("🔍 Error details: The doctor_id does not exist in the doctors table")
                    } else if responseString.contains("doctor_availability_efficient_hospital_id_fkey") {
                        print("🔍 Error details: The hospital_id does not exist in the hospitals table")
                    }
                }
                
                // Try database function as a fallback
                await insertScheduleWithFunction(record: record)
            }
        } catch {
            print("❌ Direct insertion error: \(error.localizedDescription)")
            print("❌ Error type: \(type(of: error))")
            await insertScheduleWithFunction(record: record)
        }
    }
    
    // Insert using the database function
    private func insertScheduleWithFunction(record: DoctorAvailabilityEfficientRecord) async {
        print("🔄 Attempting to insert schedule using database function")
        
        // First check if a record already exists
        do {
            let existingRecords = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: record.doctor_id
            )
            
            if !existingRecords.isEmpty {
                print("🔍 Found existing availability record. Updating instead of inserting.")
                
                guard let existingRecord = existingRecords.first,
                      let recordId = existingRecord["id"] as? Int else {
                    print("❌ Failed to get existing record ID")
                    return
                }
                
                // Try to update existing record
                let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient?id=eq.\(recordId)")!
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                
                // Create just the fields we want to update
                let updateDict: [String: Any] = [
                    "weekly_schedule": record.weekly_schedule,
                    "max_normal_patients": record.max_normal_patients,
                    "max_premium_patients": record.max_premium_patients,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                // Serialize to JSON
                let jsonData = try JSONSerialization.data(withJSONObject: updateDict)
                request.httpBody = jsonData
                
                print("📊 Update URL: \(url.absoluteString)")
                print("📊 Update data: \(String(data: jsonData, encoding: .utf8) ?? "Unable to print payload")")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    return
                }
                
                print("📊 Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ Successfully updated availability record")
                    return
                } else {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                    print("❌ Failed to update: \(responseString)")
                    // Continue to function call as last resort
                }
            }
            
            // If no record exists or update failed, use the function call
            await callDatabaseFunction(record: record)
        } catch {
            print("❌ Error checking for existing records: \(error.localizedDescription)")
            // Try function call as fallback
            await callDatabaseFunction(record: record)
        }
    }
    
    // Call the database function as last resort
    private func callDatabaseFunction(record: DoctorAvailabilityEfficientRecord) async {
        print("🔄 Calling database function to insert/update schedule")
        
        do {
            // Create SQL function URL
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/rpc/set_doctor_weekly_schedule")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            // Create an encodable struct for function parameters
            struct FunctionParams: Encodable {
                let p_doctor_id: String
                let p_hospital_id: String
                let p_weekly_schedule: [String: [TimeSlotJSON]]
                let p_effective_from: String
                let p_effective_until: String?
                let p_max_normal: Int
                let p_max_premium: Int
            }
            
            // Create parameters as a dictionary for safer JSON serialization
            let paramsDict: [String: Any] = [
                "p_doctor_id": record.doctor_id,
                "p_hospital_id": record.hospital_id,
                "p_weekly_schedule": scheduleToJsonDictionary(record.weekly_schedule),
                "p_effective_from": record.effective_from,
                "p_effective_until": record.effective_until as Any,
                "p_max_normal": record.max_normal_patients,
                "p_max_premium": record.max_premium_patients
            ]
            
            // Encode parameters using JSONSerialization
            let jsonData = try JSONSerialization.data(withJSONObject: paramsDict)
            request.httpBody = jsonData
            
            // Log request details for debugging
            print("📊 Function URL: \(url.absoluteString)")
            print("📊 Function parameters: \(String(data: jsonData, encoding: .utf8) ?? "Unable to print parameters")")
            
            // Execute request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid function response")
                return
            }
            
            print("📊 Function response status: \(httpResponse.statusCode)")
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Function call successful")
                print("📊 Response: \(responseString)")
            } else {
                print("❌ Function call failed with status: \(httpResponse.statusCode)")
                print("❌ Response: \(responseString)")
                
                // Attempt to identify specific errors
                if responseString.contains("duplicate key value") {
                    print("🔍 Error details: Record with this combination of keys already exists")
                } else if responseString.contains("violates foreign key constraint") {
                    print("🔍 Error details: Referenced doctor_id or hospital_id does not exist")
                } else if responseString.contains("null value in column") {
                    print("🔍 Error details: Required field is missing")
                }
                
                // Try one last workaround - direct manual SQL upsert
                await attemptLastResortUpsert(record: record)
            }
        } catch {
            print("❌ Function call error: \(error.localizedDescription)")
            print("❌ Error type: \(type(of: error))")
            print("⚠️ Suggestion: Verify the 'set_doctor_weekly_schedule' function exists in the database")
            
            // Try one last workaround
            await attemptLastResortUpsert(record: record)
        }
    }
    
    // Last resort method to try to work around constraints
    private func attemptLastResortUpsert(record: DoctorAvailabilityEfficientRecord) async {
        print("🔄 Attempting last resort upsert using SQL")
        
        // Try to delete any existing record first
        do {
            let deleteUrl = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient?doctor_id=eq.\(record.doctor_id)")!
            var deleteRequest = URLRequest(url: deleteUrl)
            deleteRequest.httpMethod = "DELETE"
            deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            deleteRequest.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            deleteRequest.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (_, deleteResponse) = try await URLSession.shared.data(for: deleteRequest)
            
            if let httpResponse = deleteResponse as? HTTPURLResponse {
                print("📊 Delete response status: \(httpResponse.statusCode)")
                // Even if it fails, try the insert anyway
            }
            
            // Now try to insert the record
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            // Encode and send data
            let recordDict: [String: Any] = [
                "doctor_id": record.doctor_id,
                "hospital_id": record.hospital_id,
                "weekly_schedule": scheduleToJsonDictionary(record.weekly_schedule),
                "effective_from": record.effective_from,
                "effective_until": record.effective_until as Any,
                "max_normal_patients": record.max_normal_patients,
                "max_premium_patients": record.max_premium_patients,
                "created_at": ISO8601DateFormatter().string(from: Date()),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: recordDict)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Last resort insertion successful")
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Last resort insertion failed: \(responseString)")
                print("⚠️ Manual database intervention may be required to resolve constraint issues")
            }
        } catch {
            print("❌ Last resort error: \(error.localizedDescription)")
            print("⚠️ All automatic attempts to add doctor availability have failed.")
            print("⚠️ Suggestion: Check database constraints and relationships manually.")
        }
    }
    
    // Fetch doctor availability schedule
    func getDoctorSchedule(doctorId: String, hospitalId: String) async throws -> (weekdaySlots: Set<String>, weekendSlots: Set<String>) {
        print("🔍 Fetching schedule for doctor \(doctorId) at hospital \(hospitalId)")
        
        do {
            // Query the database for this doctor's schedule using the proper API
            let results = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctorId
            )
            
            // Print the raw results for debugging
            if let rawResultData = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted),
               let rawString = String(data: rawResultData, encoding: .utf8) {
                print("📋 RAW JSON RESULT: \(rawString)")
            }
            
            // Also check the hospital_id matches since the select method only supports one condition
            let filteredResults = results.filter { record in
                if let recordHospitalId = record["hospital_id"] as? String {
                    return recordHospitalId == hospitalId
                }
                return false
            }
            
            print("📊 Query result: \(filteredResults.isEmpty ? "No data" : "Data found")")
            
            // Process the result
            if let record = filteredResults.first {
                print("✅ Found record in efficient table: \(record)")
                
                // Try parsing the weekly_schedule in multiple ways
                
                // 1. First attempt - try parsing as a dictionary
                if let weeklySchedule = record["weekly_schedule"] as? [String: Any] {
                    print("✅ Found weekly_schedule as Dictionary: \(weeklySchedule)")
                    
                    var weekdaySlots = Set<String>()
                    var weekendSlots = Set<String>()
                    
                    if let weekdayData = weeklySchedule["weekday"] as? [String] {
                        weekdaySlots = Set(weekdayData)
                        print("📋 Weekday slots (from dictionary): \(weekdaySlots)")
                    } else {
                        print("⚠️ Weekday key exists but is not a string array: \(String(describing: weeklySchedule["weekday"]))")
                    }
                    
                    if let weekendData = weeklySchedule["weekend"] as? [String] {
                        weekendSlots = Set(weekendData)
                        print("📋 Weekend slots (from dictionary): \(weekendSlots)")
                    } else {
                        print("⚠️ Weekend key exists but is not a string array: \(String(describing: weeklySchedule["weekend"]))")
                    }
                    
                    // If we found valid data, return it
                    if !weekdaySlots.isEmpty || !weekendSlots.isEmpty {
                        return (weekdaySlots, weekendSlots)
                    }
                }
                
                // 2. Second attempt - try parsing from JSON string
                if let weeklyScheduleStr = record["weekly_schedule"] as? String {
                    print("🔄 Found weekly_schedule as String: \(weeklyScheduleStr)")
                    
                    if let scheduleData = weeklyScheduleStr.data(using: .utf8),
                       let schedule = try? JSONSerialization.jsonObject(with: scheduleData) as? [String: Any] {
                        
                        var weekdaySlots = Set<String>()
                        var weekendSlots = Set<String>()
                        
                        if let weekdayData = schedule["weekday"] as? [String] {
                            weekdaySlots = Set(weekdayData)
                            print("📋 Weekday slots (from JSON string): \(weekdaySlots)")
                        }
                        
                        if let weekendData = schedule["weekend"] as? [String] {
                            weekendSlots = Set(weekendData)
                            print("📋 Weekend slots (from JSON string): \(weekendSlots)")
                        }
                        
                        return (weekdaySlots, weekendSlots)
                    }
                }
                
                // 3. Try individual slots in record
                let weekdayKeyPattern = "slot_weekday_"
                let weekendKeyPattern = "slot_weekend_"
                
                var weekdaySlots = Set<String>()
                var weekendSlots = Set<String>()
                
                for (key, value) in record {
                    if key.hasPrefix(weekdayKeyPattern), let timeSlot = value as? String {
                        weekdaySlots.insert(timeSlot)
                        print("📋 Found weekday slot in record: \(timeSlot)")
                    } else if key.hasPrefix(weekendKeyPattern), let timeSlot = value as? String {
                        weekendSlots.insert(timeSlot)
                        print("📋 Found weekend slot in record: \(timeSlot)")
                    }
                }
                
                if !weekdaySlots.isEmpty || !weekendSlots.isEmpty {
                    return (weekdaySlots, weekendSlots)
                }
                
                // 4. Last attempt - check for any time patterns in the record
                print("⚠️ No standard format found, trying fallback pattern matching")
                
                for (key, value) in record {
                    // Dump each field to help debug the structure
                    print("   📌 \(key): \(value) (type: \(type(of: value)))")
                    
                    if let valueStr = value as? String {
                        // Check for common time formats: XX:XX-XX:XX or XX:XX:XX-XX:XX:XX
                        if valueStr.range(of: #"\d{1,2}:\d{2}(:\d{2})?-\d{1,2}:\d{2}(:\d{2})?"#, options: .regularExpression) != nil {
                            print("⚡️ Found time pattern in field '\(key)': \(valueStr)")
                            
                            // Decide where to add this slot based on field name or context
                            if key.lowercased().contains("weekday") || key.lowercased().contains("week_day") {
                                weekdaySlots.insert(valueStr)
                            } else if key.lowercased().contains("weekend") || key.lowercased().contains("week_end") {
                                weekendSlots.insert(valueStr)
                            } else {
                                // Can't determine, add to weekdays by default
                                weekdaySlots.insert(valueStr)
                            }
                        }
                    }
                }
                
                // Return any slots we found
                if !weekdaySlots.isEmpty || !weekendSlots.isEmpty {
                    return (weekdaySlots, weekendSlots)
                }
            } else {
                print("⚠️ No matching record found after hospital ID filtering")
            }
            
            // If no slots found, return empty sets
            print("⚠️ No schedule found in database, returning empty sets")
            return (Set<String>(), Set<String>())
        } catch {
            print("❌ Error fetching doctor schedule: \(error.localizedDescription)")
            
            // Return empty sets on error
            print("❌ ERROR: Returning empty sets")
            return (Set<String>(), Set<String>())
        }
    }
    
    // Update doctor's availability schedule
    func updateDoctorSchedule(doctorId: String, hospitalId: String, weekdaySlots: Set<String>, weekendSlots: Set<String>) async throws {
        print("🔄 Updating availability schedule for Doctor ID: \(doctorId) - Hospital ID: \(hospitalId)")
        print("🔍 Weekday slots: \(weekdaySlots)")
        print("🔍 Weekend slots: \(weekendSlots)")
        
        // First try to find if the doctor already has a schedule
        let results = try await supabase.select(
            from: "doctor_availability_efficient",
            where: "doctor_id",
            equals: doctorId
        )
        
        if results.isEmpty {
            // If no existing schedule, create a new one
            print("ℹ️ No existing schedule found, creating new schedule")
            try await addDoctorSchedule(
                doctorId: doctorId,
                hospitalId: hospitalId,
                weekdaySlots: weekdaySlots,
                weekendSlots: weekendSlots
            )
            return
        }
        
        // If schedule exists, update it using the same structure as addDoctorSchedule
        // Initialize empty schedule for all days
        var weeklySchedule: [String: [TimeSlot]] = [
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": []
        ]
        
        // Parse and add weekday slots
        if !weekdaySlots.isEmpty {
            let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday"]
            
            // Add the same slots to all weekdays
            for slot in weekdaySlots {
                print("🔄 Processing weekday slot: \(slot)")
                if let (startTime, endTime) = parseTimeSlot(slot) {
                    let timeSlot = TimeSlot(start: startTime, end: endTime)
                    
                    // Add to each weekday
                    for day in weekdays {
                        weeklySchedule[day]?.append(timeSlot)
                    }
                } else {
                    print("⚠️ Could not parse weekday slot: \(slot)")
                }
            }
        }
        
        // Parse and add weekend slots
        if !weekendSlots.isEmpty {
            let weekends = ["saturday", "sunday"]
            
            // Add the same slots to weekend days
            for slot in weekendSlots {
                print("🔄 Processing weekend slot: \(slot)")
                if let (startTime, endTime) = parseTimeSlot(slot) {
                    let timeSlot = TimeSlot(start: startTime, end: endTime)
                    
                    // Add to each weekend day
                    for day in weekends {
                        weeklySchedule[day]?.append(timeSlot)
                    }
                } else {
                    print("⚠️ Could not parse weekend slot: \(slot)")
                }
            }
        }
        
        // Convert weekly schedule to JSON format
        let jsonSchedule = convertToJsonSchedule(weeklySchedule)
        
        // Get the ID of the existing record to update
        guard let existingRecord = results.first,
              let recordId = existingRecord["id"] as? Int else {
            print("❌ Failed to get existing schedule ID")
            throw NSError(domain: "AdminController", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to get existing schedule ID"])
        }
        
        print("ℹ️ Found existing record with ID: \(recordId)")
        
        // Use direct URL request to update the record
        do {
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient?id=eq.\(recordId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            // Create the update data
            let updateDict: [String: Any] = [
                "weekly_schedule": scheduleToJsonDictionary(jsonSchedule),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Serialize to JSON
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: updateDict)
                print("✅ Successfully serialized update data to JSON")
            } catch {
                print("❌ Failed to serialize JSON: \(error.localizedDescription)")
                throw error
            }
            request.httpBody = jsonData
            
            print("🔄 Sending update request to Supabase")
            print("📊 Update URL: \(url.absoluteString)")
            print("📊 Update data: \(String(data: jsonData, encoding: .utf8) ?? "Unable to print payload")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NSError(domain: "AdminController", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Successfully updated weekly schedule for doctor \(doctorId)")
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Failed to update schedule: \(responseString)")
                }
                throw NSError(domain: "AdminController", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update schedule with status code \(httpResponse.statusCode)"])
            }
        } catch {
            print("❌ Failed to update schedule: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Update existing schedule
    private func updateExistingSchedule(doctorId: String, newRecord: DoctorAvailabilityEfficientRecord) async {
        print("🔄 Updating existing schedule for Doctor ID: \(doctorId)")
        
        do {
            // First, fetch the existing schedule
            let existingRecords = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctorId
            )
            
            guard let existingRecord = existingRecords.first,
                  let recordId = existingRecord["id"] as? Int else {
                print("❌ Failed to find existing schedule for doctor \(doctorId)")
                return
            }
            
            // Update the existing record
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctor_availability_efficient?id=eq.\(recordId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            // Create the update data
            let updateDict: [String: Any] = [
                "weekly_schedule": scheduleToJsonDictionary(newRecord.weekly_schedule),
                "max_normal_patients": newRecord.max_normal_patients,
                "max_premium_patients": newRecord.max_premium_patients,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Serialize to JSON
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: updateDict)
                print("✅ Successfully serialized update data to JSON")
            } catch {
                print("❌ Failed to serialize JSON: \(error.localizedDescription)")
                return
            }
            request.httpBody = jsonData
            
            print("🔄 Sending update request to Supabase")
            print("📊 Update URL: \(url.absoluteString)")
            print("📊 Update data: \(String(data: jsonData, encoding: .utf8) ?? "Unable to print payload")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ Successfully updated existing schedule for doctor \(doctorId)")
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ Failed to update schedule: \(responseString)")
            }
        } catch {
            print("❌ Error updating existing schedule: \(error.localizedDescription)")
        }
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
