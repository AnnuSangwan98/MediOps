    private func validateForm() -> Bool {
        var isValid = true
        
        // Reset errors
        emailError = ""
        phoneError = ""
        hospitalPinCodeError = ""
        adminPinCodeError = ""
        hospitalLicenseError = ""
        emergencyContactError = ""
        hospitalIdError = ""
        
        // Validate Hospital ID format (HOSXXX where X is a digit)
        let hospitalIdRegex = "^HOS\\d{3}$"
        if !NSPredicate(format: "SELF MATCHES %@", hospitalIdRegex).evaluate(with: hospitalID) {
            hospitalIdError = "Hospital ID must be 'HOS' followed by 3 digits (e.g., HOS123)"
            isValid = false
        }
        
        // Validate Email
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            emailError = "Please enter a valid email address"
            isValid = false
        } else if email.count > 100 { // Limiting email to 100 characters
            emailError = "Email address is too long (maximum 100 characters)"
            isValid = false
        }
        
        // Validate Phone Numbers (must be 10 digits)
        if !phone.allSatisfy({ $0.isNumber }) || phone.count != 10 {
            phoneError = "Phone number must be 10 digits"
            isValid = false
        }
        
        if !emergencyContact.allSatisfy({ $0.isNumber }) || emergencyContact.count != 10 {
            emergencyContactError = "Emergency contact must be 10 digits"
            isValid = false
        }
        
        // Validate Pin Codes (must be 6 digits)
        if !zipCode.allSatisfy({ $0.isNumber }) || zipCode.count != 6 {
            hospitalPinCodeError = "Pin code must be 6 digits"
            isValid = false
        }
        
        if !adminPinCode.allSatisfy({ $0.isNumber }) || adminPinCode.count != 6 {
            adminPinCodeError = "Pin code must be 6 digits"
            isValid = false
        }
        
        // Validate License Number (format: UP1234)
        let licenseRegex = "^[A-Z]{2}\\d{4}$"
        if !NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: licenseNumber) {
            hospitalLicenseError = "License number must be 2 state letters followed by 4 digits (e.g., UP1234)"
            isValid = false
        }
        
        return isValid
    }

    private struct HospitalData: Encodable {
        let id: String
        let hospital_name: String
        let hospital_address: String
        let hospital_state: String
        let hospital_city: String
        let area_pincode: String
        let email: String
        let contact_number: String
        let emergency_contact_number: String
        let licence: String
        let hospital_accreditation: String
        let type: String
        let departments: [String]
        let status: String
        let hospital_profile_image: String
        let description: String
        
        init(id: String, hospital_name: String, hospital_address: String, hospital_state: String,
             hospital_city: String, area_pincode: String, email: String, contact_number: String,
             emergency_contact_number: String, licence: String, hospital_accreditation: String,
             type: String, departments: [String], status: String, hospital_profile_image: String,
             description: String) {
            self.id = id
            self.hospital_name = hospital_name
            self.hospital_address = hospital_address
            self.hospital_state = hospital_state
            self.hospital_city = hospital_city
            self.area_pincode = area_pincode
            // Trim and normalize email
            self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.contact_number = contact_number
            self.emergency_contact_number = emergency_contact_number
            self.licence = licence
            self.hospital_accreditation = hospital_accreditation
            self.type = type
            self.departments = departments
            self.status = status
            self.hospital_profile_image = hospital_profile_image
            self.description = description
        }
    }
    
    private struct AdminData: Encodable {
        let hospital_id: String
        let admin_name: String
        let email: String
        let contact_number: String
        let id: String
        let password: String
        let role: String = "HOSPITAL_ADMIN"  // Fixed role for hospital admins
        let status: String = "active"
        
        init(hospital_id: String, admin_name: String, email: String, contact_number: String,
             id: String, password: String) {
            self.hospital_id = hospital_id
            self.admin_name = admin_name
            self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.contact_number = contact_number
            self.id = id
            self.password = password
        }
    }

    private func handleSubmit() {
        guard !hasSubmitted && validateForm() else { return }
        
        hasSubmitted = true
        isEmailSending = true
        
        Task {
            do {
                // Convert hospital image to base64 if available
                let imageBase64: String = {
                    if let hospitalImage = hospitalImage,
                       let imageData = hospitalImage.jpegData(compressionQuality: 0.5) {
                        return imageData.base64EncodedString()
                    }
                    return ""
                }()
                
                // Create hospital data with the provided hospitalID
                let hospitalData = HospitalData(
                    id: hospitalID,
                    hospital_name: hospitalName,
                    hospital_address: street,
                    hospital_state: state,
                    hospital_city: city,
                    area_pincode: zipCode,
                    email: email,
                    contact_number: phone,
                    emergency_contact_number: emergencyContact,
                    licence: licenseNumber,
                    hospital_accreditation: selectedAccreditation,
                    type: "General",
                    departments: ["General"],
                    status: "active",
                    hospital_profile_image: imageBase64,
                    description: "Hospital created by Super Admin"
                )
                
                print("Inserting hospital with data:", hospitalData)
                
                // Insert hospital
                try await supabase.insert(into: "hospitals", data: hospitalData)
                
                // Default password for admin
                let defaultPassword = "Pass@123"
                
                // Create admin data using the same hospitalID
                let adminData = AdminData(
                    hospital_id: hospitalID,
                    admin_name: adminName,
                    email: email,
                    contact_number: phone,
                    id: hospitalID,
                    password: defaultPassword
                )
                
                print("Inserting admin with data:", adminData)
                
                // Insert admin data
                try await supabase.insert(into: "hospital_admins", data: adminData)
                
                // Send email with credentials
                let url = URL(string: "http://localhost:8082/send-credentials")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let emailDetails = EmailDetails(
                    fullName: adminName,
                    hospitalName: hospitalName,
                    hospitalId: hospitalID,
                    licenseNumber: licenseNumber,
                    accreditation: selectedAccreditation,
                    emergencyContact: emergencyContact,
                    street: street,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    adminLocality: adminLocality,
                    adminCity: adminCity,
                    adminState: selectedAdminState,
                    adminPinCode: adminPinCode,
                    adminPhone: phone,
                    password: defaultPassword
                )
                
                let emailPayload = EmailPayload(
                    to: email,
                    accountType: "hospital",
                    details: emailDetails
                )
                
                let jsonData = try JSONEncoder().encode(emailPayload)
                request.httpBody = jsonData
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            onSubmit()
                            isEmailSending = false
                            dismiss()
                        }
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to send email"])
                    }
                }
            } catch {
                print("Error submitting form:", error)
                await MainActor.run {
                    emailSendingError = error.localizedDescription
                    showEmailError = true
                    isEmailSending = false
                    hasSubmitted = false
                }
            }
        }
    } 