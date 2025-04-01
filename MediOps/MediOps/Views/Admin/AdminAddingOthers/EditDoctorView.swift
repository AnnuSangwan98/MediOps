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
    @State private var hospitalId = UserDefaults.standard.string(forKey: "hospital_id") ?? ""
    
    // Doctor availability slots
    @State private var selectedWeekdaySlots = Set<String>()
    @State private var selectedWeekendSlots = Set<String>()
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
                                    TimeSlotButton(time: "06:00-07:00", isSelected: isTimeSlotSelected(slotToCheck: "06:00-07:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("06:00-07:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "07:00-08:00", isSelected: isTimeSlotSelected(slotToCheck: "07:00-08:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("07:00-08:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "08:00-09:00", isSelected: isTimeSlotSelected(slotToCheck: "08:00-09:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("08:00-09:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "09:00-10:00", isSelected: isTimeSlotSelected(slotToCheck: "09:00-10:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("09:00-10:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Morning slots (10 AM - 2 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "10:00-11:00", isSelected: isTimeSlotSelected(slotToCheck: "10:00-11:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("10:00-11:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: isTimeSlotSelected(slotToCheck: "11:00-12:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("11:00-12:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "12:00-13:00", isSelected: isTimeSlotSelected(slotToCheck: "12:00-13:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("12:00-13:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "13:00-14:00", isSelected: isTimeSlotSelected(slotToCheck: "13:00-14:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("13:00-14:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots (2 PM - 6 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "14:00-15:00", isSelected: isTimeSlotSelected(slotToCheck: "14:00-15:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("14:00-15:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "15:00-16:00", isSelected: isTimeSlotSelected(slotToCheck: "15:00-16:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("15:00-16:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "16:00-17:00", isSelected: isTimeSlotSelected(slotToCheck: "16:00-17:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("16:00-17:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "17:00-18:00", isSelected: isTimeSlotSelected(slotToCheck: "17:00-18:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("17:00-18:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots (6 PM - 10 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "18:00-19:00", isSelected: isTimeSlotSelected(slotToCheck: "18:00-19:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("18:00-19:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "19:00-20:00", isSelected: isTimeSlotSelected(slotToCheck: "19:00-20:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("19:00-20:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "20:00-21:00", isSelected: isTimeSlotSelected(slotToCheck: "20:00-21:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("20:00-21:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "21:00-22:00", isSelected: isTimeSlotSelected(slotToCheck: "21:00-22:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("21:00-22:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Night slots (10 PM - 2 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "22:00-23:00", isSelected: isTimeSlotSelected(slotToCheck: "22:00-23:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("22:00-23:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "23:00-00:00", isSelected: isTimeSlotSelected(slotToCheck: "23:00-00:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("23:00-00:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "00:00-01:00", isSelected: isTimeSlotSelected(slotToCheck: "00:00-01:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("00:00-01:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "01:00-02:00", isSelected: isTimeSlotSelected(slotToCheck: "01:00-02:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("01:00-02:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Late night slots (2 AM - 6 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "02:00-03:00", isSelected: isTimeSlotSelected(slotToCheck: "02:00-03:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("02:00-03:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "03:00-04:00", isSelected: isTimeSlotSelected(slotToCheck: "03:00-04:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("03:00-04:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "04:00-05:00", isSelected: isTimeSlotSelected(slotToCheck: "04:00-05:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("04:00-05:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "05:00-06:00", isSelected: isTimeSlotSelected(slotToCheck: "05:00-06:00", selectedSlots: selectedWeekdaySlots)) {
                                        toggleSlot("05:00-06:00", in: &selectedWeekdaySlots)
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
                                    TimeSlotButton(time: "06:00-07:00", isSelected: isTimeSlotSelected(slotToCheck: "06:00-07:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("06:00-07:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "07:00-08:00", isSelected: isTimeSlotSelected(slotToCheck: "07:00-08:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("07:00-08:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "08:00-09:00", isSelected: isTimeSlotSelected(slotToCheck: "08:00-09:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("08:00-09:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "09:00-10:00", isSelected: isTimeSlotSelected(slotToCheck: "09:00-10:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("09:00-10:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Morning slots (10 AM - 2 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "10:00-11:00", isSelected: isTimeSlotSelected(slotToCheck: "10:00-11:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("10:00-11:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: isTimeSlotSelected(slotToCheck: "11:00-12:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("11:00-12:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "12:00-13:00", isSelected: isTimeSlotSelected(slotToCheck: "12:00-13:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("12:00-13:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "13:00-14:00", isSelected: isTimeSlotSelected(slotToCheck: "13:00-14:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("13:00-14:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots (2 PM - 6 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "14:00-15:00", isSelected: isTimeSlotSelected(slotToCheck: "14:00-15:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("14:00-15:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "15:00-16:00", isSelected: isTimeSlotSelected(slotToCheck: "15:00-16:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("15:00-16:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "16:00-17:00", isSelected: isTimeSlotSelected(slotToCheck: "16:00-17:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("16:00-17:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "17:00-18:00", isSelected: isTimeSlotSelected(slotToCheck: "17:00-18:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("17:00-18:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots (6 PM - 10 PM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "18:00-19:00", isSelected: isTimeSlotSelected(slotToCheck: "18:00-19:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("18:00-19:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "19:00-20:00", isSelected: isTimeSlotSelected(slotToCheck: "19:00-20:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("19:00-20:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "20:00-21:00", isSelected: isTimeSlotSelected(slotToCheck: "20:00-21:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("20:00-21:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "21:00-22:00", isSelected: isTimeSlotSelected(slotToCheck: "21:00-22:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("21:00-22:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Night slots (10 PM - 2 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "22:00-23:00", isSelected: isTimeSlotSelected(slotToCheck: "22:00-23:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("22:00-23:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "23:00-00:00", isSelected: isTimeSlotSelected(slotToCheck: "23:00-00:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("23:00-00:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "00:00-01:00", isSelected: isTimeSlotSelected(slotToCheck: "00:00-01:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("00:00-01:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "01:00-02:00", isSelected: isTimeSlotSelected(slotToCheck: "01:00-02:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("01:00-02:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Late night slots (2 AM - 6 AM)
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "02:00-03:00", isSelected: isTimeSlotSelected(slotToCheck: "02:00-03:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("02:00-03:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "03:00-04:00", isSelected: isTimeSlotSelected(slotToCheck: "03:00-04:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("03:00-04:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "04:00-05:00", isSelected: isTimeSlotSelected(slotToCheck: "04:00-05:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("04:00-05:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "05:00-06:00", isSelected: isTimeSlotSelected(slotToCheck: "05:00-06:00", selectedSlots: selectedWeekendSlots)) {
                                        toggleSlot("05:00-06:00", in: &selectedWeekendSlots)
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
                
                print("⚡️ DB returned weekday slots: \(weekdaySlots)")
                print("⚡️ DB returned weekend slots: \(weekendSlots)")
                
                // Initialize sets to store the processed slots
                var processedWeekdaySlots = Set<String>()
                var processedWeekendSlots = Set<String>()
                
                // Process weekday slots from DB
                for slot in weekdaySlots {
                    // Convert database format to UI format (e.g., "09:00-10:00" format)
                    let processedSlot = convertToUITimeFormat(slot)
                    processedWeekdaySlots.insert(processedSlot)
                    print("✅ Processed weekday slot: \(slot) -> \(processedSlot)")
                }
                
                // Process weekend slots from DB
                for slot in weekendSlots {
                    // Convert database format to UI format
                    let processedSlot = convertToUITimeFormat(slot)
                    processedWeekendSlots.insert(processedSlot)
                    print("✅ Processed weekend slot: \(slot) -> \(processedSlot)")
                }
                
                // Update main thread with the processed slots
                await MainActor.run {
                    self.selectedWeekdaySlots = processedWeekdaySlots
                    self.selectedWeekendSlots = processedWeekendSlots
                    isLoadingSlots = false
                    
                    // Debug: Print which slots should be highlighted
                    print("🔍 WEEKDAY SLOTS TO HIGHLIGHT: \(selectedWeekdaySlots)")
                    print("🔍 WEEKEND SLOTS TO HIGHLIGHT: \(selectedWeekendSlots)")
                }
            } catch {
                await MainActor.run {
                    availabilityError = "Could not load availability: \(error.localizedDescription)"
                    isLoadingSlots = false
                }
            }
        }
    }
    
    // Helper function to convert database time format to UI format
    private func convertToUITimeFormat(_ dbSlot: String) -> String {
        // Simplify by using the exact format needed for UI time slots
        // Expecting dbSlot to come in formats like "09:00:00-10:00:00" or "9:00AM-10:00AM"
        
        // Remove any seconds and convert to the standard format used in our UI
        let slot = dbSlot.replacingOccurrences(of: ":00-", with: "-")
                         .replacingOccurrences(of: ":00:", with: ":")
        
        // Handle different formats that might come from the database
        if slot.contains(":") {
            // Already has colons, just ensure it's in the right format (HH:MM-HH:MM)
            return slot.replacingOccurrences(of: ":00", with: "")
        } else if slot.contains("-") {
            // Format like "9-10" or "9-10 AM"
            // Just return as is since we're using the same format in our UI buttons
            return slot
        }
        
        // If no special formatting needed, return as is
        return dbSlot
    }
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        // Toggle individual slot without affecting other selections
        if slots.contains(time) {
            slots.remove(time)
        } else {
            slots.insert(time)
        }
        print("🔄 Toggled slot \(time), now selected: \(slots.contains(time))")
    }
    
    private func updateDoctor() {
        isLoading = true
        
        // Ensure all slots have consistent AM/PM format before saving
        normalizeTimeSlots()
        
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
                try await adminController.updateDoctorSchedule(
                    doctorId: doctor.id,
                    hospitalId: hospitalId,
                    weekdaySlots: selectedWeekdaySlots,
                    weekendSlots: selectedWeekendSlots
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
    
    private func normalizeTimeSlots() {
        // Ensure 11:00-12:00 is always PM
        if selectedWeekdaySlots.contains("11:00-12:00 AM") {
            selectedWeekdaySlots.remove("11:00-12:00 AM")
            selectedWeekdaySlots.insert("11:00-12:00 PM")
        }
        
        if selectedWeekendSlots.contains("11:00-12:00 AM") {
            selectedWeekendSlots.remove("11:00-12:00 AM")
            selectedWeekendSlots.insert("11:00-12:00 PM")
        }
        
        // Check for any slots missing AM/PM and add them
        let newWeekdaySlots = Set<String>(selectedWeekdaySlots.map { slot in
            if !slot.contains(" AM") && !slot.contains(" PM") {
                // If no AM/PM, add appropriate suffix based on time
                let components = slot.split(separator: "-")
                if components.count == 2 {
                    let startTime = String(components[0])
                    let hours = Int(startTime.components(separatedBy: ":")[0]) ?? 0
                    if hours == 12 || hours >= 12 {
                        return "\(slot) PM"
                    } else {
                        return "\(slot) AM"
                    }
                }
            }
            return slot
        })
        
        selectedWeekdaySlots = newWeekdaySlots
        
        // Do the same for weekend slots
        let newWeekendSlots = Set<String>(selectedWeekendSlots.map { slot in
            if !slot.contains(" AM") && !slot.contains(" PM") {
                // If no AM/PM, add appropriate suffix based on time
                let components = slot.split(separator: "-")
                if components.count == 2 {
                    let startTime = String(components[0])
                    let hours = Int(startTime.components(separatedBy: ":")[0]) ?? 0
                    if hours == 12 || hours >= 12 {
                        return "\(slot) PM"
                    } else {
                        return "\(slot) AM"
                    }
                }
            }
            return slot
        })
        
        selectedWeekendSlots = newWeekendSlots
    }
    
    // Helper method to check if a time slot is selected (more flexible than direct string comparison)
    private func isTimeSlotSelected(slotToCheck: String, selectedSlots: Set<String>) -> Bool {
        return selectedSlots.contains(slotToCheck)
    }
    
    // Normalize a time slot string to a standard format for comparison
    private func normalizeTimeSlot(_ slot: String) -> String {
        // Simply return the slot as is - we'll use exact matching
        return slot
    }
    
    // Helper method to normalize a set of slots to have consistent formatting
    private func normalizeSlotFormats(_ slots: Set<String>) -> Set<String> {
        var normalizedSlots = Set<String>()
        
        // Map of backend formats to UI formats
        let formatMapping: [String: String] = [
            // AddDoctorView formats to EditDoctorView formats
            "9:00AM-10:00AM": "9:00-10:00 AM",
            "10:00AM-11:00AM": "10:00-11:00 AM",
            "11:00AM-12:00PM": "11:00-12:00 PM",
            "1:00PM-2:00PM": "1:00-2:00 PM",
            "2:00PM-3:00PM": "2:00-3:00 PM",
            "3:00PM-4:00PM": "3:00-4:00 PM",
            "4:00PM-5:00PM": "4:00-5:00 PM",
            "5:00PM-6:00PM": "5:00-6:00 PM",
            "6:00PM-7:00PM": "6:00-7:00 PM",
            "7:00PM-8:00PM": "7:00-8:00 PM",
            "8:00PM-9:00PM": "8:00-9:00 PM"
        ]
        
        // First, try direct mapping from known formats
        for slot in slots {
            if let mappedSlot = formatMapping[slot] {
                normalizedSlots.insert(mappedSlot)
                print("✅ Direct mapping: \(slot) -> \(mappedSlot)")
                continue
            }
            
            // If no direct mapping, try normalizing for comparison
            let normalizedBackendSlot = normalizeTimeSlot(slot)
            print("🔄 Normalizing slot: \(slot) -> \(normalizedBackendSlot)")
            
            var matched = false
            for uiSlot in uiTimeSlots {
                let normalizedUISlot = normalizeTimeSlot(uiSlot)
                
                if normalizedUISlot == normalizedBackendSlot {
                    normalizedSlots.insert(uiSlot)
                    print("✅ Normalized match: \(slot) -> \(uiSlot)")
                    matched = true
                    break
                }
            }
            
            // If no match found, extract time components and try to build a UI format
            if !matched {
                if let uiFormat = convertToUIFormat(slot) {
                    normalizedSlots.insert(uiFormat)
                    print("✅ Converted format: \(slot) -> \(uiFormat)")
                } else {
                    // If all else fails, just use the original slot format
                    normalizedSlots.insert(slot)
                    print("⚠️ Using original format: \(slot)")
                }
            }
        }
        
        return normalizedSlots
    }
    
    // Helper to convert any time format to the UI format
    private func convertToUIFormat(_ slot: String) -> String? {
        // Try to extract start and end times and AM/PM indicators
        var startTime = ""
        var endTime = ""
        var timeIndicator = "AM"
        
        // First, standardize the slot string
        let processed = slot.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "–", with: "-")
        
        // Check if it has AM/PM indicator
        if processed.contains("AM") {
            timeIndicator = "AM"
        } else if processed.contains("PM") {
            timeIndicator = "PM"
        }
        
        // Try to split by dash
        let components = processed.components(separatedBy: "-")
        if components.count == 2 {
            // Extract start time
            var start = components[0]
            start = start.replacingOccurrences(of: "AM", with: "")
                .replacingOccurrences(of: "PM", with: "")
            
            // Extract end time
            var end = components[1]
            end = end.replacingOccurrences(of: "AM", with: "")
                .replacingOccurrences(of: "PM", with: "")
            
            // Format according to UI standards with space before AM/PM
            return "\(start)-\(end) \(timeIndicator)"
        }
        
        return nil
    }
}

// TimeSlotButton Component is imported from AddDoctorView.swift 