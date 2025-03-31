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
    @State private var selectedWeekdaySlots: Set<String> = ["9:00-10:00", "4:00-5:00"]
    @State private var selectedWeekendSlots: Set<String> = []
    @State private var hospitalId: String = ""
    @State private var doctorId: String = "" // Added to store generated doctor ID
    @State private var showSuccessInfo: Bool = false // To control doctor info display
    
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
        isValidPincode(pincode) && // Add pincode validation
        hasSlotsSelected // At least one slot must be selected
    }
    
    // Check if any slots are selected
    private var hasSlotsSelected: Bool {
        return !selectedWeekdaySlots.isEmpty || !selectedWeekendSlots.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Only show Doctor ID when available
                if !doctorId.isEmpty && showSuccessInfo {
                    Section(header: Text("Doctor Information")) {
                        HStack {
                            Text("Doctor ID:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(doctorId)
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Text("Doctor ID has been generated successfully. Use this ID for future reference.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            Task {
                                await testAvailabilityInsertion()
                            }
                        }) {
                            Text("Test Availability Insertion")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                        
                        Button(action: {
                            resetFormForNewDoctor()
                        }) {
                            Text("Create New Doctor")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                }
                
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
                
                Section(header: Text("Availability Schedule")) {
                    VStack(alignment: .leading, spacing: 15) {
                        // Weekdays (MON-FRI) Section
                        Group {
                            Text("Weekdays (MON-FRI)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 5)
                            
                            // Morning slots
                            HStack {
                                Text("Morning Slots")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "9:00-10:00", isSelected: selectedWeekdaySlots.contains("9:00-10:00"), isWeekend: false) {
                                            toggleSlot("9:00-10:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekdaySlots.contains("10:00-11:00"), isWeekend: false) {
                                            toggleSlot("10:00-11:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekdaySlots.contains("11:00-12:00"), isWeekend: false) {
                                            toggleSlot("11:00-12:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Afternoon/Evening slots
                            HStack {
                                Text("Afternoon")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "3:00-4:00", isSelected: selectedWeekdaySlots.contains("3:00-4:00"), isWeekend: false) {
                                            toggleSlot("3:00-4:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "4:00-5:00", isSelected: selectedWeekdaySlots.contains("4:00-5:00"), isWeekend: false) {
                                            toggleSlot("4:00-5:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "5:00-6:00", isSelected: selectedWeekdaySlots.contains("5:00-6:00"), isWeekend: false) {
                                            toggleSlot("5:00-6:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Evening")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "6:00-7:00", isSelected: selectedWeekdaySlots.contains("6:00-7:00"), isWeekend: false) {
                                            toggleSlot("6:00-7:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "7:00-8:00", isSelected: selectedWeekdaySlots.contains("7:00-8:00"), isWeekend: false) {
                                            toggleSlot("7:00-8:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "8:00-9:00", isSelected: selectedWeekdaySlots.contains("8:00-9:00"), isWeekend: false) {
                                            toggleSlot("8:00-9:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                        
                        // Weekend section (SAT-SUN)
                        Group {
                            Text("Weekends (SAT-SUN)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 5)
                            
                            // Morning slots
                            HStack {
                                Text("Morning Slots")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "9:00-10:00", isSelected: selectedWeekendSlots.contains("9:00-10:00"), isWeekend: true) {
                                            toggleSlot("9:00-10:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekendSlots.contains("10:00-11:00"), isWeekend: true) {
                                            toggleSlot("10:00-11:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekendSlots.contains("11:00-12:00"), isWeekend: true) {
                                            toggleSlot("11:00-12:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Afternoon/Evening slots for weekends
                            HStack {
                                Text("Afternoon")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "3:00-4:00", isSelected: selectedWeekendSlots.contains("3:00-4:00"), isWeekend: true) {
                                            toggleSlot("3:00-4:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "4:00-5:00", isSelected: selectedWeekendSlots.contains("4:00-5:00"), isWeekend: true) {
                                            toggleSlot("4:00-5:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "5:00-6:00", isSelected: selectedWeekendSlots.contains("5:00-6:00"), isWeekend: true) {
                                            toggleSlot("5:00-6:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Evening")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, alignment: .leading)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "6:00-7:00", isSelected: selectedWeekendSlots.contains("6:00-7:00"), isWeekend: true) {
                                            toggleSlot("6:00-7:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "7:00-8:00", isSelected: selectedWeekendSlots.contains("7:00-8:00"), isWeekend: true) {
                                            toggleSlot("7:00-8:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "8:00-9:00", isSelected: selectedWeekendSlots.contains("8:00-9:00"), isWeekend: true) {
                                            toggleSlot("8:00-9:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Add validation message if no slots selected
                        if selectedWeekdaySlots.isEmpty && selectedWeekendSlots.isEmpty {
                            Text("Please select at least one availability slot")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.vertical, 5)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        isLoading = true
                        Task {
                            await saveDoctor()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                // Load the hospital ID when the view appears
                if let id = UserDefaults.standard.string(forKey: "hospital_id") {
                    hospitalId = id
                    print("Loaded hospital ID: \(id)")
                } else {
                    print("Warning: No hospital ID found in UserDefaults")
                }
                
                // Generate initial password when view appears
                password = generateSecurePassword()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage.starts(with: "Doctor added") ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if !errorMessage.isEmpty {
                            isLoading = false
                        } else if alertMessage.starts(with: "Doctor added") {
                            dismiss()
                        }
                    }
                )
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
        }
    }
    
    private func saveDoctor() async {
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
                
                self.hospitalId = hospitalId // Update the state variable
                
                print("SAVE DOCTOR: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Prepare the doctor data
                print("🔄 Creating doctor with email: \(email)")
                let (doctor, _) = try await adminController.createDoctor(
                    email: email,
                    password: securePassword,
                    name: fullName,
                    specialization: specialization.rawValue,
                    hospitalId: hospitalId,
                    qualifications: Array(selectedQualifications),
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    state: "", // Add these fields if needed
                    city: "",
                    pincode: pincode,
                    contactNumber: phoneNumber
                )
                
                print("✅ Doctor created successfully with ID: \(doctor.id)")
                
                // Store the generated doctor ID
                await MainActor.run {
                    self.doctorId = doctor.id
                }
                
                // Verify we have a valid doctor ID
                guard !doctor.id.isEmpty else {
                    throw NSError(domain: "AddDoctorView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Doctor was created but no ID was returned"])
                }
                
                // Create doctor schedule using JSON approach
                print("🕒 Creating doctor schedule with \(selectedWeekdaySlots.count) weekday slots and \(selectedWeekendSlots.count) weekend slots for doctor ID: \(doctor.id)")
                
                do {
                    // Create a complete weekly schedule at once
                    try await adminController.addDoctorSchedule(
                        doctorId: doctor.id,
                        hospitalId: hospitalId,
                        weekdaySlots: selectedWeekdaySlots,
                        weekendSlots: selectedWeekendSlots
                    )
                    print("✅ Successfully created doctor schedule")
                } catch {
                    print("⚠️ Failed to create doctor schedule: \(error.localizedDescription)")
                    // Continue anyway since the doctor was created
                }
                
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
                    qualification: selectedQualifications.joined(separator: ", "),
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
                    showSuccessInfo = true // Show the doctor info section
                    onSave(activity)
                    isLoading = false
                    alertMessage = "Doctor added successfully with ID: \(doctor.id). Availability schedule has been created."
                    showAlert = true
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
        // Don't reset doctorId or showSuccessInfo to keep displaying doctor info
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
        selectedWeekdaySlots = ["9:00-10:00", "4:00-5:00"]
        selectedWeekendSlots = []
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
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        if slots.contains(time) {
            slots.remove(time)
        } else {
            slots.insert(time)
        }
    }
    
    private func createTimeFromString(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Clean up the input time string
        let cleanedTimeString = timeString.trimmingCharacters(in: .whitespaces)
        print("🔍 Processing time string: '\(cleanedTimeString)'")
        
        // Extract hours and minutes
        var hour = 0
        var minute = 0
        
        // Try different parsing approaches for maximum flexibility
        if cleanedTimeString.contains(":") {
            // Format like "9:00" or "10:00"
            let components = cleanedTimeString.components(separatedBy: ":")
            if components.count >= 2,
               let parsedHour = Int(components[0].trimmingCharacters(in: .whitespaces)),
               let parsedMinute = Int(components[1].trimmingCharacters(in: .whitespaces)) {
                hour = parsedHour
                minute = parsedMinute
                print("✅ Parsed time from colon format: \(hour):\(minute)")
            } else {
                print("❌ Failed to parse time with colon: \(cleanedTimeString)")
                return nil
            }
        } else {
            // Try to extract numeric values for hour
            let hourString = cleanedTimeString.prefix(while: { $0.isNumber })
            if let parsedHour = Int(hourString) {
                hour = parsedHour
                minute = 0 // Default minutes to 0
                print("✅ Parsed hour from numeric prefix: \(hour)")
            } else {
                print("❌ Failed to parse hour from string: \(cleanedTimeString)")
                return nil
            }
        }
        
        // Create a date with the specified hour and minute
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        
        guard let result = calendar.date(from: dateComponents) else {
            print("❌ Failed to create date from components: \(dateComponents)")
            return nil
        }
        
        print("✅ Successfully created time: \(result)")
        return result
    }
    
    // Add a test function for availability insertion
    private func testAvailabilityInsertion() async {
        guard !hospitalId.isEmpty, !doctorId.isEmpty else {
            print("❌ Missing hospital ID or doctor ID for test")
            return
        }
        
        print("🔍 Testing schedule insertion with Doctor ID: \(doctorId) and Hospital ID: \(hospitalId)")
        
        // Create test slots
        let morningSlots: Set<String> = ["09:00-10:00", "10:00-11:00"]
        let eveningSlots: Set<String> = ["16:00-17:00"]
        
        do {
            print("🔄 Adding test schedule")
            try await adminController.addDoctorSchedule(
                doctorId: doctorId,
                hospitalId: hospitalId,
                weekdaySlots: morningSlots,
                weekendSlots: eveningSlots
            )
            
            await MainActor.run {
                alertMessage = "Test schedule created successfully!"
                showAlert = true
            }
        } catch {
            print("❌ Test schedule creation failed: \(error.localizedDescription)")
            
            await MainActor.run {
                alertMessage = "Test schedule creation failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    // Add a function to reset the form for a new doctor while preserving hospital ID
    private func resetFormForNewDoctor() {
        fullName = ""
        specialization = Specialization.generalMedicine
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = ["MBBS"]
        license = ""
        address = ""
        pincode = ""
        password = generateSecurePassword() 
        selectedWeekdaySlots = ["9:00-10:00", "4:00-5:00"]
        selectedWeekendSlots = []
        
        // Reset doctor information but keep hospital ID
        doctorId = ""
        showSuccessInfo = false
    }
}

// Time Slot Button Component
struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let isWeekend: Bool
    let action: () -> Void
    
    init(time: String, isSelected: Bool, isWeekend: Bool = false, action: @escaping () -> Void) {
        self.time = time
        self.isSelected = isSelected
        self.isWeekend = isWeekend
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                }
                
                Text(time)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return isWeekend ? Color.orange : Color.teal
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        isSelected ? .white : .primary
    }
    
    private var strokeColor: Color {
        if isSelected {
            return isWeekend ? Color.orange : Color.teal
        } else {
            return Color.clear
        }
    }
}

// QualificationToggle has been moved to SharedComponents.swift
