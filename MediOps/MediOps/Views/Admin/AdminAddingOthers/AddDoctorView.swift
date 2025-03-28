//
//  AddDOctorView.swift
//  MediOps
//
//  Created by Sharvan on 21/03/25.
//

import SwiftUI
// Using SwiftUI's import approach to access QualificationToggle from another file

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
        !address.isEmpty
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
        guard isFormValid else { return }
        
        Task {
            do {
                // Get current user to determine hospital admin ID
                var hospitalId: String? = nil
                
                if let currentUser = try? await userController.getCurrentUser() {
                    print("ADD DOCTOR: Current user ID: \(currentUser.id), role: \(currentUser.role.rawValue)")
                    
                    // If user is a hospital admin, use their ID directly
                    if currentUser.role == .hospitalAdmin {
                        hospitalId = currentUser.id
                        print("ADD DOCTOR: User is a hospital admin, using ID: \(hospitalId ?? "unknown")")
                    } else {
                        // For other roles, try to get their associated hospital admin
                        do {
                            let hospitalAdmin = try await adminController.getHospitalAdminByUserId(userId: currentUser.id)
                            hospitalId = hospitalAdmin.id
                            print("ADD DOCTOR: Retrieved hospital admin ID: \(hospitalId ?? "unknown")")
                        } catch {
                            print("ADD DOCTOR WARNING: \(error.localizedDescription)")
                        }
                    }
                }
                
                // If we couldn't determine the hospital admin ID, use a fallback
                if hospitalId == nil {
                    hospitalId = "HOS001" // Fallback ID
                    print("ADD DOCTOR: Using fallback hospital ID: \(hospitalId!)")
                }
                
                // Make sure we have all required fields according to the DB schema
                // Prepare qualifications array (Required by schema constraint)
                let qualificationArray: [String] = Array(selectedQualifications)
                
                // Default values for required fields that aren't in the form
                let defaultState = "Maharashtra"
                let defaultCity = "Mumbai"
                let defaultPincode = "400001"
                let doctorStatus = "active"
                
                // Call AdminController to create doctor
                let (doctor, token) = try await adminController.createDoctor(
                    email: email,
                    password: password,
                    name: fullName,
                    specialization: specialization.rawValue,
                    hospitalId: hospitalId!,
                    qualifications: qualificationArray,
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    state: defaultState,
                    city: defaultCity,
                    pincode: defaultPincode,
                    contactNumber: phoneNumber,
                    emergencyContactNumber: phoneNumber,
                    doctorStatus: doctorStatus
                )
                
                print("DOCTOR CREATED: \(doctor.name) with ID: \(doctor.id)")
                
                // Create UI model for the doctor
                let uiDoctor = UIDoctor(
                    id: doctor.id,
                    fullName: doctor.name,
                    specialization: specialization.rawValue,
                    email: email,
                    phone: "+91\(phoneNumber)",
                    gender: gender,
                    dateOfBirth: dateOfBirth,
                    experience: experience,
                    qualification: qualificationArray.joined(separator: ", "),
                    license: license,
                    address: address
                )
                
                // Create activity for the UI
                let activity = UIActivity(
                    type: .doctorAdded,
                    title: "New Doctor: \(doctor.name)",
                    timestamp: Date(),
                    status: .completed,
                    doctorDetails: uiDoctor,
                    labAdminDetails: nil
                )
                
                // Call the sendDoctorCredentials function to send email
                sendDoctorCredentials(activity: activity)
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to create doctor: \(error.localizedDescription)"
                    showAlert = true
                    print("ADD DOCTOR ERROR: \(error)")
                }
            }
        }
    }

    private func sendDoctorCredentials(activity: UIActivity) {
        guard let url = URL(string: "http://192.168.182.100:8082/send-credentials") else {
            alertMessage = "Invalid server URL"
            showAlert = true
            isLoading = false
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
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
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
                            self.alertMessage = "Doctor created successfully and credentials sent to \(email)"
                            self.showAlert = true
                            // Call onSave callback with the new activity
                            self.onSave(activity)
                        } else {
                            self.alertMessage = "Doctor created successfully but failed to send credentials email (Status: \(httpResponse.statusCode))"
                            self.showAlert = true
                            // Still call onSave since the doctor was created
                            self.onSave(activity)
                        }
                    }
                }
            }.resume()
        } catch {
            isLoading = false
            alertMessage = "Failed to prepare email data"
            showAlert = true
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
    
    private func generateSecurePassword() -> String {
        let upperLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowerLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*()_-+="
        
        // Ensure at least one character from each category
        var password = String(upperLetters.randomElement()!)
        password += String(lowerLetters.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(specialChars.randomElement()!)
        
        // Add additional random characters
        let allChars = upperLetters + lowerLetters + numbers + specialChars
        for _ in 0..<6 {
            password += String(allChars.randomElement()!)
        }
        
        // Shuffle the password
        return String(password.shuffled())
    }
}

// QualificationToggle has been moved to SharedComponents.swift
