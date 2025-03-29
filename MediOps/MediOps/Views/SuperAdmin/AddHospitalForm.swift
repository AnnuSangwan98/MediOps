//
//  AddHospitalForm.swift
//  MediOps
//
//  Created by Aryan Shukla on 24/03/25.
//

import SwiftUI
import PhotosUI

struct AddHospitalForm: View {
    // Add Supabase controller
    private let supabase = SupabaseController.shared
    
    // Add Encodable structures for data
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
        let password: String
    }
    
    private struct AdminData: Encodable {
        let hospital_id: String
        let admin_name: String
        let email: String
        let contact_number: String
        let id: String
        let password: String
        let role: String
        let status: String
    }
    
    private struct EmailDetails: Encodable {
        let fullName: String
        let hospitalName: String
        let hospitalId: String
        let licenseNumber: String
        let accreditation: String
        let emergencyContact: String
        let street: String
        let city: String
        let state: String
        let zipCode: String
        let adminLocality: String
        let adminCity: String
        let adminState: String
        let adminPinCode: String
        let adminPhone: String
        let password: String
    }
    
    private struct EmailPayload: Encodable {
        let to: String
        let accountType: String
        let details: EmailDetails
    }
    
    private struct EmailServerResponse: Decodable {
        let status: String
        let password: String
        let id: String
    }
    
    // Hospital Information
    @State private var hospitalImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @Binding var hospitalName: String
    @Binding var hospitalID: String
    @Binding var licenseNumber: String
    @State private var selectedAccreditation: String = "NABH"
    @Binding var emergencyContact: String
    
    // Hospital Address
    @Binding var street: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    
    // Admin Information
    @Binding var adminName: String
    @Binding var phone: String
    @Binding var email: String
    @State private var adminLocality: String = ""
    @State private var adminCity: String = ""
    @State private var selectedAdminState: String = "Delhi"
    @State private var adminPinCode: String = ""
    
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Validation States
    @State private var showValidationErrors = false
    @State private var emailError = ""
    @State private var phoneError = ""
    @State private var hospitalPinCodeError = ""
    @State private var adminPinCodeError = ""
    @State private var hospitalIdError = ""
    @State private var hospitalLicenseError = ""
    @State private var emergencyContactError = ""
    @State private var isEmailSending = false
    @State private var showEmailError = false
    @State private var emailSendingError = ""
    @State private var hasSubmitted = false
    
    // Constants
    let accreditationTypes = ["NABH", "JCI", "ACHSI", "COHSASA", "Other"]
    let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Delhi",
        "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
        "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
        "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
        "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ]
    
    // Section toggle states
    @State private var hospitalInfoExpanded = true
    @State private var hospitalAddressExpanded = false
    @State private var adminInfoExpanded = false
    @State private var adminAddressExpanded = false
    
    private var isFormValid: Bool {
        // Updated validation to match schema requirements
        !hospitalName.isEmpty && 
        !licenseNumber.isEmpty && 
        !city.isEmpty &&
        !state.isEmpty && 
        !zipCode.isEmpty && 
        !adminName.isEmpty && 
        !phone.isEmpty &&
        !email.isEmpty &&
        !emergencyContact.isEmpty &&
        selectedAccreditation != "Other" // Must be one of the allowed values
    }
    
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
        
        // Validate Email (must be unique due to constraint)
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            emailError = "Please enter a valid email address"
            isValid = false
        }
        
        // Validate Phone Numbers (20 chars max per schema)
        if phone.count != 10 || !phone.allSatisfy({ $0.isNumber }) {
            phoneError = "Please enter a valid 10-digit phone number"
            isValid = false
        }
        
        // Validate Emergency Contact
        if emergencyContact.count != 10 || !emergencyContact.allSatisfy({ $0.isNumber }) {
            emergencyContactError = "Please enter a valid 10-digit emergency number"
            isValid = false
        }
        
        // Validate Pin Codes (10 chars max per schema)
        if zipCode.count != 6 || !zipCode.allSatisfy({ $0.isNumber }) {
            hospitalPinCodeError = "Please enter a valid 6-digit pin code"
            isValid = false
        }
        
        if adminPinCode.count != 6 || !adminPinCode.allSatisfy({ $0.isNumber }) {
            adminPinCodeError = "Please enter a valid 6-digit pin code"
            isValid = false
        }
        
        // Validate Hospital License Number
        let licenseRegex = "^[A-Z]{2}\\d{5}$"
        if !NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: licenseNumber) {
            hospitalLicenseError = "License number must be 2 capital letters followed by 4 digits (e.g., XX12345)"
            isValid = false
        }
        
        // Validate Accreditation (must match check constraint)
        if !["NABH", "JCI", "NABL", "ISO"].contains(selectedAccreditation) {
            isValid = false
        }
        
        showValidationErrors = !isValid
        return isValid
    }
    
    private func handleSubmit() {
        guard !hasSubmitted && validateForm() else { return }
        
        hasSubmitted = true
        isEmailSending = true
        
        Task {
            do {
                // First send email to get the generated credentials
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
                    password: ""  // Password will be generated by the server
                )
                
                let emailPayload = EmailPayload(
                    to: email,
                    accountType: "hospital",
                    details: emailDetails
                )
                
                let jsonData = try JSONEncoder().encode(emailPayload)
                request.httpBody = jsonData
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Print the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw server response:", responseString)
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server returned error status"])
                }
                
                // Decode the response using the proper structure
                let serverResponse = try JSONDecoder().decode(EmailServerResponse.self, from: data)
                guard serverResponse.status == "success",
                      !serverResponse.password.isEmpty else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
                }
                
                let generatedPassword = serverResponse.password
                print("Generated password from server:", generatedPassword)
                
                // Convert hospital image to base64 if available
                let imageBase64: String = {
                    if let hospitalImage = hospitalImage,
                       let imageData = hospitalImage.jpegData(compressionQuality: 0.5) {
                        return imageData.base64EncodedString()
                    }
                    return ""
                }()
                
                // Create hospital data with the provided hospitalID and generated password
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
                    description: "Hospital created by Super Admin",
                    password: generatedPassword  // Use the generated password
                )
                
                print("Inserting hospital with data:", hospitalData)
                
                // Insert hospital
                try await supabase.insert(into: "hospitals", data: hospitalData)
                
                // Create admin data using the same hospitalID and generated password
                let adminData = AdminData(
                    hospital_id: hospitalID,
                    admin_name: adminName,
                    email: email,
                    contact_number: phone,
                    id: hospitalID,
                    password: generatedPassword,  // Use the generated password from email server
                    role: "HOSPITAL_ADMIN",
                    status: "active"
                )
                
                print("Inserting admin with data:", adminData)
                
                // Insert admin data
                try await supabase.insert(into: "hospital_admins", data: adminData)
                
                await MainActor.run {
                    onSubmit()
                    isEmailSending = false
                    dismiss()
                }
            } catch {
                print("Error submitting form:", error)
                await MainActor.run {
                    emailSendingError = error.localizedDescription
                    showEmailError = true
                    isEmailSending = false
                    hasSubmitted = false
                    
                    // If admin creation fails, attempt to rollback hospital creation
                    if error.localizedDescription.contains("hospital_admins") {
                        Task {
                            try? await supabase.delete(from: "hospitals", where: "id", equals: hospitalID)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        Form {
            // Hospital Information Section
            Section {
                DisclosureGroup(
                    isExpanded: $hospitalInfoExpanded,
                    content: {
                        // Hospital Image
                        HStack {
                            Text("Hospital Image")
                            Spacer()
                            PhotosPicker(selection: $imageSelection, matching: .images) {
                                if let hospitalImage = hospitalImage {
                                    Image(uiImage: hospitalImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .frame(width: 80, height: 80)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .onChange(of: imageSelection) { newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    if let image = UIImage(data: data) {
                                        hospitalImage = image
                                    }
                                }
                            }
                        }
                        
                        TextField("Hospital Name", text: $hospitalName)
                        
                        TextField("Hospital ID (HOSXXX)", text: $hospitalID)
                            .onChange(of: hospitalID) { _, newValue in
                                hospitalID = newValue.uppercased()
                            }
                            
                        if !hospitalIdError.isEmpty {
                            Text(hospitalIdError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        TextField("License Number (XX12345)", text: $licenseNumber)
                            .onChange(of: licenseNumber) { _, newValue in
                                licenseNumber = newValue.uppercased()
                            }
                        if !hospitalLicenseError.isEmpty {
                            Text(hospitalLicenseError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Picker("Accreditation", selection: $selectedAccreditation) {
                            ForEach(accreditationTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        
                        HStack {
                            Text("+91")
                                .foregroundColor(.gray)
                            TextField("Emergency Contact", text: $emergencyContact)
                                .keyboardType(.numberPad)
                                .onChange(of: emergencyContact) { _, newValue in
                                    // Allow only digits and limit to 10 characters
                                    emergencyContact = newValue.filter { $0.isNumber }.prefix(10).description
                                }
                        }
                        if !emergencyContactError.isEmpty {
                            Text(emergencyContactError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.teal)
                            Text("HOSPITAL INFORMATION")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
            
            // Hospital Address Section
            Section {
                DisclosureGroup(
                    isExpanded: $hospitalAddressExpanded,
                    content: {
                        TextField("Street/Locality", text: $street)
                        TextField("City", text: $city)
                        
                        Picker("State", selection: $state) {
                            ForEach(indianStates, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                        
                        TextField("Pin Code", text: $zipCode)
                            .keyboardType(.numberPad)
                            .onChange(of: zipCode) { _, newValue in
                                // Allow only digits and limit to 10 characters
                                zipCode = newValue.filter { $0.isNumber }.prefix(6).description
                            }
                        if !hospitalPinCodeError.isEmpty {
                            Text(hospitalPinCodeError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.teal)
                            Text("HOSPITAL ADDRESS")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
            
            // Admin Information Section
            Section {
                DisclosureGroup(
                    isExpanded: $adminInfoExpanded,
                    content: {
                        TextField("Admin Name", text: $adminName)
                        
                        HStack {
                            Text("+91")
                                .foregroundColor(.gray)
                            TextField("Contact Number", text: $phone)
                                .keyboardType(.numberPad)
                                .onChange(of: phone) { _, newValue in
                                    // Allow only digits and limit to 10 characters
                                    phone = newValue.filter { $0.isNumber }.prefix(10).description
                                }
                        }
                        if !phoneError.isEmpty {
                            Text(phoneError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        if !emailError.isEmpty {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.teal)
                            Text("ADMIN INFORMATION")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
            
            // Admin Address Section
            Section {
                DisclosureGroup(
                    isExpanded: $adminAddressExpanded,
                    content: {
                        TextField("Locality", text: $adminLocality)
                        TextField("City", text: $adminCity)
                        
                        Picker("State", selection: $selectedAdminState) {
                            ForEach(indianStates, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                        
                        TextField("Pin Code", text: $adminPinCode)
                            .keyboardType(.numberPad)
                            .onChange(of: adminPinCode) { _, newValue in
                                // Allow only digits and limit to 10 characters
                                adminPinCode = newValue.filter { $0.isNumber }.prefix(6).description
                            }
                        if !adminPinCodeError.isEmpty {
                            Text(adminPinCodeError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    },
                    label: {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.teal)
                            Text("ADMIN ADDRESS")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Add Hospital")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.teal)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: handleSubmit) {
                    if isEmailSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(hasSubmitted ? "Saved" : "Save")
                    }
                }
                .disabled(!isFormValid || hasSubmitted || isEmailSending)
                .foregroundColor(isFormValid && !hasSubmitted && !isEmailSending ? .teal : .gray)
            }
        }
        .alert("Email Error", isPresented: $showEmailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(emailSendingError)
        }
        .interactiveDismissDisabled(isEmailSending) // Prevent dismissal while sending email
    }
}

struct EditHospitalForm: View {
    private let supabase = SupabaseController.shared
    @State private var editedHospital: Hospital
    @State private var adminData: [String: Any]? = nil
    let onSave: (Hospital) -> Void
    
    // UI states
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // Section toggle states
    @State private var hospitalInfoExpanded = true
    @State private var adminInfoExpanded = false
    
    init(hospital: Hospital, onSave: @escaping (Hospital) -> Void) {
        _editedHospital = State(initialValue: hospital)
        self.onSave = onSave
    }
    
    private func fetchAdminData() {
        Task {
            do {
                // Use AdminController to fetch hospital admin data instead of SupabaseController
                let adminController = AdminController.shared
                let hospitalAdmin = try await adminController.getHospitalAdmin(id: editedHospital.id)
                
                await MainActor.run {
                    // Update fields with data from the HospitalAdmin model
                    editedHospital.adminName = hospitalAdmin.name
                    // Note: hospitalAdmin might not have phone and email fields directly
                    // So we'll keep the existing values
                }
            } catch {
                print("Error fetching admin data: \(error.localizedDescription)")
                // We'll continue even if admin data fetch fails
            }
        }
    }
    
    var body: some View {
        Form {
            // HOSPITAL INFORMATION
            Section {
                DisclosureGroup(
                    isExpanded: $hospitalInfoExpanded,
                    content: {
                        TextField("Hospital Name", text: $editedHospital.name)
                        
                        // Display hospital ID as non-editable text
                        HStack {
                            Text("Hospital ID")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(editedHospital.id)
                                .foregroundColor(.teal)
                        }
                        
                        TextField("License Number", text: $editedHospital.licenseNumber)
                            .textCase(.uppercase)
                            .placeholder(when: editedHospital.licenseNumber.isEmpty) {
                                Text("Enter state license (e.g., XX12345)")
                                    .foregroundColor(.gray)
                            }
                            
                        // Hospital address fields
                        Text("Hospital Address")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                        
                        TextField("Street", text: $editedHospital.street)
                        TextField("City", text: $editedHospital.city)
                        TextField("State", text: $editedHospital.state)
                        TextField("Pin Code", text: $editedHospital.zipCode)
                            .keyboardType(.numberPad)
                        
                        // Hospital contact
                        Text("Hospital Contact")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                            
                        HStack {
                            Text("+91")
                                .foregroundColor(.gray)
                            TextField("Emergency Contact", text: $editedHospital.hospitalPhone)
                                .keyboardType(.numberPad)
                        }
                        
                        Picker("Hospital Status", selection: $editedHospital.status) {
                            Text("Active").tag(HospitalStatus.active)
                            Text("Pending").tag(HospitalStatus.pending)
                            Text("Inactive").tag(HospitalStatus.inactive)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    },
                    label: {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.teal)
                            Text("HOSPITAL INFORMATION")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
            
            // ADMIN INFORMATION
            Section {
                DisclosureGroup(
                    isExpanded: $adminInfoExpanded,
                    content: {
                        TextField("Admin Name", text: $editedHospital.adminName)
                        
                        Text("Admin Contact")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                            
                        HStack {
                            Text("+91")
                                .foregroundColor(.gray)
                            TextField("Admin Phone", text: $editedHospital.phone)
                                .keyboardType(.numberPad)
                        }
                        
                        TextField("Email", text: $editedHospital.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    },
                    label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.teal)
                            Text("ADMIN INFORMATION")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                )
            }
            
            Section {
                Button(action: saveChanges) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save Changes")
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.teal)
                .disabled(isLoading)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .interactiveDismissDisabled(isLoading)
        .onAppear {
            fetchAdminData()
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        // Update the last modified fields
        editedHospital.lastModified = Date()
        editedHospital.lastModifiedBy = "Super Admin"
        
        // First call the onSave callback for updating hospital data
        onSave(editedHospital)
        
        // Then update the admin data in the hospital_admins table
        Task {
            do {
                struct AdminUpdateData: Encodable {
                    let admin_name: String
                    let email: String 
                    let contact_number: String
                }
                
                let adminUpdate = AdminUpdateData(
                    admin_name: editedHospital.adminName,
                    email: editedHospital.email,
                    contact_number: editedHospital.phone
                )
                
                try await supabase.update(
                    table: "hospital_admins",
                    data: adminUpdate,
                    where: "hospital_id",
                    equals: editedHospital.id
                )
                
                print("SUPABASE: Successfully updated admin data for hospital \(editedHospital.id)")
                
            } catch {
                print("Error updating admin data: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to update admin information: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AddHospitalForm(
        hospitalName: .constant(""),
        hospitalID: .constant(""),
        licenseNumber: .constant(""),
        emergencyContact: .constant(""),
        street: .constant(""),
        city: .constant(""),
        state: .constant(""),
        zipCode: .constant(""),
        adminName: .constant(""),
        phone: .constant(""),
        email: .constant(""),
        onSubmit: {}
    )
}

