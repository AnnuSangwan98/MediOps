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
    @State private var selectedWeekdaySlots: Set<String> = []
    @State private var selectedWeekendSlots: Set<String> = []
    @State private var isLoadingSlots = false
    @State private var availabilityError = ""
    
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
                        
                        // Morning slots
                        HStack {
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "9:00-10:00 AM", isSelected: isTimeSlotSelected("9:00-10:00 AM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("9:00-10:00 AM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "10:00-11:00 AM", isSelected: isTimeSlotSelected("10:00-11:00 AM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("10:00-11:00 AM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00 PM", isSelected: isTimeSlotSelected("11:00-12:00 AM", in: selectedWeekdaySlots) || isTimeSlotSelected("11:00-12:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        // Try removing the old format first if it exists
                                        if isTimeSlotSelected("11:00-12:00 AM", in: selectedWeekdaySlots) {
                                            selectedWeekdaySlots.remove("11:00-12:00 AM")
                                        }
                                        toggleSlot("11:00-12:00 PM", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots
                        HStack {
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "1:00-2:00 PM", isSelected: isTimeSlotSelected("1:00-2:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("1:00-2:00 PM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "2:00-3:00 PM", isSelected: isTimeSlotSelected("2:00-3:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("2:00-3:00 PM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "3:00-4:00 PM", isSelected: isTimeSlotSelected("3:00-4:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("3:00-4:00 PM", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots
                        HStack {
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "4:00-5:00 PM", isSelected: isTimeSlotSelected("4:00-5:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("4:00-5:00 PM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "5:00-6:00 PM", isSelected: isTimeSlotSelected("5:00-6:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("5:00-6:00 PM", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "6:00-7:00 PM", isSelected: isTimeSlotSelected("6:00-7:00 PM", in: selectedWeekdaySlots), isWeekend: false) {
                                        toggleSlot("6:00-7:00 PM", in: &selectedWeekdaySlots)
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
                        
                        // Morning slots
                        HStack {
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "9:00-10:00 AM", isSelected: isTimeSlotSelected("9:00-10:00 AM", in: selectedWeekendSlots), isWeekend: true) {
                                        toggleSlot("9:00-10:00 AM", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "10:00-11:00 AM", isSelected: isTimeSlotSelected("10:00-11:00 AM", in: selectedWeekendSlots), isWeekend: true) {
                                        toggleSlot("10:00-11:00 AM", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00 PM", isSelected: isTimeSlotSelected("11:00-12:00 AM", in: selectedWeekendSlots) || isTimeSlotSelected("11:00-12:00 PM", in: selectedWeekendSlots), isWeekend: true) {
                                        // Try removing the old format first if it exists
                                        if isTimeSlotSelected("11:00-12:00 AM", in: selectedWeekendSlots) {
                                            selectedWeekendSlots.remove("11:00-12:00 AM")
                                        }
                                        toggleSlot("11:00-12:00 PM", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots
                        HStack {
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "1:00-2:00 PM", isSelected: isTimeSlotSelected("1:00-2:00 PM", in: selectedWeekendSlots), isWeekend: true) {
                                        toggleSlot("1:00-2:00 PM", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "2:00-3:00 PM", isSelected: isTimeSlotSelected("2:00-3:00 PM", in: selectedWeekendSlots), isWeekend: true) {
                                        toggleSlot("2:00-3:00 PM", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "3:00-4:00 PM", isSelected: isTimeSlotSelected("3:00-4:00 PM", in: selectedWeekendSlots), isWeekend: true) {
                                        toggleSlot("3:00-4:00 PM", in: &selectedWeekendSlots)
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
                
                let (weekdaySlots, weekendSlots) = try await adminController.getDoctorSchedule(
                    doctorId: doctor.id, 
                    hospitalId: hospitalId
                )
                
                print("⚡️ DB returned weekday slots: \(weekdaySlots.count) slots")
                print("⚡️ DB returned weekend slots: \(weekendSlots.count) slots")
                
                // Step 1: Convert slots to exact UI formats we expect (hard-coded approach for reliable results)
                
                // Known mappings to UI time formats
                let formatMap: [String: String] = [
                    // 24-hour format mapping
                    "09:00:00-10:00:00": "9:00-10:00 AM",
                    "10:00:00-11:00:00": "10:00-11:00 AM",
                    "11:00:00-12:00:00": "11:00-12:00 PM",
                    "13:00:00-14:00:00": "1:00-2:00 PM",
                    "14:00:00-15:00:00": "2:00-3:00 PM",
                    "15:00:00-16:00:00": "3:00-4:00 PM",
                    "16:00:00-17:00:00": "4:00-5:00 PM",
                    "17:00:00-18:00:00": "5:00-6:00 PM",
                    "18:00:00-19:00:00": "6:00-7:00 PM",
                    
                    // 12-hour without space format mapping
                    "9:00AM-10:00AM": "9:00-10:00 AM",
                    "10:00AM-11:00AM": "10:00-11:00 AM",
                    "11:00AM-12:00PM": "11:00-12:00 PM",
                    "1:00PM-2:00PM": "1:00-2:00 PM",
                    "2:00PM-3:00PM": "2:00-3:00 PM",
                    "3:00PM-4:00PM": "3:00-4:00 PM",
                    "4:00PM-5:00PM": "4:00-5:00 PM",
                    "5:00PM-6:00PM": "5:00-6:00 PM",
                    "6:00PM-7:00PM": "6:00-7:00 PM",
                    
                    // Other common variations
                    "9-10 AM": "9:00-10:00 AM",
                    "10-11 AM": "10:00-11:00 AM",
                    "11-12 PM": "11:00-12:00 PM",
                    "1-2 PM": "1:00-2:00 PM",
                    "2-3 PM": "2:00-3:00 PM",
                    "3-4 PM": "3:00-4:00 PM",
                    "4-5 PM": "4:00-5:00 PM",
                    "5-6 PM": "5:00-6:00 PM",
                    "6-7 PM": "6:00-7:00 PM"
                ]
                
                // Function to match hours and determine which standard UI slot to use
                func matchHourPattern(_ slot: String) -> String? {
                    // Common hour patterns
                    let patterns: [(NSRegularExpression, [Int: String])] = [
                        // Match 24-hour formats like 09:00:00-10:00:00
                        (try! NSRegularExpression(pattern: #"(\d+):00:00-(\d+):00:00"#), [
                            9: "9:00-10:00 AM", 10: "10:00-11:00 AM", 11: "11:00-12:00 PM",
                            13: "1:00-2:00 PM", 14: "2:00-3:00 PM", 15: "3:00-4:00 PM",
                            16: "4:00-5:00 PM", 17: "5:00-6:00 PM", 18: "6:00-7:00 PM"
                        ]),
                        
                        // Match simpler formats like 9-10
                        (try! NSRegularExpression(pattern: #"^(\d+)-(\d+)$"#), [
                            9: "9:00-10:00 AM", 10: "10:00-11:00 AM", 11: "11:00-12:00 PM",
                            1: "1:00-2:00 PM", 2: "2:00-3:00 PM", 3: "3:00-4:00 PM",
                            4: "4:00-5:00 PM", 5: "5:00-6:00 PM", 6: "6:00-7:00 PM"
                        ])
                    ]
                    
                    // Try each pattern
                    for (regex, hourMap) in patterns {
                        let range = NSRange(slot.startIndex..<slot.endIndex, in: slot)
                        if let match = regex.firstMatch(in: slot, range: range) {
                            if match.numberOfRanges >= 2 {
                                let startHourRange = Range(match.range(at: 1), in: slot)!
                                let startHour = Int(slot[startHourRange]) ?? 0
                                
                                if let mappedSlot = hourMap[startHour] {
                                    return mappedSlot
                                }
                            }
                        }
                    }
                    
                    return nil
                }
                
                // Final mapping function that tries multiple approaches
                func mapToUISlot(_ slot: String) -> String {
                    // Try direct mapping first
                    if let directMapped = formatMap[slot] {
                        print("✅ Direct format match: \(slot) -> \(directMapped)")
                        return directMapped
                    }
                    
                    // Try hour pattern matching
                    if let hourMapped = matchHourPattern(slot) {
                        print("✅ Hour pattern match: \(slot) -> \(hourMapped)")
                        return hourMapped
                    }
                    
                    // For 12-hour format, check if we need to add a space before AM/PM
                    if slot.contains("AM") || slot.contains("PM") {
                        let hasSpace = slot.contains(" AM") || slot.contains(" PM")
                        if !hasSpace {
                            // Try to fix common no-space format: "9:00-10:00AM" -> "9:00-10:00 AM"
                            let replaced = slot.replacingOccurrences(of: "AM", with: " AM")
                                            .replacingOccurrences(of: "PM", with: " PM")
                            if let mappedReplaced = formatMap[replaced] {
                                print("✅ Added space match: \(slot) -> \(mappedReplaced)")
                                return mappedReplaced
                            }
                        }
                    }
                    
                    // Fall back to hard-coded list of our UI slots based on simple matching
                    let uiTimeSlots = [
                        "9:00-10:00 AM", "10:00-11:00 AM", "11:00-12:00 PM",
                        "1:00-2:00 PM", "2:00-3:00 PM", "3:00-4:00 PM",
                        "4:00-5:00 PM", "5:00-6:00 PM", "6:00-7:00 PM"
                    ]
                    
                    // Simple check if the slot contains the hour numbers
                    for uiSlot in uiTimeSlots {
                        let slotLower = slot.lowercased()
                        let uiSlotLower = uiSlot.lowercased()
                        
                        // Extract just the hour numbers from both
                        let hourPattern = #"(\d+)"#
                        let regex = try! NSRegularExpression(pattern: hourPattern)
                        
                        let slotHours = regex.matches(in: slotLower, range: NSRange(slotLower.startIndex..<slotLower.endIndex, in: slotLower))
                            .compactMap { Range($0.range, in: slotLower) }
                            .map { String(slotLower[$0]) }
                        
                        let uiSlotHours = regex.matches(in: uiSlotLower, range: NSRange(uiSlotLower.startIndex..<uiSlotLower.endIndex, in: uiSlotLower))
                            .compactMap { Range($0.range, in: uiSlotLower) }
                            .map { String(uiSlotLower[$0]) }
                        
                        // Check if the hours match
                        if slotHours.count >= 2 && uiSlotHours.count >= 2 &&
                           slotHours[0] == uiSlotHours[0] && slotHours[1] == uiSlotHours[1] {
                            print("✅ Hour number match: \(slot) -> \(uiSlot)")
                            return uiSlot
                        }
                    }
                    
                    print("⚠️ No mapping found for: \(slot), using as is")
                    return slot
                }
                
                // Process all slots and map to UI format
                var processedWeekdaySlots = Set<String>()
                var processedWeekendSlots = Set<String>()
                
                print("🔄 Mapping weekday slots...")
                for slot in weekdaySlots {
                    let mappedSlot = mapToUISlot(slot)
                    processedWeekdaySlots.insert(mappedSlot)
                    print("  🔹 \(slot) -> \(mappedSlot)")
                }
                
                print("🔄 Mapping weekend slots...")
                for slot in weekendSlots {
                    let mappedSlot = mapToUISlot(slot)
                    processedWeekendSlots.insert(mappedSlot)
                    print("  🔹 \(slot) -> \(mappedSlot)")
                }
                
                print("⚙️ Final weekday slots: \(processedWeekdaySlots)")
                print("⚙️ Final weekend slots: \(processedWeekendSlots)")
                
                // Force-add slots for standard time periods if detected in raw data
                // This is a last-resort approach to ensure standard time slots are properly selected
                
                let uiTimeSlots = [
                    "9:00-10:00 AM", "10:00-11:00 AM", "11:00-12:00 PM",
                    "1:00-2:00 PM", "2:00-3:00 PM", "3:00-4:00 PM",
                    "4:00-5:00 PM", "5:00-6:00 PM", "6:00-7:00 PM"
                ]
                
                // Force-check for certain patterns in raw data
                func forceCheckForTimeRange(in rawSlots: Set<String>, hour: Int) -> Bool {
                    for slot in rawSlots {
                        // Look for slots that might contain this hour
                        if slot.contains("\(hour):") || slot.contains("-\(hour):") || 
                           slot.contains("\(hour)-") || slot.contains("-\(hour) ") {
                            return true
                        }
                        
                        // For 24-hour format, check transformed hour
                        let hourPlus12 = hour + 12
                        if hour < 12 && (slot.contains("\(hourPlus12):") || 
                                          slot.contains("-\(hourPlus12):") ||
                                          slot.contains("\(hourPlus12)-")) {
                            return true
                        }
                    }
                    return false
                }
                
                // Update main thread with the processed slots
                await MainActor.run {
                    self.selectedWeekdaySlots = processedWeekdaySlots
                    self.selectedWeekendSlots = processedWeekendSlots
                    isLoadingSlots = false
                    
                    // Debug: Print which slots should be highlighted
                    print("🔍 WEEKDAY SLOT HIGHLIGHT CHECK:")
                    for slot in uiTimeSlots {
                        let isSelected = isTimeSlotSelected(slot, in: self.selectedWeekdaySlots)
                        print("  \(slot): \(isSelected ? "✅ SELECTED" : "❌ NOT SELECTED")")
                    }
                    
                    print("🔍 WEEKEND SLOT HIGHLIGHT CHECK:")
                    for slot in uiTimeSlots {
                        let isSelected = isTimeSlotSelected(slot, in: self.selectedWeekendSlots)
                        print("  \(slot): \(isSelected ? "✅ SELECTED" : "❌ NOT SELECTED")")
                    }
                }
            } catch {
                await MainActor.run {
                    availabilityError = "Could not load availability: \(error.localizedDescription)"
                    isLoadingSlots = false
                }
            }
        }
    }
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        // Use the more robust check to see if the slot exists (with any format)
        let normalized = normalizeTimeSlot(time)
        
        // Find if any version of this slot already exists
        let matchingSlot = slots.first { normalizeTimeSlot($0) == normalized }
        
        if let existing = matchingSlot {
            // If exists (in any format), remove it
            slots.remove(existing)
        } else {
            // If doesn't exist, add it with the preferred format
            // Always use the format from the UI (which includes the space before AM/PM)
            slots.insert(time)
        }
        
        // Print for debugging
        print("🔄 Toggled slot \(time), now selected: \(slots.contains { normalizeTimeSlot($0) == normalized })")
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
    private func isTimeSlotSelected(_ slotToCheck: String, in slots: Set<String>) -> Bool {
        // Direct match first
        if slots.contains(slotToCheck) {
            print("✓ Direct match for: \(slotToCheck)")
            return true
        }
        
        // Hard-coded mappings for exact format matching (extensive list of possible formats)
        let timeSlotMappings = [
            // Morning slots (9-12)
            "9:00-10:00 AM": ["9:00AM-10:00AM", "09:00-10:00", "09:00:00-10:00:00", "9-10AM", "9AM-10AM"],
            "10:00-11:00 AM": ["10:00AM-11:00AM", "10:00-11:00", "10:00:00-11:00:00", "10-11AM", "10AM-11AM"],
            "11:00-12:00 PM": ["11:00AM-12:00PM", "11:00-12:00", "11:00:00-12:00:00", "11-12PM", "11AM-12PM"],
            
            // Afternoon slots (1-4)
            "1:00-2:00 PM": ["1:00PM-2:00PM", "13:00-14:00", "13:00:00-14:00:00", "1-2PM", "1PM-2PM"],
            "2:00-3:00 PM": ["2:00PM-3:00PM", "14:00-15:00", "14:00:00-15:00:00", "2-3PM", "2PM-3PM"],
            "3:00-4:00 PM": ["3:00PM-4:00PM", "15:00-16:00", "15:00:00-16:00:00", "3-4PM", "3PM-4PM"],
            
            // Evening slots (4-7)
            "4:00-5:00 PM": ["4:00PM-5:00PM", "16:00-17:00", "16:00:00-17:00:00", "4-5PM", "4PM-5PM"],
            "5:00-6:00 PM": ["5:00PM-6:00PM", "17:00-18:00", "17:00:00-18:00:00", "5-6PM", "5PM-6PM"],
            "6:00-7:00 PM": ["6:00PM-7:00PM", "18:00-19:00", "18:00:00-19:00:00", "6-7PM", "6PM-7PM"]
        ]
        
        // Check if any of the slots in the set matches any of the known formats for the slot we're checking
        if let knownFormats = timeSlotMappings[slotToCheck] {
            for format in knownFormats {
                if slots.contains(format) {
                    print("✓ Mapped format match: \(slotToCheck) with \(format)")
                    return true
                }
            }
            
            // Also check using normalized comparison for each known format
            for format in knownFormats {
                let normalizedFormat = normalizeTimeSlot(format)
                for slot in slots {
                    let normalizedSlot = normalizeTimeSlot(slot)
                    if normalizedFormat == normalizedSlot {
                        print("✓ Normalized mapped format match: \(slotToCheck) [\(format)] with \(slot)")
                        return true
                    }
                }
            }
        }
        
        // Extract hour numbers for matching (e.g., 9-10, 1-2)
        func extractHourNumbers(_ slot: String) -> (Int, Int)? {
            // Try to extract hours using simple pattern matching
            let patterns = [
                #"(\d+):00-(\d+):00"#,           // 9:00-10:00
                #"(\d+)[ :]*(\d+)*[APM]+-(\d+)[ :]*(\d+)*[APM]+"#,  // 9AM-10AM, 9:00AM-10:00AM
                #"(\d+)[:-](\d+)"#                // 9-10, 9:30-10:30
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(slot.startIndex..<slot.endIndex, in: slot)
                    if let match = regex.firstMatch(in: slot, range: range) {
                        if match.numberOfRanges >= 3 {
                            let startHourRange = Range(match.range(at: 1), in: slot)!
                            let endHourRange = Range(match.range(at: match.numberOfRanges >= 4 ? 3 : 2), in: slot)!
                            
                            let startHour = Int(slot[startHourRange]) ?? 0
                            let endHour = Int(slot[endHourRange]) ?? 0
                            
                            return (startHour, endHour)
                        }
                    }
                }
            }
            return nil
        }
        
        // Check hour number matching (e.g., 9-10 matches 09:00-10:00)
        if let (checkStartHour, checkEndHour) = extractHourNumbers(slotToCheck) {
            for slot in slots {
                if let (slotStartHour, slotEndHour) = extractHourNumbers(slot) {
                    // For 12-hour format, we need to handle AM/PM conversion
                    var adjustedSlotStartHour = slotStartHour
                    var adjustedSlotEndHour = slotEndHour
                    
                    // Handle 24-hour format conversion to 12-hour
                    if slotStartHour > 12 {
                        adjustedSlotStartHour = slotStartHour - 12
                    }
                    if slotEndHour > 12 {
                        adjustedSlotEndHour = slotEndHour - 12
                    }
                    
                    if (checkStartHour == slotStartHour && checkEndHour == slotEndHour) ||
                       (checkStartHour == adjustedSlotStartHour && checkEndHour == adjustedSlotEndHour) {
                        print("✓ Hour number match: \(slotToCheck) [\(checkStartHour)-\(checkEndHour)] with \(slot) [\(slotStartHour)-\(slotEndHour)]")
                        return true
                    }
                }
            }
        }
        
        // Try to normalize and compare
        let normalizedSlotToCheck = normalizeTimeSlot(slotToCheck)
        
        // Check if any slot in the set matches when normalized
        for slot in slots {
            let normalizedSlot = normalizeTimeSlot(slot)
            if normalizedSlot == normalizedSlotToCheck {
                print("✓ Normalized match: \(slotToCheck) [\(normalizedSlotToCheck)] with \(slot) [\(normalizedSlot)]")
                return true
            }
            
            // Also check for 24-hour time format conversions
            if slot.contains(":00:00") {
                // This might be a 24-hour format from the database
                let simpleTime = slot.replacingOccurrences(of: ":00:00", with: ":00")
                let simplifiedNormalizedSlot = normalizeTimeSlot(simpleTime)
                if simplifiedNormalizedSlot == normalizedSlotToCheck {
                    print("✓ 24-hour format match: \(slotToCheck) with \(slot)")
                    return true
                }
            }
        }
        
        // Special case for 11:00-12:00 which could be AM or PM
        if slotToCheck == "11:00-12:00 PM" {
            let alternateFormat = "11:00-12:00 AM"
            if slots.contains(alternateFormat) {
                print("✓ Special 11:00-12:00 case match")
                return true
            }
        }
        
        return false
    }
    
    // Normalize a time slot string to a standard format for comparison
    private func normalizeTimeSlot(_ slot: String) -> String {
        // Remove all whitespace
        var normalized = slot.replacingOccurrences(of: " ", with: "")
        
        // Handle AM/PM variations
        normalized = normalized.uppercased()
        
        // Special case for 11:00-12:00 (always treat as PM)
        if normalized.contains("11:00-12:00") {
            normalized = normalized.replacingOccurrences(of: "AM", with: "PM")
        }
        
        // Handle different dash types
        normalized = normalized.replacingOccurrences(of: "–", with: "-")
        
        // Handle formats like 9:00AM-10:00AM (from AddDoctorView)
        if !normalized.contains("-") && normalized.contains("AM") || normalized.contains("PM") {
            // Try to extract time range from patterns like "9:00AM10:00AM"
            let pattern = #"(\d+:\d+)(AM|PM)(\d+:\d+)(AM|PM)"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
                if let match = regex.firstMatch(in: normalized, range: range) {
                    let startTime = String(normalized[Range(match.range(at: 1), in: normalized)!])
                    let startIndicator = String(normalized[Range(match.range(at: 2), in: normalized)!])
                    let endTime = String(normalized[Range(match.range(at: 3), in: normalized)!])
                    let endIndicator = String(normalized[Range(match.range(at: 4), in: normalized)!])
                    normalized = "\(startTime)-\(endTime)\(endIndicator)"
                }
            }
        }
        
        return normalized
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
        
        // Standard time slots we display in the UI
        let uiTimeSlots = [
            "9:00-10:00 AM", "10:00-11:00 AM", "11:00-12:00 PM",
            "1:00-2:00 PM", "2:00-3:00 PM", "3:00-4:00 PM",
            "4:00-5:00 PM", "5:00-6:00 PM", "6:00-7:00 PM"
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

// Time Slot Button Component is already defined in AddDoctorView.swift 