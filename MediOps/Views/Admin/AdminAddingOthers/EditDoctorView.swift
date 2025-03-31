import SwiftUI
import Combine

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
    @State private var hospitalId = UserDefaults.standard.string(forKey: "hospital_id") ?? ""
    
    // Doctor availability slots - changed from Set<String> to String?
    @State private var selectedWeekdaySlot: String? = nil
    @State private var selectedWeekendSlot: String? = nil
    @State private var isLoadingSlots = false
    @State private var availabilityError = ""
    
    // Add standard UI time slots for comparison
    private let uiTimeSlots: [String] = [
        "9:00-10:00 AM", "10:00-11:00 AM", "11:00-12:00 PM",
        "1:00-2:00 PM", "2:00-3:00 PM", "3:00-4:00 PM",
        "4:00-5:00 PM", "5:00-6:00 PM", "6:00-7:00 PM",
        "7:00-8:00 PM", "8:00-9:00 PM",
        // 24-hour format alternatives
        "09:00-10:00", "10:00-11:00", "11:00-12:00",
        "13:00-14:00", "14:00-15:00", "15:00-16:00",
        "16:00-17:00", "17:00-18:00", "18:00-19:00",
        "19:00-20:00", "20:00-21:00"
    ]
    
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
                Section(header: Text("Doctor Information")) {
                    HStack {
                        Text("Doctor ID:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(doctor.id)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                
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
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              in: ...Date(),
                              displayedComponents: .date)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    TextField("License Number", text: $license)
                        .onChange(of: license) { _, newValue in
                            license = newValue.uppercased()
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
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
                
                // Availability Schedule Section
                Section(header: HStack {
                    Text("Availability Schedule")
                    Spacer()
                    if isLoadingSlots {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }) {
                    if !availabilityError.isEmpty {
                        Text(availabilityError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Weekday slots
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekday Slots (MON-FRI)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 5)
                        
                        // Early morning slots (6 AM - 10 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "06:00-07:00", isSelected: isTimeSlotSelected("06:00-07:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("06:00-07:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "07:00-08:00", isSelected: isTimeSlotSelected("07:00-08:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("07:00-08:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "08:00-09:00", isSelected: isTimeSlotSelected("08:00-09:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("08:00-09:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "09:00-10:00", isSelected: isTimeSlotSelected("09:00-10:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("09:00-10:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                        
                        // Morning slots (10 AM - 2 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "10:00-11:00", isSelected: isTimeSlotSelected("10:00-11:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("10:00-11:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: isTimeSlotSelected("11:00-12:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("11:00-12:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "12:00-13:00", isSelected: isTimeSlotSelected("12:00-13:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("12:00-13:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "13:00-14:00", isSelected: isTimeSlotSelected("13:00-14:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("13:00-14:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots (2 PM - 6 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "14:00-15:00", isSelected: isTimeSlotSelected("14:00-15:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("14:00-15:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "15:00-16:00", isSelected: isTimeSlotSelected("15:00-16:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("15:00-16:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "16:00-17:00", isSelected: isTimeSlotSelected("16:00-17:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("16:00-17:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "17:00-18:00", isSelected: isTimeSlotSelected("17:00-18:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("17:00-18:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots (6 PM - 10 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "18:00-19:00", isSelected: isTimeSlotSelected("18:00-19:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("18:00-19:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "19:00-20:00", isSelected: isTimeSlotSelected("19:00-20:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("19:00-20:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "20:00-21:00", isSelected: isTimeSlotSelected("20:00-21:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("20:00-21:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "21:00-22:00", isSelected: isTimeSlotSelected("21:00-22:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("21:00-22:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                        
                        // Night slots (10 PM - 2 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "22:00-23:00", isSelected: isTimeSlotSelected("22:00-23:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("22:00-23:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "23:00-00:00", isSelected: isTimeSlotSelected("23:00-00:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("23:00-00:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "00:00-01:00", isSelected: isTimeSlotSelected("00:00-01:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("00:00-01:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "01:00-02:00", isSelected: isTimeSlotSelected("01:00-02:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("01:00-02:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                        
                        // Late night slots (2 AM - 6 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "02:00-03:00", isSelected: isTimeSlotSelected("02:00-03:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("02:00-03:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "03:00-04:00", isSelected: isTimeSlotSelected("03:00-04:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("03:00-04:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "04:00-05:00", isSelected: isTimeSlotSelected("04:00-05:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("04:00-05:00", slot: &selectedWeekdaySlot)
                                    }
                                    
                                    TimeSlotButton(time: "05:00-06:00", isSelected: isTimeSlotSelected("05:00-06:00", selected: selectedWeekdaySlot)) {
                                        toggleSlot("05:00-06:00", slot: &selectedWeekdaySlot)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Divider()
                    
                    // Weekend slots
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekend Slots (SAT-SUN)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 5)
                        
                        // Early morning slots (6 AM - 10 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "06:00-07:00", isSelected: isTimeSlotSelected("06:00-07:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("06:00-07:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "07:00-08:00", isSelected: isTimeSlotSelected("07:00-08:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("07:00-08:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "08:00-09:00", isSelected: isTimeSlotSelected("08:00-09:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("08:00-09:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "09:00-10:00", isSelected: isTimeSlotSelected("09:00-10:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("09:00-10:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                        
                        // Morning slots (10 AM - 2 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "10:00-11:00", isSelected: isTimeSlotSelected("10:00-11:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("10:00-11:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: isTimeSlotSelected("11:00-12:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("11:00-12:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "12:00-13:00", isSelected: isTimeSlotSelected("12:00-13:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("12:00-13:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "13:00-14:00", isSelected: isTimeSlotSelected("13:00-14:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("13:00-14:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots (2 PM - 6 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "14:00-15:00", isSelected: isTimeSlotSelected("14:00-15:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("14:00-15:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "15:00-16:00", isSelected: isTimeSlotSelected("15:00-16:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("15:00-16:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "16:00-17:00", isSelected: isTimeSlotSelected("16:00-17:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("16:00-17:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "17:00-18:00", isSelected: isTimeSlotSelected("17:00-18:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("17:00-18:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots (6 PM - 10 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "18:00-19:00", isSelected: isTimeSlotSelected("18:00-19:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("18:00-19:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "19:00-20:00", isSelected: isTimeSlotSelected("19:00-20:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("19:00-20:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "20:00-21:00", isSelected: isTimeSlotSelected("20:00-21:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("20:00-21:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "21:00-22:00", isSelected: isTimeSlotSelected("21:00-22:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("21:00-22:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                        
                        // Night slots (10 PM - 2 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "22:00-23:00", isSelected: isTimeSlotSelected("22:00-23:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("22:00-23:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "23:00-00:00", isSelected: isTimeSlotSelected("23:00-00:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("23:00-00:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "00:00-01:00", isSelected: isTimeSlotSelected("00:00-01:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("00:00-01:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "01:00-02:00", isSelected: isTimeSlotSelected("01:00-02:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("01:00-02:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                        
                        // Late night slots (2 AM - 6 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "02:00-03:00", isSelected: isTimeSlotSelected("02:00-03:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("02:00-03:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "03:00-04:00", isSelected: isTimeSlotSelected("03:00-04:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("03:00-04:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "04:00-05:00", isSelected: isTimeSlotSelected("04:00-05:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("04:00-05:00", slot: &selectedWeekendSlot)
                                    }
                                    
                                    TimeSlotButton(time: "05:00-06:00", isSelected: isTimeSlotSelected("05:00-06:00", selected: selectedWeekendSlot)) {
                                        toggleSlot("05:00-06:00", slot: &selectedWeekendSlot)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Edit Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateDoctor()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                // Fetch doctor's availability schedule when the view appears
                fetchDoctorSchedule()
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
        }
    }
    
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25)
    }
    
    private func fetchDoctorSchedule() {
        isLoadingSlots = true
        availabilityError = ""
        
        Task {
            do {
                print("🔄 Fetching doctor schedule for doctorID=\(doctor.id), hospitalID=\(hospitalId)")
                
                // Create a local function that calls the specific implementation we want
                func specificGetDoctorSchedule(doctorId: String, hospitalId: String) async throws -> (weekdaySlots: Set<String>, weekendSlots: Set<String>) {
                    return try await adminController.getDoctorSchedule(doctorId: doctorId, hospitalId: hospitalId)
                }
                
                // Call our local function that has no ambiguity
                let (weekdaySlots, weekendSlots) = try await specificGetDoctorSchedule(
                    doctorId: doctor.id, 
                    hospitalId: hospitalId
                )
                
                print("⚡️ DB returned weekday slots: \(weekdaySlots.count) slots")
                print("⚡️ DB returned weekend slots: \(weekendSlots.count) slots")
                
                // Process slots and get the first one (since we now only allow one selection)
                var weekdaySlot: String? = nil
                var weekendSlot: String? = nil
                
                print("🔄 Getting first weekday slot (if any)...")
                if let firstSlot = weekdaySlots.first {
                    weekdaySlot = firstSlot
                    print("  🔹 Selected weekday slot: \(firstSlot)")
                }
                
                print("🔄 Getting first weekend slot (if any)...")
                if let firstSlot = weekendSlots.first {
                    weekendSlot = firstSlot
                    print("  🔹 Selected weekend slot: \(firstSlot)")
                }
                
                // Update main thread with the processed slots
                await MainActor.run {
                    self.selectedWeekdaySlot = weekdaySlot
                    self.selectedWeekendSlot = weekendSlot
                    isLoadingSlots = false
                }
            } catch {
                await MainActor.run {
                    availabilityError = "Could not load availability: \(error.localizedDescription)"
                    isLoadingSlots = false
                }
            }
        }
    }
    
    private func toggleSlot(_ time: String, slot: inout String?) {
        if slot == time {
            // If already selected, deselect it
            slot = nil
        } else {
            // Otherwise, select this time slot
            slot = time
        }
        print("🔄 Toggled slot: now selected: \(slot ?? "none")")
    }
    
    // Modified to check against a single selected slot
    private func isTimeSlotSelected(_ slotToCheck: String, selected: String?) -> Bool {
        // If nothing is selected, return false
        guard let selectedSlot = selected else {
            return false
        }
        
        // Direct exact match - only way to determine selection
        return slotToCheck == selectedSlot
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
            address: address
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
                    contactNumber: phoneNumber
                )
                
                // Update the doctor's availability schedule
                // Convert single slots to sets for the API
                var weekdaySlots = Set<String>()
                if let slot = selectedWeekdaySlot {
                    weekdaySlots.insert(slot)
                }
                
                var weekendSlots = Set<String>()
                if let slot = selectedWeekendSlot {
                    weekendSlots.insert(slot)
                }
                
                try await adminController.updateDoctorSchedule(
                    doctorId: doctor.id,
                    hospitalId: hospitalId,
                    weekdaySlots: weekdaySlots,
                    weekendSlots: weekendSlots
                )
                
                // Update UI on success
                await MainActor.run {
                    // Call the update callback
                    onUpdate(updatedDoctor)
                    
                    // Show success message
                    alertMessage = "Doctor information and availability updated successfully"
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    // Normalize a time slot string to a standard format for comparison
    private func normalizeTimeSlot(_ slot: String) -> String {
        // This method is no longer used since we're doing exact matching only
        return slot
    }
}