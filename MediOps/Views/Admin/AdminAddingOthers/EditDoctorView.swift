import SwiftUI
import Combine

struct EditDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var specialization: Specialization
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
        _specialization = State(initialValue: Specialization.allCases.first(where: { $0.rawValue == doctor.specialization }) ?? .generalMedicine)
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
                    Text("AVAILABILITY SCHEDULE")
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
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Weekday time slots section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekday Slots (MON-FRI)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Morning slots
                            TimeSlotSection(
                                title: "Morning",
                                slots: ["06:00-07:00", "07:00-08:00", "08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"],
                                selectedSlots: selectedWeekdaySlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekdaySlots)
                            }
                            
                            // Afternoon slots
                            TimeSlotSection(
                                title: "Afternoon",
                                slots: ["12:00-13:00", "13:00-14:00", "14:00-15:00", "15:00-16:00", "16:00-17:00"],
                                selectedSlots: selectedWeekdaySlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekdaySlots)
                            }
                            
                            // Evening slots
                            TimeSlotSection(
                                title: "Evening",
                                slots: ["17:00-18:00", "18:00-19:00", "19:00-20:00", "20:00-21:00", "21:00-22:00"],
                                selectedSlots: selectedWeekdaySlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekdaySlots)
                            }
                            
                            // Night slots
                            TimeSlotSection(
                                title: "Night",
                                slots: ["22:00-23:00", "23:00-00:00", "00:00-01:00", "01:00-02:00", "02:00-03:00", "03:00-04:00", "04:00-05:00", "05:00-06:00"],
                                selectedSlots: selectedWeekdaySlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekdaySlots)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Weekend time slots section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekend Slots (SAT-SUN)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Morning slots
                            TimeSlotSection(
                                title: "Morning",
                                slots: ["06:00-07:00", "07:00-08:00", "08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"],
                                selectedSlots: selectedWeekendSlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekendSlots)
                            }
                            
                            // Afternoon slots
                            TimeSlotSection(
                                title: "Afternoon",
                                slots: ["12:00-13:00", "13:00-14:00", "14:00-15:00", "15:00-16:00", "16:00-17:00"],
                                selectedSlots: selectedWeekendSlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekendSlots)
                            }
                            
                            // Evening slots
                            TimeSlotSection(
                                title: "Evening",
                                slots: ["17:00-18:00", "18:00-19:00", "19:00-20:00", "20:00-21:00", "21:00-22:00"],
                                selectedSlots: selectedWeekendSlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekendSlots)
                            }
                            
                            // Night slots
                            TimeSlotSection(
                                title: "Night",
                                slots: ["22:00-23:00", "23:00-00:00", "00:00-01:00", "01:00-02:00", "02:00-03:00", "03:00-04:00", "04:00-05:00", "05:00-06:00"],
                                selectedSlots: selectedWeekendSlots
                            ) { slot in
                                toggleSlot(slot, in: &selectedWeekendSlots)
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
                print("🔄 Attempting to fetch schedule for doctorID=\(doctor.id), hospitalID=\(hospitalId)")
                
                // First try a direct query without single() to see all possible matches
                let checkResponse = try await adminController.supabase
                    .from("doctor_availability_efficient")
                    .select("id, doctor_id, hospital_id")
                    .eq("doctor_id", value: doctor.id)
                    .execute()
                
                print("🔍 Available records for this doctor: \(String(describing: checkResponse.data))")
                
                // Now try the full query to get the weekly schedule
                let response = try await adminController.supabase
                    .from("doctor_availability_efficient")
                    .select("*")  // Select all fields for debugging
                    .eq("doctor_id", value: doctor.id)
                    .execute()
                
                print("📋 Complete response data: \(String(describing: response.data))")
                
                var foundWeekdaySlots = Set<String>()
                var foundWeekendSlots = Set<String>()
                
                // Check if we got a valid array response
                if let scheduleDataArray = response.data as? [[String: Any]], !scheduleDataArray.isEmpty {
                    let scheduleData = scheduleDataArray[0]  // Take the first record
                    print("📊 Processing record: \(scheduleData)")
                    
                    if let weeklySchedule = scheduleData["weekly_schedule"] as? [String: Any] {
                        print("📅 Found weekly_schedule: \(weeklySchedule)")
                        
                        // Process weekday slots
                        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday"]
                        for day in weekdays {
                            if let daySlots = weeklySchedule[day] as? [[String: Any]] {
                                for slot in daySlots {
                                    if let start = slot["start"] as? String,
                                       let end = slot["end"] as? String,
                                       let available = slot["available"] as? Bool,
                                       available {
                                        let timeSlot = "\(start)-\(end)"
                                        foundWeekdaySlots.insert(timeSlot)
                                        print("✅ Added weekday slot for \(day): \(timeSlot)")
                                    }
                                }
                            }
                        }
                        
                        // Process weekend slots
                        let weekends = ["saturday", "sunday"]
                        for day in weekends {
                            if let daySlots = weeklySchedule[day] as? [[String: Any]] {
                                for slot in daySlots {
                                    if let start = slot["start"] as? String,
                                       let end = slot["end"] as? String,
                                       let available = slot["available"] as? Bool,
                                       available {
                                        let timeSlot = "\(start)-\(end)"
                                        foundWeekendSlots.insert(timeSlot)
                                        print("✅ Added weekend slot for \(day): \(timeSlot)")
                                    }
                                }
                            }
                        }
                    } else {
                        print("⚠️ No weekly_schedule field found in the record: \(scheduleData.keys)")
                    }
                } else {
                    print("⚠️ No records found for doctor_id=\(doctor.id) in doctor_availability_efficient table")
                }
                
                await MainActor.run {
                    // Use the found slots to update the UI
                    selectedWeekdaySlots = foundWeekdaySlots
                    selectedWeekendSlots = foundWeekendSlots
                    isLoadingSlots = false
                    
                    print("🔍 Weekday slots found in DB: \(foundWeekdaySlots.count) slots")
                    print("🔍 Weekend slots found in DB: \(foundWeekendSlots.count) slots")
                    print("🔍 Weekday slots to highlight: \(selectedWeekdaySlots)")
                    print("🔍 Weekend slots to highlight: \(selectedWeekendSlots)")
                }
            } catch {
                print("❌ Error fetching doctor schedule: \(error)")
                await MainActor.run {
                    availabilityError = "Could not load availability: \(error.localizedDescription)"
                    isLoadingSlots = false
                }
            }
        }
    }
    
    private func isTimeSlotSelected(_ slot: String) -> Bool {
        // Normalize the display slot to match database format (24-hour)
        let normalizedSlot = normalizeSlotFormat(slot)
        
        // Check if the normalized slot is in our selected sets
        if selectedWeekdaySlots.contains(normalizedSlot) || selectedWeekendSlots.contains(normalizedSlot) {
            print("✅ Matched slot directly: \(slot) as \(normalizedSlot)")
            return true
        }
        
        // Try alternate formats that might be in the database
        // This handles cases where time formats might differ slightly
        for dbSlot in selectedWeekdaySlots.union(selectedWeekendSlots) {
            // Compare the time components (start and end) separately
            let dbComponents = dbSlot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            let slotComponents = normalizedSlot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if dbComponents.count == 2 && slotComponents.count == 2 {
                let dbStart = dbComponents[0]
                let dbEnd = dbComponents[1]
                let slotStart = slotComponents[0]
                let slotEnd = slotComponents[1]
                
                // Compare with some flexibility for different formats
                if compareTimeComponents(slotStart, dbStart) && compareTimeComponents(slotEnd, dbEnd) {
                    print("✅ Matched slot by components: \(slot) with DB slot: \(dbSlot)")
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper to compare time components with flexibility
    private func compareTimeComponents(_ time1: String, _ time2: String) -> Bool {
        // Direct match
        if time1 == time2 {
            return true
        }
        
        // Try to normalize and compare again (handles 2:00 vs 02:00)
        let norm1 = normalizeTimeComponent(time1)
        let norm2 = normalizeTimeComponent(time2)
        
        return norm1 == norm2
    }
    
    // Normalize individual time component (e.g. "2:00" to "02:00")
    private func normalizeTimeComponent(_ time: String) -> String {
        let parts = time.split(separator: ":")
        if parts.count == 2, let hour = Int(parts[0]) {
            return String(format: "%02d:%@", hour, parts[1])
        }
        return time
    }
    
    // Helper function to ensure consistent slot format
    private func normalizeSlotFormat(_ slot: String) -> String {
        // Split into components and clean up whitespace
        let components = slot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        
        if components.count == 2 {
            var start = components[0]
            var end = components[1]
            
            // Remove any AM/PM indicators and convert to 24-hour format
            if start.lowercased().contains("am") || start.lowercased().contains("pm") {
                start = convertTo24Hour(start)
            }
            
            if end.lowercased().contains("am") || end.lowercased().contains("pm") {
                end = convertTo24Hour(end)
            }
            
            // Add colon if missing
            if !start.contains(":") {
                start = "\(start):00"
            }
            
            if !end.contains(":") {
                end = "\(end):00"
            }
            
            // Ensure leading zeros for hours
            let startParts = start.split(separator: ":")
            let endParts = end.split(separator: ":")
            
            if startParts.count == 2 {
                let hour = Int(startParts[0]) ?? 0
                let minute = startParts[1]
                start = String(format: "%02d:%@", hour, minute)
            }
            
            if endParts.count == 2 {
                let hour = Int(endParts[0]) ?? 0
                let minute = endParts[1]
                end = String(format: "%02d:%@", hour, minute)
            }
            
            return "\(start)-\(end)"
        }
        
        return slot
    }
    
    // Convert 12-hour format to 24-hour format
    private func convertTo24Hour(_ time12: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        if let date = formatter.date(from: time12) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        return time12
    }
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        // Normalize the slot format to match the database format
        let normalizedTime = normalizeSlotFormat(time)
        print("🔄 Toggling slot: \(time) → normalized: \(normalizedTime)")
        
        // Check if this slot or a variant of it is already in the set
        var foundExistingSlot = false
        var existingSlot = ""
        
        // First check direct match
        if slots.contains(normalizedTime) {
            foundExistingSlot = true
            existingSlot = normalizedTime
        } else {
            // Then check component-wise
            for dbSlot in slots {
                let dbComponents = dbSlot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                let slotComponents = normalizedTime.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
                
                if dbComponents.count == 2 && slotComponents.count == 2 {
                    let dbStart = dbComponents[0]
                    let dbEnd = dbComponents[1]
                    let slotStart = slotComponents[0]
                    let slotEnd = slotComponents[1]
                    
                    if compareTimeComponents(slotStart, dbStart) && compareTimeComponents(slotEnd, dbEnd) {
                        foundExistingSlot = true
                        existingSlot = dbSlot
                        break
                    }
                }
            }
        }
        
        // Toggle the slot
        if foundExistingSlot {
            slots.remove(existingSlot)
            print("🗑️ Removed slot: \(existingSlot)")
        } else {
            slots.insert(normalizedTime)
            print("➕ Added slot: \(normalizedTime)")
        }
        
        print("📋 Updated slot count: \(slots.count)")
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
                try await updateDoctorAvailability()
                
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
    
    private func createSlotObject(_ slot: String, isBooked: Bool = true) -> [String: Any] {
        let normalizedSlot = normalizeSlotFormat(slot)
        let components = normalizedSlot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        
        print("🧩 Creating slot object for: \(slot) -> normalized: \(normalizedSlot)")
        
        if components.count == 2 {
            return [
                "start": components[0],
                "end": components[1],
                "available": isBooked
            ]
        }
        
        // Fallback if the format is not as expected
        let parts = slot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        return [
            "start": parts.first ?? "",
            "end": parts.count > 1 ? parts[1] : "",
            "available": isBooked
        ]
    }
    
    private func getAllPossibleTimeSlots() -> [String] {
        return [
            "09:00-10:00", "10:00-11:00", "11:00-12:00",  // Morning
            "12:00-13:00", "13:00-14:00", "14:00-15:00",  // Early Afternoon
            "15:00-16:00", "16:00-17:00", "17:00-18:00",  // Late Afternoon
            "18:00-19:00", "19:00-20:00", "20:00-21:00"   // Evening
        ]
    }
    
    private func updateDoctorAvailability() async throws {
        print("📝 Starting schedule update for doctor: \(doctor.id)")
        
        // Create the weekly schedule structure
        var weeklySchedule: [String: [[String: Any]]] = [
            "monday": [],
            "tuesday": [],
            "wednesday": [],
            "thursday": [],
            "friday": [],
            "saturday": [],
            "sunday": []
        ]

        // Process weekday slots
        for slot in selectedWeekdaySlots {
            let slotObject = createSlotObject(slot)
            for day in ["monday", "tuesday", "wednesday", "thursday", "friday"] {
                weeklySchedule[day]?.append(slotObject)
            }
        }

        // Process weekend slots
        for slot in selectedWeekendSlots {
            let slotObject = createSlotObject(slot)
            for day in ["saturday", "sunday"] {
                weeklySchedule[day]?.append(slotObject)
            }
        }

        // Add all possible slots with isBooked = false for unselected slots
        let allPossibleSlots = getAllPossibleTimeSlots()
        for (day, _) in weeklySchedule {
            let selectedSlots = day.contains("sat") || day.contains("sun") 
                ? selectedWeekendSlots 
                : selectedWeekdaySlots
            
            for slot in allPossibleSlots {
                if !selectedSlots.contains(slot) {
                    weeklySchedule[day]?.append(createSlotObject(slot, isBooked: false))
                }
            }
            
            // Sort slots by start time
            weeklySchedule[day]?.sort { slot1, slot2 in
                guard let start1 = slot1["start"] as? String,
                      let start2 = slot2["start"] as? String else {
                    return false
                }
                return start1 < start2
            }
        }

        print("📅 Final weekly schedule to save: \(weeklySchedule)")
        
        // First check if a record exists
        let checkResponse = try await adminController.supabase
            .from("doctor_availability_efficient")
            .select("id, doctor_id")
            .eq("doctor_id", value: doctor.id)
            .execute()
        
        let recordExists = (checkResponse.data as? [[String: Any]])?.first != nil
        print("🔍 Record exists check: \(recordExists)")
        
        // Prepare the data to save
        let dataToSave: [String: Any] = [
            "doctor_id": doctor.id,
            "hospital_id": hospitalId,
            "weekly_schedule": weeklySchedule,
            "max_normal_patients": 6,
            "max_premium_patients": 2
        ]
        
        // Update or insert the schedule in Supabase
        if recordExists {
            print("⚙️ Updating existing record")
            try await adminController.supabase
                .from("doctor_availability_efficient")
                .update(dataToSave)
                .eq("doctor_id", value: doctor.id)
                .execute()
        } else {
            print("➕ Creating new record")
            try await adminController.supabase
                .from("doctor_availability_efficient")
                .insert(dataToSave)
                .execute()
        }
        
        print("✅ Schedule successfully saved to database!")
    }
    
    private func handleSaveChanges() {
        isLoading = true
        
        Task {
            do {
                // First update the doctor's basic information
                let updatedDoctor = try await saveBasicDoctorInfo()
                
                // Then update the availability schedule
                try await updateDoctorAvailability()
                
                await MainActor.run {
                    isLoading = false
                    onUpdate(updatedDoctor)
                    alertMessage = "Doctor information updated successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func saveBasicDoctorInfo() async throws -> UIDoctor {
        // Create an updated doctor object
        let updatedDoctor = UIDoctor(
            id: doctor.id,
            fullName: fullName,
            email: email,
            phone: "+91\(phoneNumber)",
            specialization: specialization.rawValue,
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            license: license,
            address: address
        )
        
        // Call the admin controller to update the doctor
        try await adminController.updateDoctor(doctor: updatedDoctor)
        
        return updatedDoctor
    }
}

// Add these properties at the top of the struct
struct TimeSlotCategory {
    let title: String
    let slots: [String]
}

private let weekdayCategories = [
    TimeSlotCategory(title: "Morning Slots", slots: [
        "06:00-07:00", "07:00-08:00", "08:00-09:00",
        "09:00-10:00", "10:00-11:00", "11:00-12:00"
    ]),
    TimeSlotCategory(title: "Afternoon", slots: [
        "12:00-13:00", "13:00-14:00", "14:00-15:00", "15:00-16:00",
        "16:00-17:00", "17:00-18:00"
    ]),
    TimeSlotCategory(title: "Evening", slots: [
        "18:00-19:00", "19:00-20:00", "20:00-21:00", "21:00-22:00"
    ]),
    TimeSlotCategory(title: "Night", slots: [
        "22:00-23:00", "23:00-00:00", "00:00-01:00", "01:00-02:00",
        "02:00-03:00", "03:00-04:00", "04:00-05:00", "05:00-06:00"
    ])
]

// Helper function to convert 24-hour format to 12-hour format with AM/PM
private func formatTimeFor12Hour(_ time24: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    
    if let date = formatter.date(from: time24) {
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    return time24
}

// Helper function to convert time slot to 12-hour format
private func formatTimeSlotFor12Hour(_ slot: String) -> String {
    let components = slot.split(separator: "-")
    if components.count == 2 {
        let startTime = formatTimeFor12Hour(String(components[0]))
        let endTime = formatTimeFor12Hour(String(components[1]))
        return "\(startTime) - \(endTime)"
    }
    return slot
}

// Update the TimeSlotButton view for improved appearance
struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                
                Text(formatDisplayTime(time))
                    .font(.system(size: 14))
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(minWidth: 100, height: 36)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Convert to user-friendly display format
    private func formatDisplayTime(_ slot: String) -> String {
        let components = slot.split(separator: "-")
        if components.count == 2 {
            let start = String(components[0]).trimmingCharacters(in: .whitespaces)
            let end = String(components[1]).trimmingCharacters(in: .whitespaces)
            
            return "\(formatTimeComponent(start)) - \(formatTimeComponent(end))"
        }
        return slot
    }
    
    private func formatTimeComponent(_ time: String) -> String {
        // Convert to 12-hour format
        let timeParts = time.split(separator: ":")
        if timeParts.count == 2, let hour = Int(timeParts[0]) {
            let minute = timeParts[1]
            let ampm = hour >= 12 ? "PM" : "AM"
            let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return "\(hour12):\(minute) \(ampm)"
        }
        return time
    }
}

// Add a modern time slot section for better organization
struct TimeSlotSection: View {
    let title: String
    let slots: [String]
    let selectedSlots: Set<String>
    let onToggle: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 8)
            ], spacing: 8) {
                ForEach(slots, id: \.self) { slot in
                    TimeSlotButton(
                        time: slot,
                        isSelected: isSlotSelected(slot, in: selectedSlots)
                    ) {
                        onToggle(slot)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func isSlotSelected(_ slot: String, in slots: Set<String>) -> Bool {
        // Check if normalized version of this slot exists in the set
        let normalizedSlot = normalizeSlotFormat(slot)
        
        for selectedSlot in slots {
            if selectedSlot == normalizedSlot {
                return true
            }
            
            // Compare parts
            let slotParts = normalizedSlot.split(separator: "-")
            let selectedParts = selectedSlot.split(separator: "-")
            
            if slotParts.count == 2 && selectedParts.count == 2 {
                if slotParts[0].trimmingCharacters(in: .whitespaces) == selectedParts[0].trimmingCharacters(in: .whitespaces) &&
                   slotParts[1].trimmingCharacters(in: .whitespaces) == selectedParts[1].trimmingCharacters(in: .whitespaces) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper function to normalize slot format
    private func normalizeSlotFormat(_ slot: String) -> String {
        let components = slot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        if components.count == 2 {
            var start = components[0]
            var end = components[1]
            
            // Add colon if missing
            if !start.contains(":") {
                start = "\(start):00"
            }
            if !end.contains(":") {
                end = "\(end):00"
            }
            
            // Ensure leading zeros for hours
            let startParts = start.split(separator: ":")
            let endParts = end.split(separator: ":")
            
            if startParts.count == 2 {
                let hour = Int(startParts[0]) ?? 0
                let minute = startParts[1]
                start = String(format: "%02d:%@", hour, minute)
            }
            
            if endParts.count == 2 {
                let hour = Int(endParts[0]) ?? 0
                let minute = endParts[1]
                end = String(format: "%02d:%@", hour, minute)
            }
            
            return "\(start)-\(end)"
        }
        return slot
    }
}