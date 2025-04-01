//
//  AddDOctorView.swift
//  MediOps
//
//  Created by Sharvan on 21/03/25.
//

import SwiftUI
// QualificationToggle is defined in SharedComponents.swift

struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var specialization = Specialization.generalMedicine
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: UIDoctor.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var selectedQualifications: Set<String> = ["MBBS"] // Default to MBBS
    @State private var license = ""
    @State private var address = "" // Added address state
    @State private var pincode = "" // Add pincode field
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var password = "" // Added password for account creation
    
    // Add controllers
    private let adminController = AdminController.shared
    private let userController = UserController.shared
    
    var onSave: (UIActivity) -> Void
    
    enum Specialization: String, CaseIterable {
        case generalMedicine = "General medicine"
        case orthopaedics = "Orthopaedics"
        case gynaecology = "Gynaecology"
        case cardiology = "Cardiology"
        case pathologyLaboratory = "Pathology & laboratory"
        
        var id: String { self.rawValue }
    }
    
    // Add allowed qualifications
    private let availableQualifications = ["MBBS", "MD", "MS"]
    
    // Calculate maximum experience based on age
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25) // Experience should be 19 years less than doctor's age
    }

    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !specialization.rawValue.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !selectedQualifications.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty &&
        isValidPincode(pincode) // Add pincode validation
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Specialization", selection: $specialization) {
                        ForEach(Specialization.allCases, id: \.id) { specialization in
                            Text(specialization.rawValue)
                                .tag(specialization)
                        }
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UIDoctor.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              in: ...Date(),
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
                    
                    // Updated license field with more general format hint
                    TextField("License Number", text: $license)
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
                    
                    // Updated phone field with prefix
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
                    
                    // Changed to TextField for address
                    TextField("Address", text: $address)
                    
                    // Add pincode field with validation
                    TextField("Pincode (6 digits)", text: $pincode)
                        .keyboardType(.numberPad)
                        .onChange(of: pincode) { _, newValue in
                            // Keep only digits and limit to 6
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered.count > 6 {
                                pincode = String(filtered.prefix(6))
                            } else {
                                pincode = filtered
                            }
                        }
                }
                
                Section(header: Text("Account Information")) {
                    // Generate password automatically with button to refresh
                    HStack {
                        SecureField("Password", text: $password)
                        Button(action: {
                            password = generateSecurePassword()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if !password.isEmpty {
                        Text("Generated password: \(password)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
            }
            .navigationTitle("Add Doctor")
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
                        saveDoctor()
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
                    } else {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Generate initial password when view appears
                password = generateSecurePassword()
            }
        }
    }
    
    private func saveDoctor() {
        isLoading = true
        
        // Generate a secure password that meets the Supabase constraints
        let securePassword = generateSecurePassword()
        
        Task {
            do {
                // Get hospital ID from UserDefaults
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    await MainActor.run {
                        alertMessage = "Failed to create doctor: Hospital ID not found. Please login again."
                        showAlert = true
                        isLoading = false
                    }
                    return
                }
                
                print("SAVE DOCTOR: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Prepare the doctor data
                print("Creating doctor with hospital admin ID: \(hospitalId)")
                
                // Convert qualifications for API
                let qualificationsArray = Array(selectedQualifications)
                
                // Create the doctor
                let (doctor, _) = try await adminController.createDoctor(
                    email: email,
                    password: securePassword,
                    name: fullName,
                    specialization: specialization.rawValue,
                    hospitalId: hospitalId,
                    qualifications: qualificationsArray,
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    state: "", // Add these fields if needed
                    city: "",
                    pincode: pincode,
                    contactNumber: phoneNumber
                )
                
                // Send credentials to the doctor
                await sendDoctorCredentials(email: email, password: securePassword)
                
                // Create a doctor record for the UI
                let uiDoctor = UIDoctor(
                    id: doctor.id,
                    fullName: doctor.name,
                    specialization: doctor.specialization,
                    email: doctor.email,
                    phone: "+91\(phoneNumber)",
                    gender: gender,
                    dateOfBirth: dateOfBirth,
                    experience: experience,
                    qualification: qualificationsArray.joined(separator: ", "),
                    license: license,
                    address: address
                )
                
                // Create an activity for the new doctor
                let activity = UIActivity(
                    id: UUID(),
                    type: .doctorAdded,
                    title: "Added new doctor: \(fullName)",
                    timestamp: Date(),
                    status: .completed,
                    doctorDetails: uiDoctor,
                    labAdminDetails: nil,
                    hospitalDetails: nil
                )
                
                await MainActor.run {
                    resetForm()
                    onSave(activity)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to create doctor: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
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
        let specialChars = "@$!%*?&"
        
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
    
    private func sendDoctorCredentials(email: String, password: String) async {
        guard let url = URL(string: "http://192.168.182.100:8082/send-credentials") else {
            await MainActor.run {
                alertMessage = "Invalid server URL"
                showAlert = true
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Increased timeout to 60 seconds
        
        let emailData: [String: Any] = [
            "to": email,
            "accountType": "doctor",
            "details": [
                "fullName": fullName,
                "specialization": specialization.rawValue,
                "license": license,
                "phone": "+91\(phoneNumber)",
                "qualification": selectedQualifications.joined(separator: ", "),
                "experience": experience,
                "password": password // Include the password in the email
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Credentials email sent successfully")
                } else {
                    await MainActor.run {
                        alertMessage = "Doctor created successfully but failed to send credentials email (Status: \(httpResponse.statusCode))"
                        showAlert = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Doctor created successfully but failed to send credentials email: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func resetForm() {
        fullName = ""
        specialization = Specialization.generalMedicine
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = ["MBBS"]
        license = ""
        address = "" // Reset address
        pincode = "" // Reset pincode
        password = generateSecurePassword() // Generate new password
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    // Add validation for pincode (must be exactly 6 digits)
    private func isValidPincode(_ pincode: String) -> Bool {
        let pincodeRegex = #"^[0-9]{6}$"#
        return NSPredicate(format: "SELF MATCHES %@", pincodeRegex).evaluate(with: pincode)
    }
}

// QualificationToggle has been moved to SharedComponents.swift
