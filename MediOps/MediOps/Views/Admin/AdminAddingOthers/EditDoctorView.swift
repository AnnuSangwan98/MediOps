import SwiftUI

struct EditDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var specialization: AddDoctorView.Specialization
    @State private var email: String
    @State private var phoneNumber: String
    @State private var gender: UIDoctor.Gender
    @State private var dateOfBirth: Date
    @State private var experience: Int
    @State private var qualification: String
    @State private var license: String
    @State private var address: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    // Add time slot states
    @State private var selectedTimeSlots: [String: [String: Bool]] = [:]
    @State private var selectedDays: Set<String> = []
    @State private var maxNormalPatients: Int = 5
    @State private var maxPremiumPatients: Int = 2
    
    // Update the state variables to include maxAppointments
    @State private var maxAppointments: Int
    
    private let weekdays = [
        "monday": "Mon",
        "tuesday": "Tue",
        "wednesday": "Wed",
        "thursday": "Thu",
        "friday": "Fri",
        "saturday": "Sat",
        "sunday": "Sun"
    ]
    
    private let weekdayOrder = [
        "monday": 0,
        "tuesday": 1,
        "wednesday": 2,
        "thursday": 3,
        "friday": 4,
        "saturday": 5,
        "sunday": 6
    ]
    
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
    
    // Add reference to AdminController
    private let adminController = AdminController.shared
    
    let doctor: UIDoctor
    let onUpdate: (UIDoctor) -> Void
    
    init(doctor: UIDoctor, onUpdate: @escaping (UIDoctor) -> Void) {
        self.doctor = doctor
        self.onUpdate = onUpdate
        
        // Initialize state variables with doctor's current data
        _fullName = State(initialValue: doctor.fullName)
        _specialization = State(initialValue: AddDoctorView.Specialization.allCases.first(where: { $0.rawValue == doctor.specialization }) ?? .generalMedicine)
        _email = State(initialValue: doctor.email)
        _phoneNumber = State(initialValue: doctor.phone.replacingOccurrences(of: "+91", with: ""))
        _gender = State(initialValue: doctor.gender)
        _dateOfBirth = State(initialValue: doctor.dateOfBirth)
        _experience = State(initialValue: doctor.experience)
        _qualification = State(initialValue: doctor.qualification)
        _license = State(initialValue: doctor.license)
        _address = State(initialValue: doctor.address)
        _maxAppointments = State(initialValue: doctor.maxAppointments)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !specialization.rawValue.isEmpty &&
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
                    
                    Picker("Specialization", selection: $specialization) {
                        ForEach(AddDoctorView.Specialization.allCases, id: \.id) { specialization in
                            Text(specialization.rawValue)
                                .tag(specialization)
                        }
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UIDoctor.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
//                    DatePicker("Date of Birth",
//                              selection: $dateOfBirth,
//                              in: ...Date(),
//                              displayedComponents: .date)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    TextField("License Number", text: $license)
                        .onChange(of: license) { _, newValue in
                            license = newValue.uppercased()
                        }
                    
                    // Display experience as text instead of stepper
                    HStack {
                        Text("Experience:")
                            .foregroundColor(.primary)
                        Text("\(experience) years")
                            .foregroundColor(.secondary)
                    }
                    
                    // Add max appointments stepper
                    Stepper("Max Appointments: \(maxAppointments)", value: $maxAppointments, in: 1...50)
                        .help("Maximum number of daily appointments the doctor can handle")
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
            .navigationTitle("Edit Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
//                        Text("Doctors")
//                            .font(.headline)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateDoctor()
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
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadDoctorAvailability()
            }
        }
    }
    
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25)
    }
    
    private func updateDoctor() {
        isLoading = true
        
        // Create the updated UIDoctor object for the UI
        let updatedDoctor = UIDoctor(
            id: doctor.id,
            fullName: fullName,
            specialization: specialization.rawValue,
            email: email,
            phone: "+91\(phoneNumber)",
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            license: license,
            address: address,
            maxAppointments: maxAppointments
        )
        
        // Save to Supabase
        Task {
            do {
                // Parse qualifications from comma-separated string to array
                let qualificationsArray = qualification.split(separator: ",").map { 
                    String($0.trimmingCharacters(in: .whitespaces)) 
                }
                
                // Update doctor in Supabase
                try await adminController.updateDoctor(
                    doctorId: doctor.id, 
                    name: fullName,
                    specialization: specialization.rawValue,
                    qualifications: qualificationsArray,
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    email: email,
                    contactNumber: phoneNumber,
                    maxAppointments: maxAppointments
                )
                
                // Update doctor availability
                let weeklySchedule = createWeeklySchedule()
                try await adminController.updateDoctorAvailability(
                    doctorId: doctor.id,
                    weeklySchedule: weeklySchedule,
                    maxNormalPatients: maxNormalPatients,
                    maxPremiumPatients: maxPremiumPatients
                )
                
                // Update UI on success
                await MainActor.run {
                    // Call the update callback
                    onUpdate(updatedDoctor)
                    
                    // Show success message
                    alertMessage = "Doctor information updated successfully in database"
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to update doctor: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
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
            weeklySchedule[day] = createDaySchedule(for: day)
        }
        
        return weeklySchedule
    }
    
    private func createDaySchedule(for day: String) -> [String: Bool] {
        return selectedTimeSlots[day] ?? [:]
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    private func loadDoctorAvailability() async {
        do {
            if let availability = try await adminController.getDoctorAvailability(doctorId: doctor.id) {
                await MainActor.run {
                    // Initialize selected days and time slots from the weekly schedule
                    selectedDays = Set(availability.weeklySchedule.keys)
                    selectedTimeSlots = availability.weeklySchedule
                    
                    // Set patient limits
                    maxNormalPatients = availability.maxNormalPatients
                    maxPremiumPatients = availability.maxPremiumPatients
                }
            }
        } catch {
            print("Failed to load doctor availability: \(error)")
        }
    }
} 
