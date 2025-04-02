//
//  AddLabAdmin.swift
//  MediOps
//
//  Created by Sharvan on 22/03/25.
//

import SwiftUI
// QualificationToggle is defined in SharedComponents.swift

struct AddLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: UILabAdmin.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var selectedQualifications: Set<String> = []  // Remove default MBBS
    @State private var license = ""
    @State private var address = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
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
        isValidName(fullName) &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !selectedQualifications.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    // Add validation functions
    private func isValidName(_ name: String) -> Bool {
        let nameRegex = "^[A-Za-z\\s]{2,}$"
        return name.range(of: nameRegex, options: .regularExpression) != nil
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        // Check if license is exactly 7 characters
        guard license.count == 7 else { return false }
        
        // Check first two characters are letters and last five are numbers
        let firstTwo = license.prefix(2)
        let lastFive = license.suffix(5)
        
        return firstTwo.allSatisfy { $0.isLetter } && lastFive.allSatisfy { $0.isNumber }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .onChange(of: fullName) { _, newValue in
                            // Only allow letters and spaces
                            fullName = newValue.filter { $0.isLetter || $0.isWhitespace }
                        }
                    if !fullName.isEmpty && !isValidName(fullName) {
                        Text("Name should only contain letters and spaces")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
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
                            // Format and validate license input
                            var formatted = newValue.uppercased()
                            
                            // If length is more than 7, truncate it
                            if formatted.count > 7 {
                                formatted = String(formatted.prefix(7))
                            }
                            
                            // For the first two characters, only allow letters
                            if formatted.count <= 2 {
                                formatted = formatted.filter { $0.isLetter }
                            } else {
                                // Split into letters and numbers
                                let prefix = String(formatted.prefix(2)).filter { $0.isLetter }
                                let remainingInput = String(formatted.dropFirst(2))
                                let numbers = remainingInput.filter { $0.isNumber }
                                
                                // Combine with proper formatting
                                formatted = prefix + (numbers.count > 5 ? String(numbers.prefix(5)) : numbers)
                            }
                            
                            license = formatted
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
                Button("OK", role: .cancel) { }
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
                // Set loading state
                await MainActor.run {
                    isLoading = true
                }
                
                // Validate phone number format (must be 10 digits)
                let phoneWithoutCountryCode = labAdmin.phone.replacingOccurrences(of: "+91", with: "")
                if !phoneWithoutCountryCode.isEmpty {
                    let isValid = phoneWithoutCountryCode.range(of: "^[0-9]{10}$", options: .regularExpression) != nil
                    if !isValid {
                        await MainActor.run {
                            isLoading = false
                            alertMessage = "Invalid phone number. Must be 10 digits."
                            showAlert = true
                        }
                        return
                    }
                }
                
                // Generate a secure password
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
                
                // Save to database using AdminController
                do {
                    let (labAdminResult, _) = try await adminController.createLabAdmin(
                        email: labAdmin.email,
                        password: password,
                        name: labAdmin.fullName,
                        labName: labAdmin.qualification,
                        hospitalAdminId: hospitalId,
                        contactNumber: phoneWithoutCountryCode,
                        department: "Pathology & Laboratory"
                    )
                    
                    // If successful, immediately update UI and dismiss
                    await MainActor.run {
                        isLoading = false
                        onSave(activity)
                        dismiss()
                    }
                    
                    // Then send credentials email in the background
                    Task {
                        await sendLabCredentials(activity: activity, password: password)
                    }
                    
                } catch let error as AdminError {
                    await MainActor.run {
                        isLoading = false
                        alertMessage = "Failed to save lab admin: \(error.errorDescription ?? "Unknown error")"
                        showAlert = true
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
    }
    
    private func generateSecurePassword() -> String {
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "@$!%*?&" // Only allowed special characters per constraint
        
        // Start with a guaranteed set of characters to meet all requirements
        var passwordChars: [String] = []
        passwordChars.append(String(uppercaseLetters.randomElement()!)) // Guarantee uppercase
        passwordChars.append(String(lowercaseLetters.randomElement()!)) // Guarantee lowercase
        passwordChars.append(String(numbers.randomElement()!))          // Guarantee digit
        passwordChars.append(String(specialChars.randomElement()!))     // Guarantee special char
        
        // Add more random characters to reach at least 12 characters for better security
        let allChars = uppercaseLetters + lowercaseLetters + numbers + specialChars
        let additionalLength = 8 // Results in a 12-character password (4 guaranteed + 8 additional)
        
        for _ in 0..<additionalLength {
            passwordChars.append(String(allChars.randomElement()!))
        }
        
        // Shuffle and join the characters
        let shuffled = passwordChars.shuffled().joined()
        
        // Double check that the password meets all requirements before returning
        let meetsRequirements = 
            shuffled.count >= 8 &&
            shuffled.range(of: "[A-Z]", options: .regularExpression) != nil &&
            shuffled.range(of: "[a-z]", options: .regularExpression) != nil &&
            shuffled.range(of: "[0-9]", options: .regularExpression) != nil &&
            shuffled.range(of: "[@$!%*?&]", options: .regularExpression) != nil
        
        // Verify password matches the database constraint pattern
        let passwordConstraintRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]+$"
        let matchesConstraint = shuffled.range(of: passwordConstraintRegex, options: .regularExpression) != nil
        
        if meetsRequirements && matchesConstraint {
            print("Generated password meets all requirements (length: \(shuffled.count))")
            return shuffled
        } else {
            // If by some chance we didn't meet requirements, generate again
            print("Generated password did not meet all requirements. Regenerating...")
            return generateSecurePassword()
        }
    }
    
    private func sendLabCredentials(activity: UIActivity, password: String) async {
        guard let url = URL(string: "http://localhost:8082/send-credentials") else {
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
                "password": password
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("Failed to send credentials email (Status: \(httpResponse.statusCode))")
                }
            }
        } catch {
            print("Failed to send credentials email: \(error.localizedDescription)")
        }
    }
    
    private func resetForm() {
        fullName = ""
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = []
        license = ""
        address = ""
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

#Preview {
    AddLabAdminView { activity in
        print("Lab admin saved: \(activity.title)")
    }
}


