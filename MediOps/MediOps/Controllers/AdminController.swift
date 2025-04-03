import Foundation

class AdminController {
    static let shared = AdminController()
    
    private let supabase = SupabaseController.shared
    private let userController = UserController.shared
    private let hospitalController = HospitalController.shared
    
    private init() {}
    
    // MARK: - Diagnostic Methods
    
    /// Gets diagnostic information about the database connection
    func getDatabaseDiagnosticInfo() async throws -> [String: Any] {
        var diagnosticInfo: [String: Any] = [:]
        
        // Add Supabase URL to diagnostics
        diagnosticInfo["supabaseURL"] = supabase.supabaseURL.absoluteString
        
        // Get count of lab admins
        let labAdminCount = try await supabase.select(from: "lab_admins", columns: "count(*)")
        if let firstResult = labAdminCount.first, let count = firstResult["count"] as? Int {
            diagnosticInfo["totalLabAdmins"] = count
        }
        
        return diagnosticInfo
    }
    
    /// Check if lab admins exist for a specific hospital ID
    func checkLabAdminsForHospital(hospitalId: String) async throws -> [String: Any] {
        var result: [String: Any] = [:]
        
        // Try direct query for matching lab admins
        let directQuery = try await supabase.select(
            from: "lab_admins",
            where: "hospital_id",
            equals: hospitalId
        )
        
        result["hospitalId"] = hospitalId
        result["count"] = directQuery.count
        result["recordsExist"] = directQuery.count > 0
        
        return result
    }
    
    // MARK: - Hospital Admin Management
    
    /// Force reset a hospital admin's password without requiring the current password (admin override)
    /// Use this only for emergency cases when a user has forgotten their password
    func forceResetHospitalAdminPassword(adminId: String, newPassword: String) async throws {
        print("ADMIN: Force resetting password for admin ID: \(adminId)")
        
        // 1. Find the admin record and get hospital ID
        let admins = try await supabase.select(
            from: "hospital_admins",
            where: "id",
            equals: adminId
        )
        
        guard let adminData = admins.first,
              let hospitalId = adminData["hospital_id"] as? String else {
            print("ADMIN ERROR: Could not retrieve admin data or hospital ID")
            throw AdminError.adminNotFound
        }
        
        // 2. Validate the new password
        if newPassword.count < 8 {
            throw AdminError.invalidPassword(message: "Password must be at least 8 characters long")
        }
        
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]+$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if !passwordPredicate.evaluate(with: newPassword) {
            throw AdminError.invalidPassword(message: "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character")
        }
        
        // 3. Update the password in the hospital_admins table
        let updateData: [String: Any] = [
            "password": newPassword,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        print("ADMIN: Updating password in hospital_admins table")
        try await supabase.update(
            table: "hospital_admins",
            id: adminId,
            data: updateData
        )
        
        // 4. Update the password in the hospitals table
        print("ADMIN: Updating password in hospitals table for hospital ID: \(hospitalId)")
        try await supabase.updateHospitalPassword(hospitalId: hospitalId, newPassword: newPassword)
        
        print("ADMIN: Force password reset successful for admin ID: \(adminId)")
    }
    
    /// Reset a hospital admin's password, updating both hospital_admins and hospitals tables
    func resetHospitalAdminPassword(adminId: String, currentPassword: String, newPassword: String) async throws {
        print("ADMIN: Resetting password for admin ID: \(adminId)")
        print("ADMIN DEBUG: Current password length: \(currentPassword.count)")
        
        // 1. First verify the current password is correct
        let admins = try await supabase.select(
            from: "hospital_admins",
            where: "id",
            equals: adminId
        )
        
        guard let adminData = admins.first,
              let storedPassword = adminData["password"] as? String,
              let hospitalId = adminData["hospital_id"] as? String else {
            print("ADMIN ERROR: Could not retrieve admin password or hospital ID")
            throw AdminError.adminNotFound
        }
        
        print("ADMIN DEBUG: Retrieved admin details - Name: \(adminData["admin_name"] as? String ?? "unknown")")
        print("ADMIN DEBUG: Stored password length: \(storedPassword.count)")
        print("ADMIN DEBUG: Stored password first 3 chars: \(String(storedPassword.prefix(3)))")
        print("ADMIN DEBUG: Input password first 3 chars: \(String(currentPassword.prefix(3)))")
        
        // Add more detailed debug info about the password fields
        if storedPassword.isEmpty {
            print("ADMIN DEBUG: WARNING - Stored password is empty!")
        }
        
        if currentPassword.isEmpty {
            print("ADMIN DEBUG: WARNING - Input current password is empty!")
        }
        
        // Check for whitespace or other invisible characters
        let storedPasswordHasWhitespace = storedPassword.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        let currentPasswordHasWhitespace = currentPassword.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
        
        print("ADMIN DEBUG: Stored password has whitespace: \(storedPasswordHasWhitespace)")
        print("ADMIN DEBUG: Current password has whitespace: \(currentPasswordHasWhitespace)")
        
        // Verify current password matches
        if storedPassword != currentPassword {
            print("ADMIN ERROR: Current password is incorrect")
            print("ADMIN DEBUG: Password comparison failed - input: '\(currentPassword)' vs stored: '\(storedPassword)'")
            throw AdminError.invalidPassword(message: "Current password is incorrect")
        }
        
        // Validate the new password
        if newPassword.count < 8 {
            throw AdminError.invalidPassword(message: "Password must be at least 8 characters long")
        }
        
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]+$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if !passwordPredicate.evaluate(with: newPassword) {
            throw AdminError.invalidPassword(message: "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character")
        }
        
