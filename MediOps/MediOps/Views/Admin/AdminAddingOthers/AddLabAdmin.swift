//
//  AddLabAdmin.swift
//  MediOps
//
//  Created by Sharvan on 22/03/25.
//

import SwiftUI

struct AddLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: UILabAdmin.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var qualification = ""
    @State private var license = ""
    @State private var address = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onSave: (UIActivity) -> Void
    
    // Calculate maximum experience based on age
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25) // Experience should be 25 years less than admin's age
    }
    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !qualification.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UILabAdmin.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              displayedComponents: .date)
                    .onChange(of: dateOfBirth) { _, _ in
                        // Adjust experience if it exceeds the maximum allowed
                        if experience > maximumExperience {
                            experience = maximumExperience
                        }
                    }
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    TextField("License (XX12345)", text: $license)
                        .onChange(of: license) { _, newValue in
                            // Format license to uppercase
                            license = newValue.uppercased()
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                        .onChange(of: experience) { _, newValue in
                            // Enforce the maximum experience constraint
                            if newValue > maximumExperience {
                                experience = maximumExperience
                            }
                        }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                // Keep only digits and limit to 10
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Add Lab Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLabAdmin()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func saveLabAdmin() {
        guard isFormValid else { return }
        
        // Create a new lab admin with full formatted phone number
        let labAdmin = UILabAdmin(
            fullName: fullName,
            email: email,
            phone: "+91\(phoneNumber)",
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            address: address
        )

        let activity = UIActivity(
            type: .labAdminAdded,
            title: "New Lab Admin: \(labAdmin.fullName)",
            timestamp: Date(),
            status: .pending,
            doctorDetails: nil,
            labAdminDetails: labAdmin
        )

        sendLabCredentials(activity: activity)
    }
    
    private func sendLabCredentials(activity: UIActivity) {
        guard let url = URL(string: "http://localhost:8082/send-credentials") else {
            alertMessage = "Invalid server URL"
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let emailData: [String: Any] = [
            "to": email,
            "accountType": "lab_admin",
            "details": [
                "fullName": fullName,
                "email": email,
                "phone": "+91\(phoneNumber)",
                "qualification": qualification,
                "license": license,
                "labName": "Main Laboratory",
                "labId": "LAB001"
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        switch error.code {
                        case NSURLErrorTimedOut:
                            self.alertMessage = "Request timed out. Please try again."
                        case NSURLErrorNotConnectedToInternet:
                            self.alertMessage = "No internet connection. Please check your network settings."
                        case NSURLErrorCannotConnectToHost:
                            self.alertMessage = "Cannot connect to server. Please try again later."
                        default:
                            self.alertMessage = "Network error: \(error.localizedDescription)"
                        }
                        self.showAlert = true
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            // Show success message
                            self.alertMessage = "Credentials sent successfully to \(email)"
                            self.showAlert = true
                            // Call onSave callback with the new activity
                            self.onSave(activity)
                            // Dismiss the view immediately after successful save
                            self.dismiss()
                        } else {
                            self.alertMessage = "Failed to send credentials email (Status: \(httpResponse.statusCode))"
                            self.showAlert = true
                        }
                    }
                }
            }.resume()
        } catch {
            alertMessage = "Failed to prepare email data"
            showAlert = true
        }
    }
    
    private func resetForm() {
        fullName = ""
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        qualification = ""
        license = ""
        address = ""
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
}
