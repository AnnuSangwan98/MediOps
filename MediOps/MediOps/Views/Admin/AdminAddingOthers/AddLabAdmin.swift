//
//  AddLabAdmin.swift
//  MediOps
//
//  Created by Sharvan on 22/03/25.
//

import SwiftUI
// Using SwiftUI's import approach to access QualificationToggle from another file

struct AddLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: UILabAdmin.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var selectedQualifications: Set<String> = ["MBBS"] // Default to MBBS
    @State private var license = ""
    @State private var address = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    var onSave: (UIActivity) -> Void
    
    // Add reference to AdminController
    private let adminController = AdminController.shared
    
    // Add allowed qualifications
    private let availableQualifications = ["MBBS", "MD", "MS"]
    
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
        !selectedQualifications.isEmpty &&
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
                    // Qualifications picker
                    VStack(alignment: .leading) {
                        Text("Qualifications")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(availableQualifications, id: \.self) { qualification in
                                    QualificationToggle(
                                        title: qualification,
                                        isSelected: selectedQualifications.contains(qualification),
                                        action: {
                                            if selectedQualifications.contains(qualification) {
                                                selectedQualifications.remove(qualification)
                                            } else {
                                                selectedQualifications.insert(qualification)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        if selectedQualifications.isEmpty {
                            Text("Select at least one qualification")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 5)
                    
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
                        isLoading = true
                        saveLabAdmin()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if !errorMessage.isEmpty {
                        isLoading = false
                    }
                }
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
            qualification: selectedQualifications.joined(separator: ", "),
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

        // First save to database, then send credentials
        saveToDatabase(labAdmin: labAdmin, activity: activity)
    }
    
    private func saveToDatabase(labAdmin: UILabAdmin, activity: UIActivity) {
        Task {
            do {
                // Generate a secure password that meets the Supabase constraints:
                // - At least 8 characters
                // - At least one uppercase letter
                // - At least one lowercase letter
                // - At least one digit
                // - At least one special character (@$!%*?&)
                let password = generateSecurePassword()
                
                // Get hospital ID from UserDefaults
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    await MainActor.run {
                        isLoading = false
                        alertMessage = "Failed to save lab admin: Hospital ID not found. Please login again."
                        showAlert = true
                    }
                    return
                }
                
                print("SAVE LAB ADMIN: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Save to database using AdminController
                let (_, _) = try await adminController.createLabAdmin(
                    email: labAdmin.email,
                    password: password,
                    name: labAdmin.fullName,
                    labName: labAdmin.qualification, // This is actually mapped to department
                    hospitalAdminId: hospitalId,
                    contactNumber: labAdmin.phone.replacingOccurrences(of: "+91", with: ""), // Remove country code for 10-digit format
                    department: "Pathology & Laboratory" // Fixed to match the constraint
                )
                
                // If successful, send credentials email
                await MainActor.run {
                    sendLabCredentials(activity: activity, password: password)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to save lab admin: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    // Generate a password that meets the Supabase constraints:
    // - At least 8 characters
    // - At least one uppercase letter
    // - At least one lowercase letter
    // - At least one digit
    // - At least one special character (@$!%*?&)
    private func generateSecurePassword() -> String {
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "@$!%*?&" // Only allowed special characters per constraint
        
        // Ensure at least one character from each required category
        var passwordChars: [String] = []
        passwordChars.append(String(uppercaseLetters.randomElement()!))
        passwordChars.append(String(lowercaseLetters.randomElement()!))
        passwordChars.append(String(numbers.randomElement()!))
        passwordChars.append(String(specialChars.randomElement()!))
        
        // Add more random characters to reach at least 8 characters
        let allChars = uppercaseLetters + lowercaseLetters + numbers + specialChars
        let additionalLength = 8 // Will give us a 12-character password
        
        for _ in 0..<additionalLength {
            passwordChars.append(String(allChars.randomElement()!))
        }
        
        // Shuffle and join the characters
        return passwordChars.shuffled().joined()
    }
    
    private func sendLabCredentials(activity: UIActivity, password: String) {
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
            "accountType": "lab",
            "details": [
                "fullName": fullName,
                "email": email,
                "phone": "+91\(phoneNumber)",
                "qualification": selectedQualifications.joined(separator: ", "),
                "license": license,
                "labName": selectedQualifications.joined(separator: ", "),
                "labId": "LAB001",
                "password": password // Include the password in the email
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
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
                            self.alertMessage = "Lab admin created and credentials sent successfully to \(email)"
                            self.showAlert = true
                            // Call onSave callback with the new activity
                            self.onSave(activity)
                            // Dismiss the view after successful save
                            self.dismiss()
                        } else {
                            // Lab admin was created in database, but email failed
                            self.alertMessage = "Lab admin created, but failed to send credentials email (Status: \(httpResponse.statusCode))"
                            self.showAlert = true
                            // Still call onSave as the database operation was successful
                            self.onSave(activity)
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
        selectedQualifications = ["MBBS"]
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
