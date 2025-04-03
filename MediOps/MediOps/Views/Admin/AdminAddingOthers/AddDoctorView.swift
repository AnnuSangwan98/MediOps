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
    @State private var selectedQualifications: Set<String> = [] // Removed default MBBS
    @State private var license = ""
    @State private var address = "" // Added address state
    @State private var pincode = "" // Add pincode field
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Add time slot states
    @State private var selectedTimeSlots: [String: [String: Bool]] = [:]
    @State private var selectedDays: Set<String> = []
    
    // Add state variables for max appointments at the top with other @State declarations
    @State private var maxAppointments = 8
    
    private let weekdays = [
        "monday": "Mon",
        "tuesday": "Tue",
        "wednesday": "Wed",
        "thursday": "Thu",
        "friday": "Fri",
        "saturday": "Sat",
        "sunday": "Sun"
    ]
    
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
        isValidName(fullName) &&
        !specialization.rawValue.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !selectedQualifications.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty &&
        isValidPincode(pincode)
    }
    
    enum DayGroup {
        case weekdays
        case weekends
        case none
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .onChange(of: fullName) { _, newValue in
                            // Only allow letters and spaces
                            let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                            if filtered != newValue {
                                fullName = filtered
                            }
                        }
                    
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
                    TextField("License Number (e.g. AB12345)", text: $license)
                        .onChange(of: license) { _, newValue in
                            license = newValue.uppercased()
                        }
                    
                    if !license.isEmpty && !isValidLicense(license) {
                        Text("License must be 2 letters followed by 5 numbers")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                    
                    // Add max appointments stepper
                    Stepper("Max Appointments: \(maxAppointments)", value: $maxAppointments, in: 1...50)
                        .help("Maximum number of daily appointments the doctor can handle")
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
                
                Section(header: Text("Availability")) {
                    // Individual day selection buttons with Select All
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Select All Days button
                            Button {
                                if selectedDays.count == weekdays.count {
                                    // If all days are selected, deselect all
                                    selectedDays.removeAll()
                                    selectedTimeSlots.removeAll()
                                } else {
                                    // Select all days
                                    selectedDays = Set(weekdays.keys)
                                    for day in selectedDays {
                                        selectedTimeSlots[day] = [:]
                                    }
                                }
                            } label: {
                                Text("All Days")
                                    .frame(minWidth: 70)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(selectedDays.count == weekdays.count ? Color.teal : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDays.count == weekdays.count ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            
                            ForEach(Array(weekdays.sorted(by: { weekdayOrder[$0.key] ?? 0 < weekdayOrder[$1.key] ?? 0 })), id: \.key) { day, shortName in
                                Button {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                        selectedTimeSlots[day] = nil
                                    } else {
                                        selectedDays.insert(day)
                                        selectedTimeSlots[day] = [:]
                                    }
                                } label: {
                                    Text(shortName)
                                        .frame(minWidth: 50)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(selectedDays.contains(day) ? Color.teal : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    
                    // Time slots in three independent scrolling rows
                    VStack(alignment: .leading, spacing: 8) {
                        // Morning slots (0-7)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<8) { index in
                                    TimeSlotButton(
                                        slot: timeSlots[index],
                                        isSelected: isTimeSlotSelected(timeSlots[index]),
                                        action: { toggleTimeSlot(timeSlots[index]) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 55)
                        
                        // Afternoon slots (8-15)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(8..<16) { index in
                                    TimeSlotButton(
                                        slot: timeSlots[index],
                                        isSelected: isTimeSlotSelected(timeSlots[index]),
                                        action: { toggleTimeSlot(timeSlots[index]) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 55)
                        
                        // Evening/Night slots (16-23)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(16..<24) { index in
                                    TimeSlotButton(
                                        slot: timeSlots[index],
                                        isSelected: isTimeSlotSelected(timeSlots[index]),
                                        action: { toggleTimeSlot(timeSlots[index]) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 55)
                    }
                    .opacity(selectedDays.isEmpty ? 0.5 : 1.0)
                    .disabled(selectedDays.isEmpty)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Doctors")
                        .font(.subheadline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        isLoading = true
                        saveDoctor()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }
    
    // Add time slots with ranges
    private let timeSlots = (0...23).map { hour in
        let startTime = String(format: "%d:00", hour)
        let endHour = (hour + 1) % 24
        let endTime = String(format: "%d:00", endHour)
        return "\(startTime)-\(endTime)"
    }
    
    private var selectedTimeSlotsCount: Int {
        selectedTimeSlots["schedule"]?.filter { $0.value }.count ?? 0
    }
    
    private let weekdayOrder = [
        "monday": 0,
        "tuesday": 1,
        "wednesday": 2,
        "thursday": 3,
        "friday": 4,
        "saturday": 5,
        "sunday": 6
    ]
    
    private func saveDoctor() {
        isLoading = true
        
        Task {
            do {
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    await MainActor.run {
                        alertMessage = "Failed to create doctor: Hospital ID not found. Please login again."
                        showAlert = true
                        isLoading = false
                    }
                    return
                }
                
                // Create a secure password that meets constraints
                let securePassword = generateSecurePassword()
                
                // Create the doctor
                let (doctor, _) = try await adminController.createDoctor(
                    email: email,
                    password: securePassword, // Using secure password instead of phone number
                    name: fullName,
                    specialization: specialization.rawValue,
                    hospitalId: hospitalId,
                    qualifications: Array(selectedQualifications),
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    state: "", // Empty value since we don't have a field for it
                    city: "", // Empty value since we don't have a field for it
                    pincode: pincode,
                    contactNumber: phoneNumber,
                    emergencyContactNumber: nil,
                    doctorStatus: "active",
                    maxAppointments: maxAppointments
                )
                
                // Create weekly schedule using the helper function
                let weeklySchedule = createWeeklySchedule()
                
                // Create doctor availability
                try await adminController.createDoctorAvailability(
                    doctorId: doctor.id,
                    hospitalId: hospitalId,
                    weeklySchedule: weeklySchedule,
                    maxNormalPatients: 0,
                    maxPremiumPatients: 0
                )
                
                // Create UI doctor record
                let uiDoctor = UIDoctor(
                    id: doctor.id,
                    fullName: doctor.name,
                    specialization: doctor.specialization,
                    email: doctor.email,
                    phone: "+91\(phoneNumber)",
                    gender: gender,
                    dateOfBirth: dateOfBirth,
                    experience: experience,
                    qualification: Array(selectedQualifications).joined(separator: ", "),
                    license: license,
                    address: address,
                    maxAppointments: maxAppointments
                )
                
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
    
    private func resetForm() {
        fullName = ""
        specialization = Specialization.generalMedicine
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = []
        license = ""
        address = ""
        pincode = ""
        selectedTimeSlots = [:]
        selectedDays = []
        maxAppointments = 8
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        // Must be exactly 7 characters: 2 letters followed by 5 numbers
        let licenseRegex = #"^[A-Z]{2}[0-9]{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    private func isValidName(_ name: String) -> Bool {
        // Must contain only letters and spaces, at least 2 characters
        let nameRegex = #"^[A-Za-z\s]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: name)
    }
    
    // Add validation for pincode (must be exactly 6 digits)
    private func isValidPincode(_ pincode: String) -> Bool {
        let pincodeRegex = #"^[0-9]{6}$"#
        return NSPredicate(format: "SELF MATCHES %@", pincodeRegex).evaluate(with: pincode)
    }
    
    private func isTimeSlotSelected(_ slot: String) -> Bool {
        for day in selectedDays {
            if selectedTimeSlots[day]?[slot] == true {
                return true
            }
        }
        return false
    }
    
    private func toggleTimeSlot(_ slot: String) {
        let currentValue = isTimeSlotSelected(slot)
        for day in selectedDays {
            if selectedTimeSlots[day] == nil {
                selectedTimeSlots[day] = [:]
            }
            selectedTimeSlots[day]?[slot] = !currentValue
        }
    }
    
    private func createWeeklySchedule() -> [String: [String: Bool]] {
        var weeklySchedule: [String: [String: Bool]] = [:]
        
        // Create schedule for each selected day
        for day in selectedDays {
            weeklySchedule[day] = createDaySchedule()
        }
        
        return weeklySchedule
    }
    
    private func createDaySchedule() -> [String: Bool] {
        var daySchedule: [String: Bool] = [:]
        
        for slot in timeSlots {
            daySchedule[slot] = selectedTimeSlots["schedule"]?[slot] ?? false
        }
        
        return daySchedule
    }
    
    // Create a secure password that meets constraints
    private func generateSecurePassword() -> String {
        // Create password with at least 8 chars including uppercase, lowercase, number and special char
        let uppercaseLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!
        let lowercaseLetter = "abcdefghijklmnopqrstuvwxyz".randomElement()!
        let number = "0123456789".randomElement()!
        let specialChar = "!@#$%^&*".randomElement()!
        
        // Basic info plus random chars to make 8+ length
        return "Doc\(uppercaseLetter)\(lowercaseLetter)\(number)\(specialChar)\(phoneNumber.suffix(4))"
    }
}

struct TimeSlotButton: View {
    let slot: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(slot)
                .frame(minWidth: 100)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? Color.teal : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// QualificationToggle has been moved to SharedComponents.swift

#Preview {
    AddDoctorView { activity in
        print("Doctor saved: \(activity.title)")
    }
}