        // 2. Update the password in the hospital_admins table
        let updateData: [String: Any] = [
            "password": newPassword,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        print("ADMIN: Updating password in hospital_admins table")
        try await supabase.update(
            table: "hospital_admins",
            id: adminId,
            data: updateData
        )
        
        // 3. Update the password in the hospitals table
        print("ADMIN: Updating password in hospitals table for hospital ID: \(hospitalId)")
        try await supabase.updateHospitalPassword(hospitalId: hospitalId, newPassword: newPassword)
        
        print("ADMIN: Password reset successful for admin ID: \(adminId)")
    }
    
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
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
        doctorStatus: String = "active",
        maxAppointments: Int = 8
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
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
            let max_appointments: Int
            var contact_number: String?
            var emergency_contact_number: String?
        }
        
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
            max_appointments: maxAppointments,
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
            dateOfBirth: nil, // Add missing dateOfBirth parameter
            createdAt: now,
            updatedAt: now,
            maxAppointments: maxAppointments
        )
        
        // Log the activity with structured data
        await logActivity(
            action: "create",
            entityType: "doctor",
            entityId: doctorId,
            entityName: name,
            details: [
                "hospital_id": hospitalId,
                "specialization": specialization,
                "qualifications": qualifications,
                "email": email,
                "contact_number": contactNumber.isEmpty ? "" : contactNumber,
                "license_no": licenseNo,
                "experience": experience
            ]
        )
        
        // Return doctor object with a dummy token
        print("CREATE DOCTOR: Successfully created doctor with ID: \(doctorId)")
        return (doctor, "doctor-token")
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
        contactNumber: String,
        maxAppointments: Int = 10
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
            let max_appointments: Int
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
            updated_at: ISO8601DateFormatter().string(from: Date()),
            max_appointments: maxAppointments
        )
        
        // Update the doctor record in Supabase
        try await supabase.update(
            table: "doctors",
            data: doctorData,
            where: "id",
            equals: doctorId
        )
        
        // Add before return or at the end of the function:
        await logActivity(
            action: "update",
            entityType: "doctor",
            entityId: doctorId,
            entityName: name,
            details: [
                "specialization": specialization,
                "qualifications": qualifications,
                "license_no": licenseNo,
                "experience": experience,
                "address_line": addressLine,
                "email": email,
                "contact_number": contactNumber
            ]
        )
        
        print("UPDATE DOCTOR: Successfully updated doctor with ID: \(doctorId)")
    }
    
    /// Delete a doctor
    func deleteDoctor(id: String) async throws {
        // Get the doctor name before deletion for logging
        let doctor = try await getDoctor(id: id)
        let doctorName = doctor.name
        let hospitalId = doctor.hospitalId
        
        print("DELETE DOCTOR: Attempting to delete doctor with ID: \(id)")
        
        // First, attempt to delete any related records that might cause foreign key constraint issues
        do {
            // Delete from doctor_availability_efficient table
            print("DELETE DOCTOR: Removing doctor availability records")
            try await supabase.delete(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: id
            )
            print("DELETE DOCTOR: Successfully removed availability records")
        } catch {
            print("DELETE DOCTOR: No availability records found or error removing them: \(error.localizedDescription)")
            // Continue with deletion even if this fails
        }
        
        do {
            // Delete from doctor_slots table if it exists
            print("DELETE DOCTOR: Removing doctor slots records")
            try await supabase.delete(
                from: "doctor_slots",
                where: "doctor_id",
                equals: id
            )
            print("DELETE DOCTOR: Successfully removed slot records")
        } catch {
            print("DELETE DOCTOR: No slot records found or error removing them: \(error.localizedDescription)")
            // Continue with deletion even if this fails
        }
        
        do {
            // Delete from appointments table if it exists
            print("DELETE DOCTOR: Removing appointment records")
            try await supabase.delete(
                from: "appointments",
                where: "doctor_id",
                equals: id
            )
            print("DELETE DOCTOR: Successfully removed appointment records")
        } catch {
            print("DELETE DOCTOR: No appointment records found or error removing them: \(error.localizedDescription)")
            // Continue with deletion even if this fails
        }
        
        // Now try to delete the doctor record
        do {
            print("DELETE DOCTOR: Attempting to delete doctor record")
            try await supabase.delete(
                from: "doctors",
                where: "id",
                equals: id
            )
            print("DELETE DOCTOR: Successfully deleted doctor with ID: \(id)")
            return // Exit if deletion was successful
        } catch {
            print("DELETE DOCTOR ERROR on deletion: \(error.localizedDescription)")
            
            // Try with a direct URL request instead of executeSql
            do {
                print("DELETE DOCTOR: Attempting direct API delete")
                
                let url = URL(string: "\(supabase.supabaseURL)/rest/v1/doctors?id=eq.\(id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, 
                   httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("DELETE DOCTOR: Successfully deleted doctor with ID: \(id) via direct API")
                    return
                } else {
                    print("DELETE DOCTOR: Direct API deletion failed")
                }
            } catch {
                print("DELETE DOCTOR ERROR on direct API deletion: \(error.localizedDescription)")
            }
            
            // As a last resort, try to update status (but we prefer actual deletion)
            struct DoctorStatusUpdate: Encodable {
                let doctor_status: String
                let updated_at: String
            }
            
            // Try various possible status values that might be allowed by the check constraint
            let possibleStatuses = ["inactive", "suspended", "terminated"]
            
            for status in possibleStatuses {
                do {
                    print("DELETE DOCTOR: Deletion failed, trying status update to '\(status)'")
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
                    
                    print("DELETE DOCTOR: Successfully performed soft delete with status: \(status)")
                    return
                } catch {
                    print("DELETE DOCTOR: Status '\(status)' update failed: \(error.localizedDescription)")
                    // Continue trying other statuses
                }
            }
            
            // If we reach here, none of our approaches worked
            throw AdminError.doctorDeleteFailed
        }
        
        // Add at the end of the function:
        await logActivity(
            action: "delete",
            entityType: "doctor",
            entityId: id,
            entityName: doctorName,
            details: [
                "hospital_id": hospitalId,
                "deletion_type": "permanent",
                "related_records_deleted": true
            ]
        )
        
        print("DELETE DOCTOR: Successfully deleted doctor with ID: \(id)")
    }
    
    // MARK: - Lab Admin Management
    
    /// Register a new lab admin (independent of users table)
    func createLabAdmin(email: String, password: String, name: String, qualification: [String], hospitalAdminId: String, contactNumber: String = "", department: String = "Pathology & Laboratory", license: String? = nil, dateOfBirth: Date? = nil, experience: Int = 0) async throws -> (LabAdmin, String) {
        print("CREATE LAB ADMIN: Creating lab admin with hospital ID: \(hospitalAdminId)")
        
        // Verify that the hospital admin exists and get their correct ID
        var verifiedHospitalId = hospitalAdminId
        
        // Basic validation for empty hospital ID
        if verifiedHospitalId.isEmpty {
            print("CREATE LAB ADMIN ERROR: Empty hospital ID provided")
            throw AdminError.invalidData("Hospital ID cannot be empty")
        }
        
        // Validate qualifications against allowed values
        let allowedQualifications = ["MLT", "DMLT", "M.Sc"]
        if qualification.isEmpty {
            throw AdminError.invalidData("Qualification cannot be empty")
        }
        
        // Check that all qualifications are from the allowed set
        for qual in qualification {
            if !allowedQualifications.contains(qual) {
                throw AdminError.invalidFormat("Invalid qualification: \(qual). Allowed values are: \(allowedQualifications.joined(separator: ", "))")
            }
        }
        
        // Try to verify hospital admin exists
        do {
            // Get hospital details to verify it exists
            let hospitalAdmin = try await getHospitalAdmin(id: hospitalAdminId)
            // Use the verified hospital_id from the admin record
            verifiedHospitalId = hospitalAdmin.id
            print("CREATE LAB ADMIN: Verified hospital admin ID: \(verifiedHospitalId)")
        } catch {
            print("CREATE LAB ADMIN WARNING: Could not verify hospital admin ID: \(error.localizedDescription)")
            
            // Since we couldn't verify the hospital admin, let's try to check if the hospital exists directly
            do {
                _ = try await getHospital(id: hospitalAdminId)
                print("CREATE LAB ADMIN: Hospital exists with ID: \(hospitalAdminId), using this ID directly")
                verifiedHospitalId = hospitalAdminId // Use the original ID if hospital exists
            } catch {
                print("CREATE LAB ADMIN ERROR: Could not verify hospital either: \(error.localizedDescription)")
                // Now we throw an error since we couldn't verify the hospital ID through any method
                throw AdminError.invalidData("Invalid hospital ID. Please ensure you're using a valid hospital identifier.")
            }
        }
        
        // Generate a LAB-prefixed ID
        // Ensure it's exactly 6 characters (LAB followed by 3 digits)
        let randomNumber = Int.random(in: 1...999)
        let labAdminId = "LAB" + String(format: "%03d", randomNumber) // Ensures 3 digits with leading zeros
        
        // Double-check that the generated ID matches the required format
        let idFormatRegex = "^LAB[0-9]{3}$"
        let isValidId = labAdminId.range(of: idFormatRegex, options: .regularExpression) != nil
        if !isValidId {
            print("CREATE LAB ADMIN ERROR: Generated ID '\(labAdminId)' does not match required format")
            throw AdminError.invalidFormat("Invalid lab admin ID format. Generated ID does not match required pattern.")
        } else {
            print("CREATE LAB ADMIN: Generated valid ID: \(labAdminId)")
        }
        
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = dateFormatter.string(from: now)
        
        // Validate data against table constraints
        
        // 1. Ensure contact number follows the format constraint (10 digits)
        let contactNumberToUse = contactNumber.isEmpty ? "" : contactNumber
        if !contactNumberToUse.isEmpty {
            let isValid = contactNumberToUse.range(of: "^[0-9]{10}$", options: .regularExpression) != nil
            if !isValid {
                throw AdminError.invalidContactNumber("Contact number must be 10 digits")
            }
        }
        
        // 2. Validate the ID format
        let idFormatValid = labAdminId.range(of: "^LAB[0-9]{3}$", options: .regularExpression) != nil
        if !idFormatValid {
            throw AdminError.invalidFormat("Invalid lab admin ID format")
        }
        
        // 3. Ensure password meets requirements
        // At least 8 characters with at least one uppercase, one lowercase, one digit, and one special character
        if password.count < 8 || 
           password.range(of: ".*[A-Z].*", options: .regularExpression) == nil ||
           password.range(of: ".*[a-z].*", options: .regularExpression) == nil ||
           password.range(of: ".*[0-9].*", options: .regularExpression) == nil ||
           password.range(of: ".*[@$!%*?&].*", options: .regularExpression) == nil {
            throw AdminError.invalidPassword(message: "Password does not meet security requirements")
        }
        
        // Create lab admin record with qualifications as array
        var labAdminData: [String: Any] = [
            "id": labAdminId,
            "hospital_id": verifiedHospitalId,
            "password": password,
            "name": name,
            "email": email,
            "contact_number": contactNumberToUse,
            "department": "Pathology & Laboratory", // Always use the fixed value to match constraint
            "qualification": qualification, // Store as array
            "license_no": license, // Use license parameter directly
            "experience": experience, // Add experience field
            "Address": "", // Default empty address
            "created_at": createdAt,
            "updated_at": createdAt
        ]
        
        // Add date of birth if available
        if let dob = dateOfBirth {
            labAdminData["dob"] = dateFormatter.string(from: dob)
        }
        
        // Validate data against table constraints one more time before submission
        print("CREATE LAB ADMIN: Validating lab admin data before submission")
        print("- ID: \(labAdminId) (format: \(labAdminId.range(of: "^LAB[0-9]{3}$", options: .regularExpression) != nil ? "✓" : "✗"))")
        print("- Hospital ID: \(verifiedHospitalId)")
        print("- Name: \(name)")
        print("- Email: \(email)")
        print("- Qualifications: \(qualification.joined(separator: ", "))")
        print("- Contact number: \(contactNumberToUse.isEmpty ? "[empty]" : contactNumberToUse) (format: \(contactNumberToUse.isEmpty || contactNumberToUse.range(of: "^[0-9]{10}$", options: .regularExpression) != nil ? "✓" : "✗"))")
        print("- Password: [hidden] (length: \(password.count), meets requirements: \(password.count >= 8 && password.range(of: ".*[A-Z].*", options: .regularExpression) != nil && password.range(of: ".*[a-z].*", options: .regularExpression) != nil && password.range(of: ".*[0-9].*", options: .regularExpression) != nil && password.range(of: ".*[@$!%*?&].*", options: .regularExpression) != nil ? "✓" : "✗"))")
        print("- Department: \(labAdminData["department"] ?? "") (required: 'Pathology & Laboratory')")
        
        do {
            // Create an Encodable struct for database insertion
            struct LabAdminInsertData: Encodable {
                let id: String
                let hospital_id: String
                let password: String
                let name: String
                let email: String
                let contact_number: String
                let department: String
                let qualification: [String]
                let license_no: String?
                let dob: String?
                let experience: Int
                let Address: String
                let created_at: String
                let updated_at: String
            }
            
            // Format date of birth for insertion
            let dateOfBirthString = dateOfBirth.map { dateFormatter.string(from: $0) }
            
            // Create encodable struct from the data
            let encodableData = LabAdminInsertData(
                id: labAdminId,
                hospital_id: verifiedHospitalId,
                password: password,
                name: name,
                email: email,
                contact_number: contactNumberToUse,
                department: "Pathology & Laboratory",
                qualification: qualification,
                license_no: license, // Use license parameter directly
                dob: dateOfBirthString,
                experience: experience,
                Address: "",
                created_at: createdAt,
                updated_at: createdAt
            )
            
            // Insert with the encodable struct
            try await supabase.insert(into: "lab_admins", data: encodableData)
            print("CREATE LAB ADMIN: Successfully inserted data into lab_admins table")
        } catch {
            print("CREATE LAB ADMIN ERROR: Failed to insert lab admin: \(error.localizedDescription)")
            
            // If there's a specific insert error, provide a more helpful message
            let errorDesc = error.localizedDescription.lowercased()
            if errorDesc.contains("duplicate") && errorDesc.contains("email") {
                throw AdminError.emailAlreadyExists("Email address already in use")
            } else if errorDesc.contains("violates") && errorDesc.contains("constraint") {
                if errorDesc.contains("lab_admins_hospital_id_fkey") {
                    // Add more diagnostic information for hospital ID issues
                    print("CREATE LAB ADMIN DIAGNOSTIC: Hospital ID verification failed. Used ID: \(verifiedHospitalId)")
                    print("CREATE LAB ADMIN DIAGNOSTIC: Original hospital ID from request: \(hospitalAdminId)")
                    
                    // Try to get additional details about the hospital
                    do {
                        _ = try await getHospital(id: verifiedHospitalId)
                        print("CREATE LAB ADMIN DIAGNOSTIC: Strange - hospital lookup succeeded but constraint failed")
                    } catch {
                        print("CREATE LAB ADMIN DIAGNOSTIC: Hospital lookup also failed: \(error.localizedDescription)")
                    }
                    
                    throw AdminError.invalidData("Invalid hospital ID: \(verifiedHospitalId). The referenced hospital does not exist in the database.")
                } else if errorDesc.contains("lab_admins_id_format") {
                    throw AdminError.invalidFormat("Invalid lab admin ID format: \(labAdminId)")
                } else if errorDesc.contains("lab_admins_contact_number_format") {
                    throw AdminError.invalidContactNumber("Invalid contact number format: \(contactNumberToUse)")
                } else if errorDesc.contains("lab_admins_password_format") {
                    throw AdminError.invalidPassword(message: "Password does not meet security requirements")
                } else if errorDesc.contains("lab_admins_department_check") {
                    throw AdminError.invalidFormat("Department must be 'Pathology & Laboratory'")
                } else if errorDesc.contains("qualification_check") {
                    throw AdminError.invalidFormat("Invalid qualification. Allowed values are: MLT, DMLT, M.Sc")
                } else {
                    throw AdminError.invalidFormat("Database constraint violation: \(error.localizedDescription)")
                }
            } else {
                throw error
            }
        }
        
        // Return lab admin object with a dummy token
        let labAdmin = LabAdmin(
            id: labAdminId,
            hospitalId: verifiedHospitalId,
            name: name,
            email: email,
            contactNumber: contactNumberToUse,
            department: "Pathology & Laboratory", // Fixed to match the constraint
            address: "",
            qualification: qualification, // Add the qualification array
            licenseNo: license, // Add license number
            dateOfBirth: dateOfBirth, // Add dateOfBirth field (will update parsing later)
            experience: experience, // Add experience field
            createdAt: now,
            updatedAt: now
        )
        
        // Log the activity with structured data
        await logActivity(
            action: "create",
            entityType: "lab_admin",
            entityId: labAdminId,
            entityName: name,
            details: [
                "hospital_id": verifiedHospitalId,
                "qualification": qualification,
                "email": email,
                "contact_number": contactNumberToUse,
                "license_no": license ?? "",
                "experience": experience,
                "date_of_birth": dateOfBirth != nil ? dateFormatter.string(from: dateOfBirth!) : ""
            ]
        )
        
        // Return lab admin object with a dummy token
        print("CREATE LAB ADMIN: Successfully created lab admin with ID: \(labAdminId)")
        return (labAdmin, "lab-admin-token")
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
        
        // Basic validation for hospital ID
        if hospitalAdminId.isEmpty {
            print("GET LAB ADMINS ERROR: Empty hospital ID provided")
            throw AdminError.invalidData("Hospital ID cannot be empty")
        }
        
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
            
            // Since we couldn't verify the hospital admin, let's try to check if the hospital exists directly
            do {
                _ = try await getHospital(id: hospitalAdminId)
                print("GET LAB ADMINS: Hospital exists with ID: \(hospitalAdminId), using this ID directly")
                verifiedHospitalId = hospitalAdminId // Use the original ID if hospital exists
            } catch {
                print("GET LAB ADMINS WARNING: Could not verify hospital either: \(error.localizedDescription)")
            // Continue with the provided ID, but log the warning
            }
        }
        
        print("GET LAB ADMINS: Final hospital ID for query: \(verifiedHospitalId)")
        
        // Fetch lab admins with the verified ID
        do {
        let labAdmins = try await supabase.select(
            from: "lab_admins",
            where: "hospital_id",
            equals: verifiedHospitalId
        )
        
        print("GET LAB ADMINS: Found \(labAdmins.count) lab admins for hospital ID: \(verifiedHospitalId)")
        
        // If no lab admins are found, it's not necessarily an error, could just be an empty list
        if labAdmins.isEmpty {
            print("GET LAB ADMINS: No lab admins found for hospital ID: \(verifiedHospitalId)")
                
                // Check if the lab_admins table exists and has any records at all
                let allLabAdmins = try await supabase.select(from: "lab_admins", columns: "count(*)")
                if let firstResult = allLabAdmins.first, let count = firstResult["count"] as? Int {
                    print("GET LAB ADMINS INFO: Total lab admins in database: \(count)")
                }
                
            return []
        }
        
        // Parse each lab admin record
        var parsedLabAdmins: [LabAdmin] = []
            for (index, labAdminData) in labAdmins.enumerated() {
            do {
                    print("GET LAB ADMINS: Processing lab admin \(index + 1) of \(labAdmins.count)")
                let labAdmin = try parseLabAdminData(labAdminData)
                    print("GET LAB ADMINS: Successfully parsed lab admin: ID=\(labAdmin.id), Name=\(labAdmin.name)")
                parsedLabAdmins.append(labAdmin)
            } catch {
                    print("GET LAB ADMINS WARNING: Failed to parse lab admin \(index + 1): \(error.localizedDescription)")
                // Continue with other records
            }
        }
        
        return parsedLabAdmins
        } catch {
            print("GET LAB ADMINS ERROR: Failed to fetch lab admins: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update lab admin
    func updateLabAdmin(_ labAdmin: LabAdmin) async throws {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let updatedAt = dateFormatter.string(from: now)
        
        // Create an Encodable struct for lab admin updates
        struct LabAdminUpdateData: Encodable {
            let name: String
            let email: String
            let contact_number: String
            let department: String
            let Address: String
            let qualification: [String]?
            let license_no: String?
            let dob: String?
            let experience: Int
            let updated_at: String
        }
        
        // Format date of birth to ISO8601 string if available
        let dateOfBirthString: String?
        if let dob = labAdmin.dateOfBirth {
            dateOfBirthString = dateFormatter.string(from: dob)
        } else {
            dateOfBirthString = nil
        }
        
        let labAdminData = LabAdminUpdateData(
            name: labAdmin.name,
            email: labAdmin.email,
            contact_number: labAdmin.contactNumber,
            department: labAdmin.department,
            Address: labAdmin.address,
            qualification: labAdmin.qualification,
            license_no: labAdmin.licenseNo,
            dob: dateOfBirthString,
            experience: labAdmin.experience,
            updated_at: updatedAt
        )
        
        try await supabase.update(
            table: "lab_admins",
            data: labAdminData,
            where: "id",
            equals: labAdmin.id
        )
        
        // Add before the end of the function:
        await logActivity(
            action: "update",
            entityType: "lab_admin",
            entityId: labAdmin.id,
            entityName: labAdmin.name,
            details: [
                "hospital_id": labAdmin.hospitalId,
                "email": labAdmin.email,
                "contact_number": labAdmin.contactNumber,
                "department": labAdmin.department,
                "qualification": labAdmin.qualification as Any,
                "license_no": labAdmin.licenseNo as Any,
                "experience": labAdmin.experience,
                "address": labAdmin.address,
                "date_of_birth": dateOfBirthString as Any
            ]
        )
        
        print("UPDATE LAB ADMIN: Successfully updated lab admin with ID: \(labAdmin.id)")
    }
    
    /// Delete lab admin
    func deleteLabAdmin(id: String) async throws {
        // Get the lab admin name before deletion for logging
        let labAdmin = try await getLabAdmin(id: id)
        let labAdminName = labAdmin.name
        let hospitalId = labAdmin.hospitalId
        
        print("DELETE LAB ADMIN: Attempting to delete lab admin with ID: \(id)")
        
        // First verify if the lab admin exists
        do {
            let verifyResult = try await verifyLabAdminExists(id: id)
            if !(verifyResult["exists"] as? Bool ?? false) {
                print("DELETE LAB ADMIN ERROR: Lab admin with ID \(id) does not exist")
                throw AdminError.labAdminNotFound
            }
            
            if let name = verifyResult["name"] as? String {
                print("DELETE LAB ADMIN: Confirmed lab admin exists - Name: \(name)")
            }
        } catch {
            if let adminError = error as? AdminError {
                throw adminError
            } else {
                print("DELETE LAB ADMIN WARNING: Verification check failed: \(error.localizedDescription)")
                print("DELETE LAB ADMIN: Continuing with deletion attempt anyway")
            }
        }
        
        // Check for constraints that might prevent deletion
        do {
            let constraintCheck = try await checkLabAdminDeletionConstraints(id: id)
            if !(constraintCheck["canDelete"] as? Bool ?? false) {
                if let message = constraintCheck["message"] as? String {
                    print("DELETE LAB ADMIN ERROR: Constraint check failed - \(message)")
                    throw AdminError.customError(message)
                } else {
                    throw AdminError.customError("Cannot delete lab admin due to database constraints")
                }
            }
        } catch let adminError as AdminError {
            throw adminError
        } catch {
            print("DELETE LAB ADMIN WARNING: Constraint check failed: \(error.localizedDescription)")
            print("DELETE LAB ADMIN: Continuing with deletion attempt anyway")
        }
        
        // Try direct deletion
        do {
            print("DELETE LAB ADMIN: Attempting direct deletion with ID: \(id)")
            try await supabase.delete(
                from: "lab_admins",
                where: "id",
                equals: id
            )
            print("DELETE LAB ADMIN: Successfully deleted lab admin with ID: \(id)")
            return
        } catch {
            print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
            
            // Check if this is a constraint violation (possibly foreign key constraint)
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("violates") && errorMessage.contains("constraint") {
                print("DELETE LAB ADMIN WARNING: Constraint violation detected. Attempting soft delete if possible.")
                
                // Try to implement a soft delete by updating a status field if it exists
                do {
                    // Create a struct for the status update
                    struct LabAdminStatusUpdate: Encodable {
                        let status: String
                        let updated_at: String
                    }
                    
                    // Try to update the status to "inactive" or "deleted" or similar
                    let possibleStatuses = ["inactive", "deleted", "disabled", "removed"]
                    
                    for status in possibleStatuses {
                        do {
                            print("DELETE LAB ADMIN: Trying soft delete with status: \(status)")
                            let updateData = LabAdminStatusUpdate(
                                status: status,
                                updated_at: ISO8601DateFormatter().string(from: Date())
                            )
                            
                            try await supabase.update(
                                table: "lab_admins",
                                data: updateData,
                                where: "id",
                                equals: id
                            )
                            
                            print("DELETE LAB ADMIN: Successfully performed soft delete with status: \(status)")
                            return
                        } catch {
                            print("DELETE LAB ADMIN: Soft delete failed with status \(status): \(error.localizedDescription)")
                            // Continue trying other statuses
                        }
                    }
                    
                    // If soft delete with status field fails, try another approach
                    // Try adding "_deleted" to the email to allow re-registration with same email
                    do {
                        print("DELETE LAB ADMIN: Attempting email modification as soft delete")
                        
                        // Get the current lab admin data
                        let labAdmins = try await supabase.select(
                            from: "lab_admins",
                            where: "id",
                            equals: id
                        )
                        
                        if let labAdmin = labAdmins.first, let email = labAdmin["email"] as? String {
                            // Create a struct for the email update
                            struct EmailUpdate: Encodable {
                                let email: String
                                let updated_at: String
                            }
                            
                            let timestamp = Int(Date().timeIntervalSince1970)
                            let newEmail = "\(email)_deleted_\(timestamp)"
                            
                            let updateData = EmailUpdate(
                                email: newEmail,
                                updated_at: ISO8601DateFormatter().string(from: Date())
                            )
                            
                            try await supabase.update(
                                table: "lab_admins",
                                data: updateData,
                                where: "id",
                                equals: id
                            )
                            
                            print("DELETE LAB ADMIN: Successfully performed soft delete by email modification")
                            return
                        }
                    } catch {
                        print("DELETE LAB ADMIN: Email modification failed: \(error.localizedDescription)")
                    }
                } catch {
                    print("DELETE LAB ADMIN ERROR: All soft delete attempts failed: \(error.localizedDescription)")
                }
            }
            
            // If we got here, neither hard delete nor soft delete worked
            let details = "Failed to delete lab admin with ID: \(id). Error: \(error.localizedDescription)"
            print("DELETE LAB ADMIN ERROR: \(details)")
            throw AdminError.customError(details)
        }
        
        // Add at the end of the function:
        await logActivity(
            action: "delete",
            entityType: "lab_admin",
            entityId: id,
            entityName: labAdminName,
            details: [
                "hospital_id": hospitalId,
                "deletion_type": "permanent",
                "verification_performed": true
            ]
        )
        
        print("DELETE LAB ADMIN: Successfully deleted lab admin with ID: \(id)")
    }
    
    // MARK: - Activity Management
    
    /// Create a new activity
    func createActivity(type: String, title: String, doctorId: String? = nil, labAdminId: String? = nil) async throws -> Activity {
        let activityId = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
            throw AdminError.invalidData("Missing id or hospital_id fields")
        }
        
        guard let adminName = data["admin_name"] as? String else {
            print("CRITICAL ERROR: Missing admin_name field")
            throw AdminError.invalidData("Missing admin_name field")
        }
        
        guard let email = data["email"] as? String else {
            print("CRITICAL ERROR: Missing email field")
            throw AdminError.invalidData("Missing email field")
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
            throw AdminError.invalidData("Missing id field")
        }
        
        // Optional user_id
        let userId = data["user_id"] as? String
                
        guard let name = data["name"] as? String else {
            print("PARSE DOCTOR ERROR: Missing name field")
            throw AdminError.invalidData("Missing name field")
        }
        
        guard let specialization = data["specialization"] as? String else {
            print("PARSE DOCTOR ERROR: Missing specialization field")
            throw AdminError.invalidData("Missing specialization field")
        }
        
        guard let hospitalId = data["hospital_id"] as? String else {
            print("PARSE DOCTOR ERROR: Missing hospital_id field")
            throw AdminError.invalidData("Missing hospital_id field")
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
        
        // Handle max appointments with fallback
        let maxAppointments: Int
        if let max = data["max_appointments"] as? Int {
            maxAppointments = max
        } else if let maxString = data["max_appointments"] as? String, let max = Int(maxString) {
            maxAppointments = max
        } else {
            print("PARSE DOCTOR WARNING: Missing or invalid max_appointments field, using default")
            maxAppointments = 8
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
        
        // Handle date_of_birth field if it exists
        var dateOfBirth: Date? = nil
        if let dobString = data["dob"] as? String {
            // Try to parse the date of birth with timestampz format
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dateOfBirth = dateFormatter.date(from: dobString)
            
            // If ISO8601 fails, try other formats
            if dateOfBirth == nil {
                let pgFormatter = DateFormatter()
                pgFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                dateOfBirth = pgFormatter.date(from: dobString)
                
                if dateOfBirth == nil {
                    pgFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
                    dateOfBirth = pgFormatter.date(from: dobString)
                    
                    if dateOfBirth == nil {
                        pgFormatter.dateFormat = "yyyy-MM-dd"
                        dateOfBirth = pgFormatter.date(from: dobString)
                    }
                }
            }
            
            if dateOfBirth != nil {
                print("PARSE LAB ADMIN: Found date of birth: \(dobString), parsed as: \(dateOfBirth!)")
            } else {
                print("PARSE LAB ADMIN WARNING: Could not parse dob: '\(dobString)'")
            }
        } else {
            print("PARSE LAB ADMIN INFO: No dob found")
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
            dateOfBirth: dateOfBirth,
            createdAt: createdAt,
            updatedAt: updatedAt,
            maxAppointments: maxAppointments
        )
    }
    
    private func parseLabAdminData(_ data: [String: Any]) throws -> LabAdmin {
        print("PARSE LAB ADMIN: Raw data keys: \(data.keys.joined(separator: ", "))")
        
        // Check for required fields first and log any missing ones
        var missingFields: [String] = []
        
        if data["id"] == nil { missingFields.append("id") }
        if data["hospital_id"] == nil { missingFields.append("hospital_id") }
        if data["name"] == nil { missingFields.append("name") }
        if data["email"] == nil { missingFields.append("email") }
        if data["contact_number"] == nil { missingFields.append("contact_number") }
        if data["department"] == nil { missingFields.append("department") }
        if data["created_at"] == nil { missingFields.append("created_at") }
        if data["updated_at"] == nil { missingFields.append("updated_at") }
        
        if !missingFields.isEmpty {
            let errorMessage = "Missing required fields in lab admin data: \(missingFields.joined(separator: ", "))"
            print("PARSE LAB ADMIN ERROR: \(errorMessage)")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Extract the fields with better error handling
        guard let id = data["id"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'id' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'id' field format"])
        }
        
        guard let hospitalId = data["hospital_id"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'hospital_id' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'hospital_id' field format"])
        }
        
        guard let name = data["name"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'name' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'name' field format"])
        }
        
        guard let email = data["email"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'email' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'email' field format"])
        }
        
        guard let contactNumber = data["contact_number"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'contact_number' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'contact_number' field format"])
        }
        
        guard let department = data["department"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'department' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'department' field format"])
        }
        
        guard let createdAtString = data["created_at"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'created_at' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'created_at' field format"])
        }
        
        guard let updatedAtString = data["updated_at"] as? String else {
            print("PARSE LAB ADMIN ERROR: 'updated_at' field is not a string")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid 'updated_at' field format"])
        }
        
        // Get license_no field if it exists
        let licenseNo = data["license_no"] as? String
        if licenseNo != nil {
            print("PARSE LAB ADMIN: Found license number: \(licenseNo!)")
        } else {
            print("PARSE LAB ADMIN INFO: No license number found")
        }
        
        // Handle experience field (int)
        let experience: Int
        if let expInt = data["experience"] as? Int {
            experience = expInt
            print("PARSE LAB ADMIN: Found experience: \(experience) years")
        } else if let expString = data["experience"] as? String, let expInt = Int(expString) {
            experience = expInt
            print("PARSE LAB ADMIN: Converted experience from string to int: \(experience) years")
        } else {
            experience = 0
            print("PARSE LAB ADMIN WARNING: No valid experience found, using default value of 0")
        }
        
        // Handle date_of_birth field if it exists
        var dateOfBirth: Date? = nil
        if let dobString = data["dob"] as? String {
            // Try to parse the date of birth with timestampz format
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dateOfBirth = dateFormatter.date(from: dobString)
            
            // If ISO8601 fails, try other formats
            if dateOfBirth == nil {
                let pgFormatter = DateFormatter()
                pgFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                dateOfBirth = pgFormatter.date(from: dobString)
                
                if dateOfBirth == nil {
                    pgFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
                    dateOfBirth = pgFormatter.date(from: dobString)
                    
                    if dateOfBirth == nil {
                        pgFormatter.dateFormat = "yyyy-MM-dd"
                        dateOfBirth = pgFormatter.date(from: dobString)
                    }
                }
            }
            
            if dateOfBirth != nil {
                print("PARSE LAB ADMIN: Found date of birth: \(dobString), parsed as: \(dateOfBirth!)")
            } else {
                print("PARSE LAB ADMIN WARNING: Could not parse dob: '\(dobString)'")
            }
        } else {
            print("PARSE LAB ADMIN INFO: No dob found")
        }
        
        // Handle qualifications field (may be an array or might not exist yet)
        let qualification: [String]?
        if let qualArray = data["qualification"] as? [String] {
            qualification = qualArray
            print("PARSE LAB ADMIN: Found qualification array with \(qualArray.count) items")
        } else if let qualString = data["qualification"] as? String {
            // Handle case where it might be stored as comma-separated string
            qualification = qualString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            print("PARSE LAB ADMIN: Converted qualification string to array with \(qualification?.count ?? 0) items")
        } else {
            qualification = nil
            print("PARSE LAB ADMIN WARNING: No qualification data found")
        }
        
        // Parse dates with multiple format support
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try ISO 8601 format first
        var createdAt = dateFormatter.date(from: createdAtString)
        var updatedAt = dateFormatter.date(from: updatedAtString)
        
        // If ISO 8601 fails, try PostgreSQL timestamp format
        if createdAt == nil || updatedAt == nil {
            let pgFormatter = DateFormatter()
            pgFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            
            if createdAt == nil {
                createdAt = pgFormatter.date(from: createdAtString)
            }
            
            if updatedAt == nil {
                updatedAt = pgFormatter.date(from: updatedAtString)
            }
            
            // Try another common PostgreSQL format
            if createdAt == nil || updatedAt == nil {
                pgFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
                
                if createdAt == nil {
                    createdAt = pgFormatter.date(from: createdAtString)
                }
                
                if updatedAt == nil {
                    updatedAt = pgFormatter.date(from: updatedAtString)
                }
            }
        }
        
        // If dates still can't be parsed, use current date as fallback
        let now = Date()
        if createdAt == nil {
            print("PARSE LAB ADMIN WARNING: Could not parse created_at date: '\(createdAtString)', using current date")
            createdAt = now
        }
        
        if updatedAt == nil {
            print("PARSE LAB ADMIN WARNING: Could not parse updated_at date: '\(updatedAtString)', using current date")
            updatedAt = now
        }
        
        // Handle address field which might have inconsistent capitalization
        let address: String
        if let addr = data["Address"] as? String {
            address = addr
        } else if let addr = data["address"] as? String {
            address = addr
        } else {
            address = ""
            print("PARSE LAB ADMIN WARNING: No address field found (neither 'Address' nor 'address'), using empty string")
        }
        
        let labAdmin = LabAdmin(
            id: id,
            hospitalId: hospitalId,
            name: name,
            email: email,
            contactNumber: contactNumber,
            department: department,
            address: address,
            qualification: qualification,
            licenseNo: licenseNo,
            dateOfBirth: dateOfBirth,
            experience: experience, // Add the missing experience parameter
            createdAt: createdAt!,
            updatedAt: updatedAt!
        )
        
        
        print("PARSE LAB ADMIN: Successfully parsed lab admin with ID: \(id), Name: \(name)")
        return labAdmin
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
            throw AdminError.invalidData("Missing required fields in hospital data")
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
            throw AdminError.invalidData("Invalid status format")
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
    
    // MARK: - Debug Methods
    
    /// Verify if a lab admin ID exists in the database (for debugging delete issues)
    func verifyLabAdminExists(id: String) async throws -> [String: Any] {
        print("VERIFY LAB ADMIN: Checking if lab admin with ID \(id) exists")
        
        var result: [String: Any] = [:]
        result["id"] = id
        result["exists"] = false
        
        // First try a direct query for the ID
        do {
            let labAdmins = try await supabase.select(
                from: "lab_admins",
                where: "id",
                equals: id
            )
            
            if labAdmins.isEmpty {
                print("VERIFY LAB ADMIN: No lab admin found with ID \(id)")
                result["exists"] = false
                result["message"] = "Lab admin not found"
            } else {
                print("VERIFY LAB ADMIN: Found lab admin with ID \(id)")
                // Include basic info about the lab admin
                if let data = labAdmins.first {
                    result["exists"] = true
                    result["name"] = data["name"] as? String ?? "Unknown"
                    result["email"] = data["email"] as? String ?? "Unknown"
                    result["message"] = "Lab admin exists in database"
                }
            }
        } catch {
            print("VERIFY LAB ADMIN ERROR: Failed to query database: \(error.localizedDescription)")
            result["error"] = error.localizedDescription
            result["message"] = "Failed to verify lab admin: \(error.localizedDescription)"
            throw error
        }
        
        return result
    }
    
    /// Check for constraints that might prevent deletion
    func checkLabAdminDeletionConstraints(id: String) async throws -> [String: Any] {
        print("CHECK CONSTRAINTS: Checking constraints for lab admin with ID \(id)")
        
        var result: [String: Any] = [:]
        result["id"] = id
        result["canDelete"] = false
        
        // First check if it exists
        do {
            let verifyResult = try await verifyLabAdminExists(id: id)
            if !(verifyResult["exists"] as? Bool ?? false) {
                result["canDelete"] = false
                result["message"] = "Lab admin does not exist"
                return result
            }
        } catch {
            result["error"] = error.localizedDescription
            result["message"] = "Failed to verify lab admin: \(error.localizedDescription)"
            return result
        }
        
        // Check for foreign key constraints in other tables
        // This would depend on your database schema - add checks for each table that might reference lab_admins
        // For example:
        
        /*
        // Example: Check if lab admin has reports
        do {
            let reports = try await supabase.select(
                from: "reports",
                where: "lab_admin_id",
                equals: id
            )
            
            if !reports.isEmpty {
                result["canDelete"] = false
                result["message"] = "Cannot delete lab admin: Has \(reports.count) reports"
                return result
            }
        } catch {
            // Log but don't fail the entire check
            print("CHECK CONSTRAINTS WARNING: Failed to check reports: \(error.localizedDescription)")
        }
        */
        
        // If we get here, assume it can be deleted
        result["canDelete"] = true
        result["message"] = "Lab admin can be safely deleted"
        
        return result
    }
    
    /// Create doctor availability
    func createDoctorAvailability(
        doctorId: String,
        hospitalId: String,
        weeklySchedule: [String: [String: Bool]],
        maxNormalPatients: Int = 5,
        maxPremiumPatients: Int = 2
    ) async throws {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = dateFormatter.string(from: now)
        
        // Create a struct for the availability data
        struct DoctorAvailabilityData: Encodable {
            let doctor_id: String
            let hospital_id: String
            let weekly_schedule: [String: [String: Bool]]
            let effective_from: String
            let max_normal_patients: Int
            let max_premium_patients: Int
            let created_at: String
            let updated_at: String
        }
        
        // Create availability data using the struct
        let availabilityData = DoctorAvailabilityData(
            doctor_id: doctorId,
            hospital_id: hospitalId,
            weekly_schedule: weeklySchedule,
            effective_from: dateFormatter.string(from: now),
            max_normal_patients: maxNormalPatients,
            max_premium_patients: maxPremiumPatients,
            created_at: createdAt,
            updated_at: createdAt
        )
        
        // Insert into doctor_availability_efficient table
        try await supabase.insert(
            into: "doctor_availability_efficient",
            data: availabilityData
        )
    }
    
    // MARK: - Doctor Availability Methods
    
    /// Simple struct to represent doctor availability
    struct DoctorAvailability {
        let doctorId: String
        let weeklySchedule: [String: [String: Bool]]
        let maxNormalPatients: Int
        let maxPremiumPatients: Int
    }
    
    /// Get doctor's availability schedule and patient limits
    func getDoctorAvailability(doctorId: String) async throws -> DoctorAvailability? {
        let availabilityData = try await supabase.select(
            from: "doctor_availability_efficient",
            where: "doctor_id",
            equals: doctorId
        )
        
        guard let data = availabilityData.first,
              let weeklySchedule = data["weekly_schedule"] as? [String: [String: Bool]],
              let maxNormalPatients = data["max_normal_patients"] as? Int,
              let maxPremiumPatients = data["max_premium_patients"] as? Int else {
            return nil
        }
        
        return DoctorAvailability(
            doctorId: doctorId,
            weeklySchedule: weeklySchedule,
            maxNormalPatients: maxNormalPatients,
            maxPremiumPatients: maxPremiumPatients
        )
    }
    
    /// Update doctor's availability schedule and patient limits
    func updateDoctorAvailability(
        doctorId: String,
        weeklySchedule: [String: [String: Bool]],
        maxNormalPatients: Int,
        maxPremiumPatients: Int
    ) async throws {
        struct AvailabilityData: Encodable {
            let weekly_schedule: [String: [String: Bool]]
            let max_normal_patients: Int
            let max_premium_patients: Int
            let updated_at: String
        }
        
        let updateData = AvailabilityData(
            weekly_schedule: weeklySchedule,
            max_normal_patients: maxNormalPatients,
            max_premium_patients: maxPremiumPatients,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        // Check if record exists
        let existingData = try await supabase.select(
            from: "doctor_availability_efficient",
            where: "doctor_id",
            equals: doctorId
        )
        
        if existingData.isEmpty {
            // Insert new record
            struct InsertData: Encodable {
                let doctor_id: String
                let weekly_schedule: [String: [String: Bool]]
                let max_normal_patients: Int
                let max_premium_patients: Int
                let created_at: String
                let updated_at: String
            }
            
            let insertData = InsertData(
                doctor_id: doctorId,
                weekly_schedule: weeklySchedule,
                max_normal_patients: maxNormalPatients,
                max_premium_patients: maxPremiumPatients,
                created_at: ISO8601DateFormatter().string(from: Date()),
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase.insert(into: "doctor_availability_efficient", data: insertData)
        } else {
            // Update existing record
            try await supabase.update(
                table: "doctor_availability_efficient",
                data: updateData,
                where: "doctor_id",
                equals: doctorId
            )
        }
    }
    
    // MARK: - Blood Donation Request Methods
    
    /// Get all patients who are registered as blood donors
    /// Optionally filter by blood group
    func getRegisteredBloodDonors(bloodGroup: String? = nil) async throws -> [BloodDonor] {
        // Get the current admin ID
        guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
            throw AdminError.adminNotFound
        }
        
        // Get all blood donors
        let allDonors = try await supabase.select(
            from: "patients",
            where: "is_blood_donor",
            equals: "true"
        )
        
        var donors: [BloodDonor] = []
        
        for donorData in allDonors {
            guard let patientId = donorData["patient_id"] as? String,
                  let name = donorData["name"] as? String,
                  let donorBloodGroup = donorData["bloodGroup"] as? String,
                  let contactNumber = donorData["phoneNumber"] as? String,
                  let email = donorData["email"] as? String else {
                continue
            }
            
            // If blood group filter is specified, only include matching donors
            if let requestedGroup = bloodGroup {
                // Only return donors with matching blood group
                if donorBloodGroup.lowercased() != requestedGroup.lowercased() {
                    continue // Skip donors with non-matching blood group
                }
            }
            
            // Get the donor's request status
            let donorRequests = try await supabase.select(
                from: "blood_donor_requests",
                where: "donor_id",
                equals: patientId
            )
            
            // Find requests from this admin and for the specified blood group
            let matchingRequests = donorRequests.filter { request in
                guard let requestedByAdmin = request["requested_by_admin"] as? String,
                      let bloodRequestedFor = request["blood_requested_for"] as? String,
                      let requestStatus = request["request_status"] as? String else {
                    return false
                }
                
                let matchesAdmin = requestedByAdmin == adminId
                let matchesBloodGroup = bloodGroup == nil || bloodRequestedFor == bloodGroup
                
                return matchesAdmin && matchesBloodGroup
            }
            
            // Get the most recent request status
            var requestStatus: String? = nil
            if let latestRequest = matchingRequests.first {
                requestStatus = latestRequest["request_status"] as? String
            }
            
            // Create the donor object with request status
            let donor = BloodDonor(
                id: patientId,
                name: name,
                bloodGroup: donorBloodGroup,
                contactNumber: contactNumber,
                email: email,
                requestStatus: requestStatus
            )
            
            donors.append(donor)
        }
        
        return donors
    }
    
    /// Send blood donation request to specified donors
    func sendBloodDonationRequest(donorIds: [String], bloodGroup: String) async throws {
        guard !donorIds.isEmpty else {
            throw AdminError.invalidData("No donors selected")
        }
        
        // Validate blood group against allowed values
        let validBloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
        guard validBloodGroups.contains(bloodGroup) else {
            throw AdminError.invalidData("Invalid blood group: \(bloodGroup)")
        }
        
        // Get the current admin ID from hospital_id key in UserDefaults
        guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
            throw AdminError.adminNotFound
        }
        
        print("BLOOD DONATION: Using admin ID: \(adminId) for blood donation request")
        
        // Define the request data structure that matches table constraints
        struct BloodDonorRequestData: Encodable {
            let donor_id: String
            let requested_by_admin: String
            let blood_requested_for: String
            let requested_activity_status: Bool
            let request_status: String
        }
        
        // Send request to each selected donor
        for donorId in donorIds {
            // Get all requests for this donor
            let donorRequests = try await supabase.select(
                from: "blood_donor_requests",
                where: "donor_id",
                equals: donorId
            )
            
            // Filter for active requests matching our criteria
            let existingActiveRequest = donorRequests.first { request in
                guard let requestedByAdmin = request["requested_by_admin"] as? String,
                      let bloodRequestedFor = request["blood_requested_for"] as? String,
                      let requestedActivityStatus = request["requested_activity_status"] as? Bool,
                      let requestStatus = request["request_status"] as? String else {
                    return false
                }
                
                return requestedByAdmin == adminId &&
                       bloodRequestedFor == bloodGroup &&
                       requestedActivityStatus == true &&
                       (requestStatus == "Pending" || requestStatus == "Accepted")
            }
            
            // If an active request already exists, skip creating a new one
            if existingActiveRequest != nil {
                print("BLOOD DONATION: Active request already exists for donor \(donorId). Skipping.")
                continue
            }
            
            // Always create a new request (even if there was a rejected/cancelled/completed one before)
            let requestData = BloodDonorRequestData(
                donor_id: donorId,
                requested_by_admin: adminId,
                blood_requested_for: bloodGroup,
                requested_activity_status: true,
                request_status: "Pending"
            )
            
            // Insert the request into the database (creating a new row)
            try await supabase.insert(
                into: "blood_donor_requests",
                data: requestData
            )
        }
    }
    
    /// Cancel blood donation request for specified donors
    func cancelBloodDonationRequest(donorIds: [String], bloodGroup: String) async throws {
        guard !donorIds.isEmpty else {
            throw AdminError.invalidData("No donors selected")
        }
        
        // Get the current admin ID from hospital_id key in UserDefaults
        guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
            throw AdminError.adminNotFound
        }
        
        print("BLOOD DONATION: Using admin ID: \(adminId) for canceling blood donation request")
        
        // Define the update data structure
        struct BloodDonorRequestUpdateData: Encodable {
            let requested_activity_status: Bool
            let request_status: String
        }
        
        // Set update data with cancelled status
        let updateData = BloodDonorRequestUpdateData(
            requested_activity_status: false,
            request_status: "Cancelled"
        )
        
        // For each donor, update the request status
        for donorId in donorIds {
            let conditions: [String: String] = [
                "donor_id": donorId,
                "requested_by_admin": adminId,
                "blood_requested_for": bloodGroup
            ]
            
            try await supabase.update(
                table: "blood_donor_requests",
                data: updateData,
                where: conditions
            )
        }
    }
    
    /// Complete blood donation request for specified donors
    func completeBloodDonationRequest(donorIds: [String], bloodGroup: String) async throws {
        guard !donorIds.isEmpty else {
            throw AdminError.invalidData("No donors selected")
        }
        
        // Get the current admin ID from hospital_id key in UserDefaults
        guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
            throw AdminError.adminNotFound
        }
        
        print("BLOOD DONATION: Using admin ID: \(adminId) for completing blood donation request")
        
        // Define the update data structure
        struct BloodDonorRequestUpdateData: Encodable {
            let requested_activity_status: Bool
            let request_status: String
        }
        
        // Set update data with completed status
        let updateData = BloodDonorRequestUpdateData(
            requested_activity_status: true,
            request_status: "Completed"
        )
        
        // For each donor, update the request status
        for donorId in donorIds {
            let conditions: [String: String] = [
                "donor_id": donorId,
                "requested_by_admin": adminId,
                "blood_requested_for": bloodGroup
            ]
            
            try await supabase.update(
                table: "blood_donor_requests",
                data: updateData,
                where: conditions
            )
        }
    }
    
    /// Get blood donation request history for the current admin
    func getBloodDonationRequestHistory() async throws -> [[String: Any]] {
        // Get the current admin ID from hospital_id key in UserDefaults
        guard let adminId = UserDefaults.standard.string(forKey: "hospital_id") else {
            throw AdminError.adminNotFound
        }
        
        // Get all requests for this admin
        let requests = try await supabase.select(
            from: "blood_donor_requests",
            where: "requested_by_admin",
            equals: adminId
        )
        
        // Filter for completed, cancelled, or rejected requests
        let filteredRequests = requests.filter { request in
            guard let requestStatus = request["request_status"] as? String else {
                return false
            }
            
            return requestStatus == "Completed" || requestStatus == "Cancelled" || requestStatus == "Rejected"
        }
        
        // Enrich with donor information
        var enrichedRequests: [[String: Any]] = []
        
        for request in filteredRequests {
            var enrichedRequest = request
            
            // Add donor information if available
            if let donorId = request["donor_id"] as? String {
                let donorInfo = try await supabase.select(
                    from: "patients",
                    where: "patient_id",
                    equals: donorId
                )
                
                if let donor = donorInfo.first {
                    if let name = donor["name"] as? String {
                        enrichedRequest["donor_name"] = name
                    }
                    if let bloodGroup = donor["bloodGroup"] as? String {
                        enrichedRequest["donor_blood_group"] = bloodGroup
                    }
                }
            }
            
            enrichedRequests.append(enrichedRequest)
        }
        
        // Sort by request time (newest first)
        return enrichedRequests.sorted { first, second in
            guard let firstTime = first["blood_requested_time"] as? String,
                  let secondTime = second["blood_requested_time"] as? String else {
                return false
            }
            
            return firstTime > secondTime
        }
    }
    
    // MARK: - Activity Logging
    
    /// Log an activity to the activity_logs table with all details in description field
    func logActivity(action: String, entityType: String, entityId: String, entityName: String, details: [String: Any]? = nil) async {
        // Activity logging disabled
        print("ADMIN: Activity logging is disabled")
        /*
        do {
            print("ADMIN: Logging activity - \(action) \(entityType): \(entityName)")
            
            let now = Date()
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let timestamp = dateFormatter.string(from: now)
            
            // Format detailed description to include all information
            var actionVerb = ""
            switch action.lowercased() {
            case "create": actionVerb = "Added"
            case "update": actionVerb = "Updated"
            case "delete": actionVerb = "Deleted"
            case "login": actionVerb = "Login by"
            default: actionVerb = action.capitalized
            }
            
            // Create a structured description with all important details
            var descriptionParts = ["\(actionVerb) \(entityType): \(entityName)"]
            descriptionParts.append("ID: \(entityId)")
            
            // Add hospital ID if available
            if let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") {
                descriptionParts.append("Hospital: \(hospitalId)")
            }
            
            // Add user ID if available
            if let userId = UserDefaults.standard.string(forKey: "hospitalAdminId") {
                descriptionParts.append("User: \(userId)")
            }
            
            // Add important details if provided
            if let details = details {
                for (key, value) in details {
                    // Only include non-empty values
                    if let stringValue = value as? String, !stringValue.isEmpty {
                        descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(stringValue)")
                    } else if let intValue = value as? Int {
                        descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(intValue)")
                    } else if let doubleValue = value as? Double {
                        descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(doubleValue)")
                    } else if let boolValue = value as? Bool {
                        descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(boolValue)")
                    } else if let dateValue = value as? Date {
                        descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(dateFormatter.string(from: dateValue))")
                    } else if value is NSNull {
                        // Skip null values
                    } else {
                        let stringValue = String(describing: value)
                        if stringValue != "nil" && !stringValue.isEmpty {
                            descriptionParts.append("\(key.replacingOccurrences(of: "_", with: " ").capitalized): \(stringValue)")
                        }
                    }
                }
            }
            
            // Combine all parts with semicolons for easier parsing
            let description = descriptionParts.joined(separator: "; ")
            
            // Create an encodable struct for inserting into the database
            struct ActivityLogData: Encodable {
                let created_at: String
                let description: String
            }
            
            let activityLogData = ActivityLogData(
                created_at: timestamp,
                description: description
            )
            
            // Insert into database
            try await supabase.insert(
                into: "activity_logs",
                data: activityLogData
            )
            
            print("ADMIN: Successfully logged activity")
        } catch {
            print("ADMIN ERROR: Failed to log activity: \(error.localizedDescription)")
        }
        */
    }
    
    // Backwards compatibility method
    func logActivity(description: String, remarks: String? = nil) async {
        // Activity logging disabled
        print("ADMIN: Activity logging is disabled (legacy method)")
        /*
        let parts = description.split(separator: ":")
        let action = (parts.first?.contains("Added") ?? false) ? "create" : 
                     (parts.first?.contains("Updated") ?? false) ? "update" : 
                     (parts.first?.contains("Deleted") ?? false) ? "delete" : "action"
        
        let entityType = description.lowercased().contains("doctor") ? "doctor" : 
                        description.lowercased().contains("lab admin") ? "lab_admin" : 
                        "entity"
        
        let entityName = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : "Unknown"
        let entityId = "unknown"
        
        await logActivity(
            action: action,
            entityType: entityType,
            entityId: entityId,
            entityName: entityName,
            details: remarks != nil ? ["note": remarks!] : nil
        )
        */
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
    case invalidData(String)
    case doctorDeleteFailed
    case invalidContactNumber(String)
    case invalidFormat(String)
    case invalidPassword(message: String)
    case emailAlreadyExists(String)
    case customError(String)
    
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
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .doctorDeleteFailed:
            return "Failed to delete doctor"
        case .invalidContactNumber(let message):
            return "Invalid contact number: \(message)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .invalidPassword(let message):
            return "Invalid password: \(message)"
        case .emailAlreadyExists(let message):
            return "Email already exists: \(message)"
        case .customError(let message):
            return message
        }
    }
} 
