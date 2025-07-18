//
//  AddHospitalForm.swift
//  MediOps
//
//  Created by Sharvan on 22/03/25.
//

import SwiftUI

struct AddHospitalForm: View {
    @Binding var hospitalName: String
    @Binding var adminName: String
    @Binding var licenseNumber: String
    @Binding var street: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var phone: String
    @Binding var email: String
    let onSubmit: () -> Void
    
    @State private var showValidationErrors = false
    @State private var emailError = ""
    @State private var phoneError = ""
    @State private var pinCodeError = ""
    @State private var hospitalIdError = ""
    @State private var isEmailSending = false
    @State private var showEmailError = false
    @State private var emailSendingError = ""
    
    private func validateForm() -> Bool {
        var isValid = true
        
        // Reset previous errors
        emailError = ""
        phoneError = ""
        pinCodeError = ""
        hospitalIdError = ""
        
        // Validate Hospital ID format
        if !licenseNumber.hasPrefix("HOS") || licenseNumber.count != 6 {
            hospitalIdError = "Hospital ID must start with HOS followed by 3 digits"
            isValid = false
        }
        
        // Validate email format
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            emailError = "Please enter a valid email address"
            isValid = false
        }
        
        // Validate phone number
        if phone.count != 10 || !phone.allSatisfy({ $0.isNumber }) {
            phoneError = "Please enter a valid 10-digit phone number"
            isValid = false
        }
        
        // Validate pin code
        if zipCode.count != 6 || !zipCode.allSatisfy({ $0.isNumber }) {
            pinCodeError = "Please enter a valid 6-digit pin code"
            isValid = false
        }
        
        showValidationErrors = !isValid
        return isValid
    }
    
    var body: some View {
        Form {
            Section(header: Text("Hospital Information")) {
                TextField("Hospital Name", text: $hospitalName)
                TextField("Admin Name", text: $adminName)
                TextField("Hospital ID", text: $licenseNumber)
                    .placeholder(when: licenseNumber.isEmpty) {
                        Text("Hospital ID (HOSXXX)")
                            .foregroundColor(.gray)
                    }
                if !hospitalIdError.isEmpty {
                    Text(hospitalIdError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Address")) {
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Pin Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .placeholder(when: zipCode.isEmpty) {
                        Text("Pin Code eg: 123456")
                            .foregroundColor(.gray)
                    }
                if !pinCodeError.isEmpty {
                    Text(pinCodeError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Contact Information")) {
                HStack {
                    Text("+91")
                        .foregroundColor(.gray)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.numberPad)
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
            }
            
            if !hospitalName.isEmpty && !adminName.isEmpty && !licenseNumber.isEmpty && !street.isEmpty &&
               !city.isEmpty && !state.isEmpty && !zipCode.isEmpty &&
               !phone.isEmpty && !email.isEmpty {
                Section {
                    Button("Submit") {
                        if validateForm() {
                            isEmailSending = true
                            // Send credentials email
                            Task {
                                do {
                                    let url = URL(string: "http://localhost:8082/send-credentials")!
                                    var request = URLRequest(url: url)
                                    request.httpMethod = "POST"
                                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                    
                                    let details: [String: Any] = [
                                        "fullName": adminName,
                                        "hospitalName": hospitalName,
                                        "hospitalId": licenseNumber,
                                        "licenseNumber": licenseNumber,
                                        "street": street,
                                        "city": city,
                                        "state": state,
                                        "zipCode": zipCode,
                                        "phone": phone
                                    ]
                                    
                                    let payload: [String: Any] = [
                                        "to": email,
                                        "accountType": "hospital",
                                        "details": details
                                    ]
                                    
                                    let jsonData = try JSONSerialization.data(withJSONObject: payload)
                                    request.httpBody = jsonData
                                    
                                    let (data, response) = try await URLSession.shared.data(for: request)
                                    
                                    if let httpResponse = response as? HTTPURLResponse {
                                        if httpResponse.statusCode == 200 {
                                            await MainActor.run {
                                                onSubmit()
                                                isEmailSending = false
                                            }
                                        } else {
                                            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to send email"])
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        emailSendingError = error.localizedDescription
                                        showEmailError = true
                                        isEmailSending = false
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct EditHospitalForm: View {
    @State private var editedHospital: Hospital
    let onSave: (Hospital) -> Void
    
    init(hospital: Hospital, onSave: @escaping (Hospital) -> Void) {
        _editedHospital = State(initialValue: hospital)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section(header: Text("Hospital Information")) {
                TextField("Hospital Name", text: $editedHospital.name)
                TextField("Admin Name", text: $editedHospital.adminName)
                TextField("Hospital ID", text: $editedHospital.licenseNumber)
                    .placeholder(when: editedHospital.licenseNumber.isEmpty) {
                        Text("Hospital ID (HOSXXX)")
                            .foregroundColor(.gray)
                    }
            }
            
            Section(header: Text("Address")) {
                TextField("Street", text: $editedHospital.street)
                TextField("City", text: $editedHospital.city)
                TextField("State", text: $editedHospital.state)
                TextField("Pin Code", text: $editedHospital.zipCode)
                    .keyboardType(.numberPad)
                    .placeholder(when: editedHospital.zipCode.isEmpty) {
                        Text("Pin Code eg: 123456")
                            .foregroundColor(.gray)
                    }
            }
            
            Section(header: Text("Contact Information")) {
                TextField("Phone", text: $editedHospital.phone)
                TextField("Email", text: $editedHospital.email)
            }
            
            Section {
                Button("Save Changes") {
                    editedHospital.lastModified = Date()
                    editedHospital.lastModifiedBy = "Super Admin"
                    onSave(editedHospital)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
    }
}

