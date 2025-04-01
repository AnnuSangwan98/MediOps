import SwiftUI

// Specialization Enum
enum Specialization: String, CaseIterable, Identifiable {
    case generalMedicine = "General Medicine"
    case cardiology = "Cardiology"
    case neurology = "Neurology"
    case pediatrics = "Pediatrics"
    case orthopedics = "Orthopedics"
    case dermatology = "Dermatology"
    case ophthalmology = "Ophthalmology"
    
    var id: String { self.rawValue }
}

// Validation Functions
extension AddDoctorView {
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    func isValidPincode(_ pincode: String) -> Bool {
        let pincodeRegex = #"^\d{6}$"#
        return NSPredicate(format: "SELF MATCHES %@", pincodeRegex).evaluate(with: pincode)
    }
}

// Time Slot Category
struct TimeSlotCategory {
    let title: String
    let slots: [String]
}

private let timeSlots = [
    "6:00 AM - 7:00 AM",
    "7:00 AM - 8:00 AM",
    "8:00 AM - 9:00 AM",
    "9:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM",
    "12:00 PM - 1:00 PM",
    "1:00 PM - 2:00 PM",
    "2:00 PM - 3:00 PM",
    "3:00 PM - 4:00 PM",
    "4:00 PM - 5:00 PM",
    "5:00 PM - 6:00 PM",
    "6:00 PM - 7:00 PM",
    "7:00 PM - 8:00 PM",
    "8:00 PM - 9:00 PM",
    "9:00 PM - 10:00 PM",
    "10:00 PM - 11:00 PM",
    "11:00 PM - 12:00 AM",
    "12:00 AM - 1:00 AM",
    "1:00 AM - 2:00 AM",
    "2:00 AM - 3:00 AM",
    "3:00 AM - 4:00 AM",
    "4:00 AM - 5:00 AM",
    "5:00 AM - 6:00 AM"
]

