import SwiftUI
import Foundation

struct BookAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @AppStorage("current_user_id") private var userId: String?
    
    @State private var selectedDoctor: HospitalDoctor? = nil
    @State private var selectedHospital: HospitalModel? = nil
    @State private var selectedDate = Date()
    @State private var selectedSlot: DoctorAvailabilityModels.AppointmentSlot?
    @State private var reason: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var doctorAvailability: DoctorAvailabilityModels.EfficientAvailability?
    
    // Minimum date is today
    private let minDate = Date()
    // Maximum date is 3 months from today
    private let maxDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appointment Details")) {
                    // Hospital Selection
                    if hospitalVM.hospitals.isEmpty {
                        HStack {
                            Text("Loading hospitals...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Picker("Select Hospital", selection: $selectedHospital) {
                            Text("Select a Hospital").tag(nil as HospitalModel?)
                            ForEach(hospitalVM.hospitals) { hospital in
                                Text(hospital.hospitalName).tag(hospital as HospitalModel?)
                            }
                        }
                        .onChange(of: selectedHospital) { newHospital in
                            selectedDoctor = nil
                            doctorAvailability = nil
                            selectedSlot = nil
                            hospitalVM.availableSlots = []
                            if newHospital != nil {
                                hospitalVM.selectedHospital = newHospital
                                Task {
                                    await hospitalVM.fetchDoctors()
                                }
                            }
                        }
                    }
                    
                    // Doctor Selection
                    if let selectedHospital = selectedHospital {
                        if hospitalVM.isLoading {
                            HStack {
                                Text("Loading doctors...")
                                Spacer()
                                ProgressView()
                            }
                        } else if hospitalVM.doctors.isEmpty {
                            Text("No doctors available at this hospital")
                        } else {
                            Picker("Select Doctor", selection: $selectedDoctor) {
                                Text("Select a Doctor").tag(nil as HospitalDoctor?)
                                ForEach(hospitalVM.doctors) { doctor in
                                    Text(doctor.name).tag(doctor as HospitalDoctor?)
                                }
                            }
                            .onChange(of: selectedDoctor) { newDoctor in
                                selectedSlot = nil
                                doctorAvailability = nil
                                hospitalVM.availableSlots = []
                                if newDoctor != nil {
                                    hospitalVM.selectedDoctor = newDoctor
                                    Task {
                                        await fetchDoctorAvailability()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Date Selection
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: minDate...maxDate,
                        displayedComponents: [.date]
                    )
                    .onChange(of: selectedDate) { newDate in
                        selectedSlot = nil
                        if selectedDoctor != nil && doctorAvailability != nil {
                            Task {
                                await fetchAvailableSlots(for: newDate)
                            }
                        }
                    }
                    
                    // Available Time Slots
                    timeSlotSection
                    
                    // Reason
                    TextField("Reason for Visit", text: $reason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Book") {
                        Task {
                            await bookAppointment()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .task {
                if hospitalVM.hospitals.isEmpty {
                    await hospitalVM.fetchHospitals()
                }
                
                // Ensure any lingering state is cleared
                selectedDoctor = nil
                doctorAvailability = nil
                selectedSlot = nil
                hospitalVM.availableSlots = []
            }
            .onDisappear {
                // Clean up when view disappears
                hospitalVM.availableSlots = []
                doctorAvailability = nil
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedDoctor != nil &&
        selectedHospital != nil &&
        selectedSlot != nil &&
        !reason.isEmpty
    }
    
    private func fetchDoctorAvailability() async {
        guard let doctor = selectedDoctor else { return }
        
        print("==========================================================")
        print("🔍 START FETCHING AVAILABILITY FOR DOCTOR: \(doctor.name) (ID: \(doctor.id))")
        print("==========================================================")
        
        do {
            let supabase = SupabaseController.shared
            print("⏳ Querying doctor_availability_efficient table for doctor_id: \(doctor.id)")
            
            // Reset availability data when doctor changes
            await MainActor.run {
                self.doctorAvailability = nil
                self.hospitalVM.availableSlots = []
            }
            
            let results = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctor.id
            )
            
            print("📊 Query results count for doctor \(doctor.name): \(results.count)")
            
            guard let availabilityData = results.first else {
                print("❌ No availability found for doctor \(doctor.name) (ID: \(doctor.id))")
                
                // Display a message to the user about missing availability data
                await MainActor.run {
                    alertMessage = "This doctor doesn't have any availability schedule set up yet. Please select another doctor or contact the hospital."
                    showAlert = true
                    hospitalVM.isLoading = false
                }
                return
            }
            
            // Print the raw data we got for debugging
            print("📅 Raw availability data for doctor \(doctor.name): \(availabilityData)")
            
            // Get the day of week for the selected date
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: selectedDate)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1]
            print("📅 Selected day for initial fetch: \(dayName)")
            
            // Parse the availability data
            let availability = try parseDoctorAvailability(availabilityData)
            await MainActor.run {
                self.doctorAvailability = availability
            }
            
            // Debug: Check for specific days in the schedule
            let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            print("🗓️ WEEKLY SCHEDULE SUMMARY FOR DOCTOR: \(doctor.name)")
            for day in days {
                if let daySchedule = availability.weeklySchedule[day] {
                    let availableSlots = daySchedule.filter { $0.value == true }
                    print("📆 \(day.capitalized) schedule: \(daySchedule.count) time slots, \(availableSlots.count) available")
                    // Print sample slots
                    if !availableSlots.isEmpty {
                        let sampleSlots = availableSlots.keys.prefix(3)
                        print("   Sample available slots: \(Array(sampleSlots))")
                    } else {
                        print("   No available slots for \(day)")
                    }
                } else {
                    print("❌ No schedule found for \(day)")
                }
            }
            
            // Fetch available slots for the selected date
            await fetchAvailableSlots(for: selectedDate)
            
        } catch {
            print("❌ Error fetching doctor availability: \(error)")
            await MainActor.run {
                alertMessage = "Failed to load doctor's availability: \(error.localizedDescription)"
                showAlert = true
                hospitalVM.isLoading = false
            }
        }
        
        print("==========================================================")
        print("🔍 END FETCHING AVAILABILITY FOR DOCTOR: \(doctor.name)")
        print("==========================================================")
    }
    
    private func parseDoctorAvailability(_ data: [String: Any]) throws -> DoctorAvailabilityModels.EfficientAvailability {
        // Debug print for availability data
        print("📅 Parsing doctor availability data: \(data)")
        
        // First check if weekly_schedule exists but might be in a different format than expected
        if let weeklyScheduleRaw = data["weekly_schedule"] {
            print("📅 Weekly schedule data type: \(type(of: weeklyScheduleRaw))")
            
            // If it's a string (JSON string), try to parse it
            if let weeklyScheduleString = weeklyScheduleRaw as? String {
                print("📝 Weekly schedule is stored as a JSON string, attempting to parse")
                if let data = weeklyScheduleString.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                   let parsedSchedule = jsonObject as? [String: [String: Bool]] {
                    print("✅ Successfully parsed JSON string to dictionary")
                    // Continue with the parsed schedule
                    // Note: We'll let the original guard statement handle the rest of the validation
                }
            }
        }
        
        guard let id = data["id"] as? Int,
              let doctorId = data["doctor_id"] as? String,
              let hospitalId = data["hospital_id"] as? String,
              let weeklySchedule = data["weekly_schedule"] as? [String: [String: Bool]],
              let effectiveFromStr = data["effective_from"] as? String else {
            // Print what's missing from the data
            print("❌ Invalid availability data: id=\(data["id"] ?? "missing"), doctorId=\(data["doctor_id"] ?? "missing"), hospitalId=\(data["hospital_id"] ?? "missing"), weeklySchedule type=\(type(of: data["weekly_schedule"] ?? "missing")), effectiveFrom=\(data["effective_from"] ?? "missing")")
            
            // Detailed check of weekly_schedule if it exists but has wrong format
            if let wrongFormat = data["weekly_schedule"] {
                print("🛑 weekly_schedule exists but has unexpected format: \(type(of: wrongFormat))")
                print("🛑 Value: \(wrongFormat)")
                
                // Try to cast to common types to understand what we're dealing with
                if let asDict = wrongFormat as? [String: Any] {
                    print("🔍 It's a dictionary with keys: \(asDict.keys)")
                    // Check the first value to understand structure
                    if let firstValue = asDict.values.first {
                        print("🔍 First value type: \(type(of: firstValue))")
                    }
                } else if let asArray = wrongFormat as? [Any] {
                    print("🔍 It's an array with \(asArray.count) items")
                } else if let asString = wrongFormat as? String {
                    print("🔍 It's a string: \(asString)")
                }
            }
            
            throw NSError(domain: "AvailabilityError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid availability data format. Please check the database."])
        }
        
        // Debug print for weekly schedule
        print("📅 Weekly schedule data: \(weeklySchedule)")
        // Check if any days have available slots
        let availableDays = weeklySchedule.filter { !$0.value.isEmpty }
        if availableDays.isEmpty {
            print("⚠️ No days have any time slots defined in weekly schedule")
        } else {
            print("✅ Found available slots for days: \(availableDays.keys.joined(separator: ", "))")
        }
        
        // Format validation check for the slots
        for (day, slots) in weeklySchedule {
            for (timeRange, isAvailable) in slots {
                let components = timeRange.split(separator: "-")
                if components.count != 2 {
                    print("⚠️ Invalid time range format for \(day): \(timeRange)")
                }
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let effectiveFrom = dateFormatter.date(from: effectiveFromStr) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
        }
        
        var effectiveUntil: Date? = nil
        if let untilStr = data["effective_until"] as? String {
            effectiveUntil = dateFormatter.date(from: untilStr)
        }
        
        var createdAt: Date? = nil
        if let createdAtStr = data["created_at"] as? String {
            createdAt = dateFormatter.date(from: createdAtStr)
        }
        
        var updatedAt: Date? = nil
        if let updatedAtStr = data["updated_at"] as? String {
            updatedAt = dateFormatter.date(from: updatedAtStr)
        }
        
        return DoctorAvailabilityModels.EfficientAvailability(
            id: id,
            doctorId: doctorId,
            hospitalId: hospitalId,
            weeklySchedule: weeklySchedule,
            effectiveFrom: effectiveFrom,
            effectiveUntil: effectiveUntil,
            maxNormalPatients: data["max_normal_patients"] as? Int ?? 5,
            maxPremiumPatients: data["max_premium_patients"] as? Int ?? 2,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func fetchAvailableSlots(for date: Date) async {
        guard let availability = doctorAvailability,
              let doctor = selectedDoctor else { return }
        
        print("==========================================================")
        print("🔄 START FETCHING SLOTS FOR DOCTOR: \(doctor.name) (ID: \(doctor.id))")
        print("🗓️ Date selected: \(date.formatted(date: .long, time: .omitted))")
        print("==========================================================")
        
        await MainActor.run {
            hospitalVM.isLoading = true
            hospitalVM.availableSlots = []
        }
        
        do {
            // Get the day of week
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1]
            
            print("🗓️ Selected day: \(dayName) for doctor \(doctor.name)")
            
            // Get available slots for the day
            guard let daySlots = availability.weeklySchedule[dayName] else {
                print("❌ No schedule defined for \(dayName) in weekly schedule for doctor \(doctor.name)")
                await MainActor.run {
                    hospitalVM.isLoading = false
                }
                return
            }
            
            print("🔍 RAW day slots data for doctor \(doctor.name) on \(dayName):")
            for (slot, isAvailable) in daySlots {
                print("   \(slot): \(isAvailable ? "Available" : "Not available")")
            }
            
            // Count how many slots are available vs unavailable
            let availableCount = daySlots.filter { $0.value == true }.count
            let unavailableCount = daySlots.filter { $0.value == false }.count
            print("📊 Day slots summary for \(doctor.name): \(availableCount) available, \(unavailableCount) unavailable")
            
            // Get existing appointments for the date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            print("📅 Fetching existing appointments for date: \(dateString)")
            let supabase = SupabaseController.shared
            let existingAppointments = try await supabase.select(
                from: "appointments",
                where: "doctor_id",
                equals: doctor.id
            ).filter { appointment in
                guard let appointmentDate = appointment["appointment_date"] as? String,
                      let status = appointment["status"] as? String else { return false }
                return appointmentDate == dateString && status == "upcoming"
            }
            
            print("📊 Found \(existingAppointments.count) existing appointments for doctor \(doctor.name) on this day")
            
            // Count appointments per slot time
            var slotCounts: [String: Int] = [:]
            for appointment in existingAppointments {
                if let startTime = appointment["slot_start_time"] as? String {
                    slotCounts[startTime, default: 0] += 1
                    print("  - Slot \(startTime) has \(slotCounts[startTime]!) bookings")
                }
            }
            
            // Convert slots to AppointmentSlot objects
            var availableSlots: [DoctorAvailabilityModels.AppointmentSlot] = []
            
            // CRITICAL FIX: Only process slots that are marked as available (true) in the weekly schedule
            for (timeRange, isAvailable) in daySlots {
                print("⏰ Processing time range: \(timeRange), available: \(isAvailable)")
                
                // Skip slots that are not available in doctor's schedule
                if !isAvailable {
                    print("⏭️ Skipping unavailable slot: \(timeRange) for doctor \(doctor.name)")
                    continue
                }
                
                let components = timeRange.split(separator: "-")
                guard components.count == 2 else { 
                    print("⚠️ Invalid time range format: \(timeRange)")
                    continue 
                }
                
                let startTime = String(components[0])
                let endTime = String(components[1])
                
                // Calculate max and remaining slots
                let maxSlots = availability.maxNormalPatients + availability.maxPremiumPatients
                let bookedSlots = slotCounts[startTime] ?? 0
                let remainingSlots = maxSlots - bookedSlots
                
                // Only include slot if there are available slots remaining
                if remainingSlots > 0 {
                    // Generate a deterministic integer ID based on the components
                    let timeComponents = startTime.split(separator: ":").map { String($0) }
                    let hour = Int(timeComponents[0]) ?? 0
                    let minute = Int(timeComponents[1]) ?? 0
                    let dayComponent = Calendar.current.component(.day, from: date)
                    let monthComponent = Calendar.current.component(.month, from: date)
                    
                    // Create a unique integer ID combining date and time components
                    let slotId = (dayComponent * 10000) + (monthComponent * 100) + hour
                    
                    // Format times for display
                    let formattedStartTime = DoctorAvailabilityModels.AppointmentSlot.formatTimeForDisplay(startTime)
                    let formattedEndTime = DoctorAvailabilityModels.AppointmentSlot.formatTimeForDisplay(endTime)
                    
                    print("✅ Adding available slot for doctor \(doctor.name): \(formattedStartTime) - \(formattedEndTime)")
                    
                    let slot = DoctorAvailabilityModels.AppointmentSlot(
                        id: slotId,
                        doctorId: doctor.id,
                        date: date,
                        startTime: formattedStartTime,
                        endTime: formattedEndTime,
                        rawStartTime: startTime,
                        rawEndTime: endTime,
                        isAvailable: true,
                        remainingSlots: remainingSlots,
                        totalSlots: maxSlots
                    )
                    availableSlots.append(slot)
                } else {
                    print("⏭️ Skipping fully booked slot: \(startTime) - \(endTime) for doctor \(doctor.name)")
                }
            }
            
            // Sort slots by start time
            availableSlots.sort { slot1, slot2 in
                return slot1.startTime < slot2.startTime
            }
            
            // After processing all slots
            print("📋 FINAL AVAILABLE SLOTS FOR DOCTOR \(doctor.name): \(availableSlots.count)")
            for (index, slot) in availableSlots.enumerated() {
                print("  \(index+1). \(slot.startTime) - \(slot.endTime) (\(slot.remainingSlots)/\(slot.totalSlots) slots)")
            }
            
            // ADDED: Check if slots might be hardcoded elsewhere
            await MainActor.run {
                print("⚠️ Before updating hospitalVM.availableSlots: \(hospitalVM.availableSlots.count) slots")
                hospitalVM.availableSlots = availableSlots
                print("✅ After updating hospitalVM.availableSlots: \(hospitalVM.availableSlots.count) slots for doctor \(doctor.name)")
                hospitalVM.isLoading = false
            }
            
        } catch {
            print("❌ Error fetching available slots: \(error)")
            await MainActor.run {
                hospitalVM.isLoading = false
                alertMessage = "Failed to load available slots: \(error.localizedDescription)"
                showAlert = true
            }
        }
        
        print("==========================================================")
        print("🔄 END FETCHING SLOTS FOR DOCTOR: \(doctor.name)")
        print("==========================================================")
    }
    
    private func refreshAvailabilityAfterBooking() async {
        // Refresh the available slots to update the counts
        if let doctor = selectedDoctor {
            hospitalVM.selectedDoctor = doctor
            await hospitalVM.fetchAvailableSlots(for: selectedDate)
        }
    }
    
    private func bookAppointment() async {
        print("📝 Starting appointment booking process")
        
        // Verify user ID
        guard let userId = userId else {
            print("❌ No user ID found when booking appointment")
            alertMessage = "User ID not found. Please log in again."
            showAlert = true
            return
        }
        
        print("👤 Using user ID: \(userId)")
        
        guard let doctor = selectedDoctor,
              let hospital = selectedHospital,
              let slot = selectedSlot else {
            print("❌ Missing required selection (doctor, hospital, or slot)")
            alertMessage = "Please select all required fields"
            showAlert = true
            return
        }
        
        isLoading = true
        
        do {
            // Use SupabaseController directly
            
            // Ensure patient has patient_id field - this is a critical step
            print("🔍 Ensuring patient record has patient_id field")
            guard var patientId = await SupabaseController.shared.ensurePatientHasPatientId(userId: userId) else {
                isLoading = false
                print("❌ Failed to ensure patient has patient_id field")
                alertMessage = "Could not locate or update your patient record. Please contact support."
                showAlert = true
                return
            }
            
            print("✅ Using patient ID: \(patientId) for user ID: \(userId)")
            print("📋 Booking details:")
            print("- Patient ID: \(patientId)")
            print("- Doctor: \(doctor.name) (ID: \(doctor.id))")
            print("- Hospital: \(hospital.hospitalName) (ID: \(hospital.id))")
            print("- Date: \(selectedDate.formatted(date: .long, time: .omitted))")
            print("- Slot ID: \(slot.id) (\(slot.startTime) - \(slot.endTime))")
            print("- Reason: \(reason)")
            
            // Generate appointment ID in the format APPT[0-9]{3}[A-Z]
            let randomNum = String(format: "%03d", Int.random(in: 0...999))
            let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
            let appointmentId = "APPT\(randomNum)\(randomLetter)"
            
            // Format date for database
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // First, directly verify the patient record exists in the database
            print("🔍 Double-checking patient exists in database")
            let patientRecords = try await SupabaseController.shared.select(
                from: "patients",
                where: "id",
                equals: patientId
            )
            
            if patientRecords.isEmpty {
                print("⚠️ Patient ID not found as primary key - attempting to create it")
                
                // First check if there's a patient record with this user_id
                let userPatientRecords = try await SupabaseController.shared.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                if let existingPatient = userPatientRecords.first, 
                   let existingRecordId = existingPatient["id"] as? String,
                   let existingPatientId = existingPatient["patient_id"] as? String {
                    print("✅ Found existing patient with user_id \(userId), using id: \(existingRecordId) and patient_id: \(existingPatientId)")
                    // Use the existing patient ID instead
                    patientId = existingPatientId
                } else {
                    // Create a completely new patient record
                    print("🔄 Creating new patient record with id=\(patientId) and user_id=\(userId)")
                    
                    // Generate a patient_id in the format PAT[0-9]{3}
                    let randomNum = String(format: "%03d", Int.random(in: 0...999))
                    let patientIdValue = "PAT\(randomNum)"
                    
                    // Create the patient record with proper fields
                    let patientData: [String: Any] = [
                        "id": patientId,
                        "patient_id": patientIdValue, // Set the patient_id field
                        "user_id": userId,
                        "name": "Patient",
                        "gender": "Not specified",
                        "bloodGroup": "Not specified",
                        "age": 0,
                        "phoneNumber": "",
                        "emergencyContactNumber": "",
                        "emergencyRelationship": ""
                    ]
                    
                    try await SupabaseController.shared.insert(into: "patients", values: patientData)
                    print("✅ Created patient record with ID: \(patientId) and patient_id: \(patientIdValue)")
                    
                    // Update the patientId to use the newly created patient_id value
                    patientId = patientIdValue
                    
                    // Verify the patient was created successfully
                    let verifyPatient = try await SupabaseController.shared.select(
                        from: "patients",
                        where: "id",
                        equals: patientId
                    )
                    
                    if verifyPatient.isEmpty {
                        throw NSError(
                            domain: "AppointmentError",
                            code: 1002,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create patient record. Please try again."]
                        )
                    }
                }
            } else {
                print("✅ Patient record exists with ID: \(patientId)")
            }
            
            // Attempt to book the appointment
            do {
                print("🔄 Attempting to book appointment with patient_id: \(patientId)")
                try await SupabaseController.shared.insertAppointment(
                    id: appointmentId,
                    patientId: patientId,
                    doctorId: doctor.id,
                    hospitalId: hospital.id,
                    slotId: slot.id,
                    date: selectedDate,
                    reason: reason
                )
                
                print("✅ Successfully saved appointment to Supabase")
            } catch let appointmentError {
                print("⚠️ First attempt failed: \(appointmentError.localizedDescription)")
                
                // Check if it's a foreign key error and attempt a fix
                if appointmentError.localizedDescription.contains("foreign key constraint") {
                    print("🔍 Foreign key constraint error detected - attempting to diagnose and fix")
                    
                    // Debug: Check if the patient exists in the table directly
                    let checkPatientSql = "SELECT id, patient_id, user_id FROM patients WHERE id = '\(patientId)' OR patient_id = '\(patientId)'"
                    
                    do {
                        let result = try await SupabaseController.shared.executeSQL(sql: checkPatientSql)
                        print("🔍 Patient lookup result: \(result)")
                        
                        if !result.isEmpty, let record = result.first {
                            // Determine which ID to use
                            if let patientIdField = record["patient_id"] as? String {
                                print("✅ Found patient_id field: \(patientIdField), using this for appointment")
                                patientId = patientIdField
                            }
                        }
                        
                        // If we got here but still have issues, try updating the record to ensure patient_id is set
                        let updateSql = """
                        UPDATE patients SET patient_id = '\(patientId)' WHERE id = '\(patientId)' AND (patient_id IS NULL OR patient_id = '')
                        """
                        let updateResult = try await SupabaseController.shared.executeSQL(sql: updateSql)
                        print("🔄 Patient record update result: \(updateResult)")
                    } catch {
                        print("⚠️ Error checking patient record: \(error.localizedDescription)")
                    }
                }
                
                print("🔄 Trying alternative approach with direct insert")
                
                // Try direct insert into appointments table
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId,  // This is now the patient_id field from the patients table
                    "doctor_id": doctor.id,
                    "hospital_id": hospital.id,
                    "availability_slot_id": slot.id,
                    "appointment_date": dateFormatter.string(from: selectedDate),
                    "status": "upcoming",
                    "reason": reason.isEmpty ? "Medical consultation" : reason,
                    "isdone": false,
                    "is_premium": false,
                    "slot_start_time": slot.startTime,
                    "slot_end_time": slot.endTime,
                    "slot": [
                        "start_time": slot.startTime,
                        "end_time": slot.endTime, 
                        "remaining_slots": slot.remainingSlots - 1, // Subtract one for the slot being booked
                        "total_slots": slot.totalSlots
                    ]
                ]
                
                print("📊 Direct insert appointment data:")
                print("- ID: \(appointmentId)")
                print("- Patient ID: \(patientId) (using patient_id from patients table)")
                print("- Doctor ID: \(doctor.id)")
                
                try await SupabaseController.shared.insert(into: "appointments", values: appointmentData)
                print("✅ Successfully saved appointment using direct insert")
            }
            
            // Create local appointment object for immediate UI update
            let appointmentTime = Calendar.current.date(from: DateComponents(
                hour: Int(slot.startTime.components(separatedBy: ":").first ?? "9"),
                minute: 0
            )) ?? Date()
            
            let appointment = Appointment(
                id: appointmentId,
                doctor: doctor.toModelDoctor(),
                date: selectedDate,
                time: appointmentTime,
                status: .upcoming,
                startTime: slot.startTime,
                endTime: slot.endTime
            )
            
            // Add to local state
            appointmentManager.addAppointment(appointment)

            // Refresh appointments from database to ensure consistency
            try await hospitalVM.fetchAppointments(for: patientId)

            // Refresh availability slots to update counts
            await refreshAvailabilityAfterBooking()

            // Display success message
            isLoading = false
            alertMessage = "Appointment booked successfully for \(selectedDate.formatted(date: .long, time: .omitted))!"
            showAlert = true
        } catch {
            isLoading = false
            print("❌ Error booking appointment: \(error.localizedDescription)")
            
            if let nsError = error as? NSError {
                // Give more helpful error messages based on error details
                if nsError.domain == "AppointmentError" {
                    alertMessage = "Failed to book appointment: \(nsError.localizedDescription)"
                } else if nsError.localizedDescription.contains("foreign key constraint") {
                    alertMessage = "Cannot book appointment: Your patient record wasn't found. Please try updating your profile first."
                } else if nsError.localizedDescription.contains("network") {
                    alertMessage = "Cannot book appointment: Network error. Please check your internet connection and try again."
                } else {
                    alertMessage = "Failed to book appointment: \(nsError.localizedDescription)"
                }
            } else {
                alertMessage = "Failed to book appointment: \(error.localizedDescription)"
            }
            
            showAlert = true
        }
    }
    
    var timeSlotSection: some View {
        Section {
            if selectedDoctor != nil {
                if hospitalVM.isLoading {
                    HStack {
                        Text("Loading available slots...")
                        Spacer()
                        ProgressView()
                    }
                } else if hospitalVM.availableSlots.isEmpty {
                    Text("No available slots on this date. Please select another date or doctor.")
                        .foregroundColor(.red)
                } else {
                    Section(header: Text("Available Time Slots")) {
                        ForEach(hospitalVM.availableSlots) { slot in
                            Button(action: {
                                selectedSlot = slot
                            }) {
                                HStack {
                                    Text("\(slot.startTime) - \(slot.endTime)")
                                    Spacer()
                                    Text("\(slot.remainingSlots)/\(slot.totalSlots) slots")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if selectedSlot?.id == slot.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.teal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 