// Helper function to convert 12-hour format to 24-hour format
private func convertTo24Hour(_ time12: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    
    if let date = formatter.date(from: time12) {
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    return time12
}

// Helper function to normalize time slot for database storage
private func normalizeTimeSlot(_ slot: String) -> String {
    return normalizeSlotFormat(slot)
}

// Update the toggleSlot function
private func toggleSlot(_ time: String, in slots: inout Set<String>) {
    let normalizedTime = normalizeSlotFormat(time)
    
    if slots.contains(normalizedTime) {
        slots.remove(normalizedTime)
        print("🔄 Removed slot: \(normalizedTime)")
    } else {
        slots.insert(normalizedTime)
        print("🔄 Added slot: \(normalizedTime)")
    }
}

// Time Slot Button Component
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

// TimeSlotSection component for better UI organization
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

struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var adminController = AdminController.shared
    
    // Doctor ID fields
    @State private var doctorId: String = ""
    @State private var idError: String? = nil
    
    // Personal Information
    @State private var name: String = ""
    @State private var selectedSpecialization: Specialization = .generalMedicine
    @State private var gender: String = "Male"
    @State private var dateOfBirth = Date()
    
    // Professional Information
    @State private var selectedQualifications: [String] = ["MBBS"]
    @State private var licenseNumber: String = ""
    @State private var experience: String = "0"
    
    // Contact Information
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var contactNumber: String = ""
    @State private var emergencyContactNumber: String = ""
    
    // Address
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var pincode: String = ""
    
    // Schedule
    @State private var selectedWeekdaySlots: Set<String> = []
    @State private var selectedWeekendSlots: Set<String> = []
    
    // UI State
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var hospitalAdminId: String = ""
    
    // Options
    let qualificationOptions = ["MBBS", "MD", "MS", "DNB", "DM", "MCh", "PhD"]
    let genderOptions = ["Male", "Female", "Other"]
    
    private let weekdayCategories = [
        TimeSlotCategory(title: "Morning Slots", slots: [
            "09:00-10:00", "10:00-11:00", "11:00-12:00"
        ]),
        TimeSlotCategory(title: "Afternoon", slots: [
            "12:00-13:00", "13:00-14:00", "14:00-15:00",
            "15:00-16:00", "16:00-17:00"
        ]),
        TimeSlotCategory(title: "Evening", slots: [
            "17:00-18:00", "18:00-19:00", "19:00-20:00",
            "20:00-21:00"
        ])
    ]

    private func createSlotObject(_ slot: String, isBooked: Bool = true) -> [String: Any] {
        let normalizedSlot = normalizeSlotFormat(slot)
        let components = normalizedSlot.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        
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

    private func updateDoctorAvailability() async throws {
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

        print("📅 Final weekly schedule: \(weeklySchedule)")

        // Update the schedule in Supabase
        try await adminController.supabase
            .from("doctor_availability_efficient")
            .upsert([
                "doctor_id": doctorId,
                "hospital_id": hospitalId,
                "weekly_schedule": weeklySchedule,
                "max_normal_patients": 6,
                "max_premium_patients": 2
            ])
            .execute()
    }

    private func getAllPossibleTimeSlots() -> [String] {
        return [
            "09:00-10:00", "10:00-11:00", "11:00-12:00",  // Morning
            "12:00-13:00", "13:00-14:00", "14:00-15:00",  // Early Afternoon
            "15:00-16:00", "16:00-17:00", "17:00-18:00",  // Late Afternoon
            "18:00-19:00", "19:00-20:00", "20:00-21:00"   // Evening
        ]
    }

    private func handleSave() {
        isLoading = true
        Task {
            do {
                // First save the doctor's basic information
                try await saveDoctor()
                
                // Then update the availability schedule
                try await updateDoctorAvailability()
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Doctor added successfully"
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

    var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        contactNumber.count == 10 &&
        !address.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        isValidPincode(pincode) &&
        !licenseNumber.isEmpty &&
        isValidLicense(licenseNumber) &&
        !doctorId.isEmpty &&
        idError == nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Doctor ID Section
                Section(header: Text("Doctor Information")) {
                    HStack {
                        Text("Doctor ID:")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Enter Doctor ID", text: $doctorId)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: doctorId) { _, newValue in
                                // Remove any spaces
                                let trimmedValue = newValue.trimmingCharacters(in: .whitespaces)
                                
                                // If empty, just clear the error
                                if trimmedValue.isEmpty {
                                    idError = nil
                                    return
                                }
                                
                                // Validate the format
                                if trimmedValue.count < 4 {
                                    idError = "Doctor ID must be at least 4 characters"
                                } else {
                                    idError = nil
                                }
                            }
                    }
                    
                    if let error = idError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Text("Enter a unique doctor ID (e.g. DOC001)")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                // Personal Information Section
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    
                    Picker("Specialization", selection: $selectedSpecialization) {
                        ForEach(Specialization.allCases) { specialization in
                            Text(specialization.rawValue).tag(specialization)
                        }
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                }
                
                // Professional Information Section
                Section(header: Text("Professional Information")) {
                    VStack(alignment: .leading) {
                        Text("Qualifications")
                            .padding(.vertical, 4)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(qualificationOptions, id: \.self) { qualification in
                                    Button(action: {
                                        if selectedQualifications.contains(qualification) {
                                            selectedQualifications.removeAll(where: { $0 == qualification })
                                        } else {
                                            selectedQualifications.append(qualification)
                                        }
                                    }) {
                                        Text(qualification)
                                            .font(.system(size: 14))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedQualifications.contains(qualification)
                                                ? Color.blue
                                                : Color.gray.opacity(0.2)
                                            )
                                            .foregroundColor(
                                                selectedQualifications.contains(qualification)
                                                ? .white
                                                : .primary
                                            )
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    
                    TextField("License Number (Format: AB12345)", text: $licenseNumber)
                    
                    HStack {
                        Text("Experience: \(experience) years")
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                let currentExp = Int(experience) ?? 0
                                if currentExp > 0 {
                                    experience = "\(currentExp - 1)"
                                }
                            }) {
                                Image(systemName: "minus")
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                let currentExp = Int(experience) ?? 0
                                experience = "\(currentExp + 1)"
                            }) {
                                Image(systemName: "plus")
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                // Contact Information
                Section(header: Text("Contact Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                    
                    TextField("Contact Number", text: $contactNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("Emergency Contact (Optional)", text: $emergencyContactNumber)
                        .keyboardType(.phonePad)
                }
                
                // Address
                Section(header: Text("Address")) {
                    TextField("Address Line", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Pincode", text: $pincode)
                        .keyboardType(.numberPad)
                }
                
                // Availability Schedule
                Section(header: Text("AVAILABILITY SCHEDULE")) {
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
                        }
                        
                        if selectedWeekdaySlots.isEmpty && selectedWeekendSlots.isEmpty {
                            Text("Please select at least one time slot")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 4)
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
                        handleSave()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Set the hospital admin ID here - you might get this from UserDefaults or another source
                Task {
                    do {
                        let user = try await adminController.userController.getCurrentUser()
                        let admin = try await adminController.getHospitalAdminByUserId(userId: user.id)
                        hospitalAdminId = admin.id
                    } catch {
                        print("Error fetching hospital admin: \(error)")
                    }
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.4)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            )
        }
    }

    private func submitDoctor() async {
        isLoading = true
        
        do {
            // Validate doctor ID format
            guard !doctorId.isEmpty && doctorId.count >= 4 else {
                idError = "Doctor ID must be at least 4 characters"
                isLoading = false
                return
            }
            
            // Check if ID already exists in Supabase
            let existingDoctors = try await adminController.supabase.from("doctors")
                .select("id")
                .eq("id", value: doctorId)
                .execute()
                .data
            
            if !existingDoctors.isEmpty {
                idError = "This Doctor ID is already in use. Please try another one."
                isLoading = false
                return
            }

            // Get hospital ID from UserDefaults
            guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                alertMessage = "Failed to create doctor: Hospital ID not found. Please login again."
                showAlert = true
                isLoading = false
                return
            }
            
            // Create the doctor with the manually entered ID
            let (doctor, _) = try await adminController.createDoctor(
                email: email,
                password: password,
                name: name,
                specialization: selectedSpecialization,
                hospitalId: hospitalId,
                qualifications: Array(selectedQualifications),
                licenseNo: licenseNumber,
                experience: Int(experience) ?? 0,
                addressLine: address,
                state: state,
                city: city,
                pincode: pincode,
                contactNumber: contactNumber,
                customDoctorId: doctorId
            )
            
            alertMessage = "Doctor added successfully with ID: \(doctor.id)"
            showAlert = true
            isLoading = false
            
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
            showAlert = true
            isLoading = false
        }
    }

    private func saveDoctor() async throws {
        // Implement the logic to save the doctor's basic information to Supabase
        try await submitDoctor()
    }
}

struct AddDoctorView_Previews: PreviewProvider {
    static var previews: some View {
        AddDoctorView()
    }
} 