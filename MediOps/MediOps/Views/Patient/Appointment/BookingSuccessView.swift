import SwiftUI

struct BookingSuccessView: View {
    let doctor: HospitalDoctor
    let appointmentDate: Date
    let startTime: String
    let endTime: String
    let rawStartTime: String
    let rawEndTime: String
    let isPremium: Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appointmentManager = AppointmentManager.shared
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var appointmentCreated = false // Track if appointment was created
    @State private var appointmentId = "" // Store the appointment ID to avoid regenerating it
    @AppStorage("current_user_id") private var userId: String?
    @ObservedObject private var translationManager = TranslationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private func formatTime() -> String {
        // Use the saved formatted times directly
        return "\(startTime) to \(endTime)"
    }
    
    private func checkIfAppointmentExists(_ appointmentId: String) async -> Bool {
        do {
            let supabase = SupabaseController.shared
            let results = try await supabase.select(
                from: "appointments",
                where: "id",
                equals: appointmentId
            )
            return !results.isEmpty
        } catch {
            return false
        }
    }
    
    private func diagnoseDatabaseIssues() {
        Task {
            do {
                print("🩺 DIAGNOSTIC: Starting database connection check")
                let supabase = SupabaseController.shared
                
                // Check basic connectivity
                let connected = await supabase.checkConnectivity()
                print("🩺 DIAGNOSTIC: Supabase connection: \(connected ? "SUCCESS" : "FAILED")")
                
                // Check appointments table structure
                print("🩺 DIAGNOSTIC: Checking appointments table structure")
                let schemaSQL = """
                SELECT column_name, data_type, is_nullable 
                FROM information_schema.columns 
                WHERE table_name = 'appointments' 
                ORDER BY ordinal_position;
                """
                
                let schemaResults = try await supabase.executeSQL(sql: schemaSQL)
                print("🩺 DIAGNOSTIC: Appointments table schema: \(schemaResults)")
                
                // Check constraints
                print("🩺 DIAGNOSTIC: Checking appointments table constraints")
                let constraintsSQL = """
                SELECT con.conname AS constraint_name,
                       pg_get_constraintdef(con.oid) AS constraint_definition
                FROM pg_constraint con
                JOIN pg_class rel ON rel.oid = con.conrelid
                JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
                WHERE rel.relname = 'appointments'
                  AND nsp.nspname = 'public';
                """
                
                let constraintResults = try await supabase.executeSQL(sql: constraintsSQL)
                print("🩺 DIAGNOSTIC: Appointments constraints: \(constraintResults)")
                
                // Test inserting a record directly
                print("🩺 DIAGNOSTIC: Testing direct insert with minimal data")
                
                // Generate a test ID
                let testId = "APPT\(String(format: "%03d", Int.random(in: 0...999)))\(String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25)))))"
                
                // Format dates for the test
                let testDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedTestDate = dateFormatter.string(from: testDate)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let testStartTime = timeFormatter.string(from: testDate)
                let testEndTime = timeFormatter.string(from: Date(timeInterval: 3600, since: testDate))
                
                // Get essential data from the doctor object
                let doctorId = doctor.id
                let hospitalId = doctor.hospitalId 
                
                // Get a valid patient ID - critical for foreign key constraint
                guard let userId = userId else {
                    print("🩺 DIAGNOSTIC: No user ID available for test")
                    return
                }
                
                let patientResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patientData = patientResults.first, 
                      let patientRecordId = patientData["id"] as? String,
                      let patientId = patientData["patient_id"] as? String else {
                    print("🩺 DIAGNOSTIC: No patient ID found for current user")
                    return
                }
                
                print("🩺 DIAGNOSTIC: Using patient record ID: \(patientRecordId) and patient_id: \(patientId) for test")
                
                // Test simple insert with minimal data
                let testSQL = """
                INSERT INTO appointments (
                    id, patient_id, doctor_id, hospital_id, appointment_date
                ) VALUES (
                    '\(testId)', '\(patientId)', '\(doctorId)', '\(hospitalId)', '\(formattedTestDate)'::date
                ) RETURNING id;
                """
                
                do {
                    let testResults = try await supabase.executeSQL(sql: testSQL)
                    print("🩺 DIAGNOSTIC: Test insert success! Results: \(testResults)")
                    
                    // Clean up the test record
                    let cleanupSQL = "DELETE FROM appointments WHERE id = '\(testId)';"
                    try await supabase.executeSQL(sql: cleanupSQL)
                    print("🩺 DIAGNOSTIC: Test record cleaned up")
                } catch {
                    print("🩺 DIAGNOSTIC: Test insert failed: \(error.localizedDescription)")
                    
                    // Try with all required fields explicitly set
                    let fullTestSQL = """
                    INSERT INTO appointments (
                        id, patient_id, doctor_id, hospital_id, appointment_date, 
                        status, reason, isdone, is_premium, 
                        slot_start_time, slot_end_time, slot
                    ) VALUES (
                        '\(testId)', '\(patientId)', '\(doctorId)', '\(hospitalId)', '\(formattedTestDate)'::date,
                        'upcoming', 'Test consultation', false, false,
                        '\(testStartTime)'::time, '\(testEndTime)'::time, '{}'::jsonb
                    ) RETURNING id;
                    """
                    
                    do {
                        let fullTestResults = try await supabase.executeSQL(sql: fullTestSQL)
                        print("🩺 DIAGNOSTIC: Full test insert success! Results: \(fullTestResults)")
                        
                        // Clean up the test record
                        let cleanupSQL = "DELETE FROM appointments WHERE id = '\(testId)';"
                        try await supabase.executeSQL(sql: cleanupSQL)
                        print("🩺 DIAGNOSTIC: Test record cleaned up")
                    } catch {
                        print("🩺 DIAGNOSTIC: Full test insert also failed: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("🩺 DIAGNOSTIC: Error during diagnostics: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 40, weight: .bold))
            }
            .padding(.top, 40)
            
            // Success message
            VStack(spacing: 15) {
                Text("booking_confirmed".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.text)
                    .multilineTextAlignment(.center)
                
                Text("email_receipt".localized)
                    .foregroundColor(themeManager.colors.subtext)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Appointment details card
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    // Doctor avatar and info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(themeManager.colors.primary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                            Text(doctor.specialization)
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.subtext)
                        }
                    }
                    
                    // Date and time
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(themeManager.colors.primary)
                        
                        Text(appointmentDate, style: .date)
                            .foregroundColor(themeManager.colors.text)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(themeManager.colors.primary)
                        
                        Text(formatTime())
                            .foregroundColor(themeManager.colors.text)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: themeManager.colors.primary.opacity(0.1), radius: 5)
            
            Spacer()
            
            Button(action: {
                navigateToHome()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                } else {
                    Text("done".localized)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .disabled(isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).ignoresSafeArea())
        .localizedLayout()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: EmptyView())
        .alert(isPresented: $showError) {
            Alert(
                title: Text("error".localized),
                message: Text(errorMessage),
                dismissButton: .default(Text("ok".localized))
            )
        }
        .onAppear {
            print("📋 BookingSuccessView appeared - generating appointment ID")
            // Generate appointment ID on appear if needed
            if appointmentId.isEmpty {
                let randomNum = String(format: "%03d", Int.random(in: 0...999))
                let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
                appointmentId = "APPT\(randomNum)\(randomLetter)"
                print("📋 Generated appointment ID on appear: \(appointmentId)")
            }
            
            // Only run diagnostics in debug builds
            #if DEBUG
            diagnoseDatabaseIssues()
            #endif
        }
    }
    
    // New function to navigate directly to home screen
    private func navigateToHome() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            print("🔄 Navigating to HomeTabView")
            let homeView = HomeTabView()
                .environmentObject(hospitalVM)
                .environmentObject(appointmentManager)
            
            window.rootViewController = UIHostingController(rootView: homeView)
            window.makeKeyAndVisible()
            
            // Post notification to dismiss all modals
            NotificationCenter.default.post(name: NSNotification.Name("DismissAllModals"), object: nil)
        }
    }
    
    // Function to ensure consistent time display for appointments
    private func ensureConsistentTime(displayTimes: (String, String), rawTimes: (String, String)) -> (String, String, String, String) {
        // Log the input values for debugging
        print("⏳ ensureConsistentTime input: Display=(\(displayTimes.0), \(displayTimes.1)), Raw=(\(rawTimes.0), \(rawTimes.1))")
        
        // If raw times are empty or invalid, generate them from display times
        let finalRawStartTime: String
        let finalRawEndTime: String
        
        // Check if raw times are valid
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let rawStartValid = rawTimes.0.count >= 5 && (timeFormatter.date(from: rawTimes.0) != nil || 
                                                      timeFormatter.date(from: rawTimes.0 + ":00") != nil)
        
        let rawEndValid = rawTimes.1.count >= 5 && (timeFormatter.date(from: rawTimes.1) != nil || 
                                               timeFormatter.date(from: rawTimes.1 + ":00") != nil)
        
        if !rawStartValid || rawTimes.0.isEmpty {
            finalRawStartTime = DoctorAvailabilityModels.AppointmentSlot.convertToRawTime(displayTimes.0)
            print("📝 Generated raw start time: \(finalRawStartTime) from display time \(displayTimes.0)")
        } else {
            finalRawStartTime = rawTimes.0.count == 5 ? rawTimes.0 + ":00" : rawTimes.0
            print("📝 Using original raw start time: \(finalRawStartTime)")
        }
        
        if !rawEndValid || rawTimes.1.isEmpty {
            finalRawEndTime = DoctorAvailabilityModels.AppointmentSlot.convertToRawTime(displayTimes.1)
            print("📝 Generated raw end time: \(finalRawEndTime) from display time \(displayTimes.1)")
        } else {
            finalRawEndTime = rawTimes.1.count == 5 ? rawTimes.1 + ":00" : rawTimes.1
            print("📝 Using original raw end time: \(finalRawEndTime)")
        }
        
        // Make sure display times are properly formatted
        let finalDisplayStartTime = formatTimeForDisplay(finalRawStartTime)
        let finalDisplayEndTime = formatTimeForDisplay(finalRawEndTime)
        
        print("⌛ Time conversion completed: Raw=(\(finalRawStartTime)-\(finalRawEndTime)) Display=(\(finalDisplayStartTime)-\(finalDisplayEndTime))")
        
        // Return both display and raw times
        return (finalDisplayStartTime, finalDisplayEndTime, finalRawStartTime, finalRawEndTime)
    }
    
    // Helper function to convert database time format to display format
    private func formatTimeForDisplay(_ databaseTime: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let date = inputFormatter.date(from: databaseTime) {
            return outputFormatter.string(from: date)
        }
        
        // Try alternative formats
        let alternativeFormats = ["HH:mm", "h:mm a", "hh:mm a", "h:mm"]
        for format in alternativeFormats {
            inputFormatter.dateFormat = format
            if let date = inputFormatter.date(from: databaseTime) {
                return outputFormatter.string(from: date)
            }
        }
        
        print("⚠️ Warning: Could not format time: \(databaseTime)")
        return databaseTime
    }
    
    private func saveAndNavigate() {
        // Prevent multiple taps
        if isLoading {
            print("⚠️ Already processing, ignoring additional tap")
            return
        }
        
        isLoading = true
        
        // Check if this appointment was already created by PaymentFinalView
        Task {
            do {
                // First, check if there's already an appointment with this doctor and date
                let supabase = SupabaseController.shared
                
                // Format date for database
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedDate = dateFormatter.string(from: appointmentDate)
                
                // Ensure we have consistent time formats
                let (displayStart, displayEnd, finalRawStart, finalRawEnd) = ensureConsistentTime(
                    displayTimes: (startTime, endTime),
                    rawTimes: (rawStartTime, rawEndTime)
                )
                
                // Look for matching appointments that might have been created
                let existingAppointments = try await supabase.select(
                    from: "appointments",
                    where: "doctor_id",
                    equals: doctor.id
                ).filter { appointment in
                    guard let appointmentDate = appointment["appointment_date"] as? String,
                          let status = appointment["status"] as? String else {
                        return false
                    }
                    return appointmentDate == formattedDate && status == "upcoming"
                }

                if !existingAppointments.isEmpty {
                    print("✅ Found existing appointment with this doctor and date - assuming PaymentFinalView created it")
                    
                    // If appointment exists, just navigate to home
                    navigateToHome()
                    return
                }
                
                // If no existing appointment is found, proceed with creating one
                print("⚠️ No existing appointment found - creating new appointment")
                
                // Generate appointment ID if not already generated
                if appointmentId.isEmpty {
                    let randomNum = String(format: "%03d", Int.random(in: 0...999))
                    let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
                    appointmentId = "APPT\(randomNum)\(randomLetter)"
                    print("📋 Generated new appointment ID: \(appointmentId)")
                } else {
                    print("📋 Using existing appointment ID: \(appointmentId)")
                }
                
                // Create a date for the appointment time based on properly formatted time
                let displayTimeFormatter = DateFormatter()
                displayTimeFormatter.dateFormat = "HH:mm:ss"
                let appointmentTime = displayTimeFormatter.date(from: finalRawStart) ?? Date()
                
                // Convert to a good display format for the UI
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "h:mm a"
                let displayStartTime = displayFormatter.string(from: appointmentTime)
                let displayEndTimeDate = displayTimeFormatter.date(from: finalRawEnd) ?? Date(timeInterval: 3600, since: appointmentTime)
                let displayEndTime = displayFormatter.string(from: displayEndTimeDate)
                
                print("💾 Saving appointment with times: DB=(\(finalRawStart)-\(finalRawEnd)) Display=(\(displayStartTime)-\(displayEndTime))")
                
                // Create appointment object for local state with the consistent display times
                let appointment = Appointment(
                    id: appointmentId,
                    doctor: doctor.toModelDoctor(),
                    date: appointmentDate,
                    time: appointmentTime,
                    status: .upcoming,
                    startTime: displayStartTime,
                    endTime: displayEndTime,
                    isPremium: isPremium
                )
                
                // First ensure we have a valid patient_id
                guard let userId = userId else {
                    print("❌ No user ID found")
                    throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "user_id_not_found".localized])
                }
                
                let patientResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patientData = patientResults.first,
                      let patientId = patientData["patient_id"] as? String else {
                    print("❌ Could not get or create patient_id")
                    throw NSError(domain: "AppointmentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "patient_verification_failed".localized])
                }
                
                print("✅ Got patient_id: \(patientId)")
                
                // Use the final raw times for consistent database storage
                let startTime = finalRawStart
                let endTime = finalRawEnd
                
                print("🕒 Using times: display=(\(displayStart)-\(displayEnd)), raw=(\(startTime)-\(endTime))")
                
                // Format times properly for database storage - 24-hour format
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                // Ensure start and end times are properly formatted
                let formattedStartTime: String
                let formattedEndTime: String
                
                // If times are in the correct format, use them directly
                if timeFormatter.date(from: startTime) != nil {
                    formattedStartTime = startTime
                } else {
                    // Try to convert from any other format to HH:mm:ss
                    let displayFormatter = DateFormatter()
                    var parsedStartTime = ""
                    // Try different formats
                    for format in ["h:mm a", "HH:mm", "h:mm", "hh:mm a"] {
                        displayFormatter.dateFormat = format
                        if let date = displayFormatter.date(from: startTime) {
                            parsedStartTime = timeFormatter.string(from: date)
                            break
                        }
                    }
                    // If all else fails, use a default time
                    formattedStartTime = parsedStartTime.isEmpty ? "12:00:00" : parsedStartTime
                    if parsedStartTime.isEmpty {
                        print("⚠️ Warning: Could not parse start time \(startTime), using default: \(formattedStartTime)")
                    }
                }
                
                // Same for end time
                if timeFormatter.date(from: endTime) != nil {
                    formattedEndTime = endTime
                } else {
                    // Try to convert from any other format to HH:mm:ss
                    let displayFormatter = DateFormatter()
                    var parsedEndTime = ""
                    // Try different formats
                    for format in ["h:mm a", "HH:mm", "h:mm", "hh:mm a"] {
                        displayFormatter.dateFormat = format
                        if let date = displayFormatter.date(from: endTime) {
                            parsedEndTime = timeFormatter.string(from: date)
                            break
                        }
                    }
                    // If all else fails, use a default time
                    formattedEndTime = parsedEndTime.isEmpty ? "13:00:00" : parsedEndTime
                    if parsedEndTime.isEmpty {
                        print("⚠️ Warning: Could not parse end time \(endTime), using default: \(formattedEndTime)")
                    }
                }
                
                // Log the before/after for debugging
                print("Time conversion: Raw start=\(startTime) → Formatted=\(formattedStartTime)")
                print("Time conversion: Raw end=\(endTime) → Formatted=\(formattedEndTime)")
                
                // Format the slot JSON properly - ensure it uses the same formatted times
                let slotJson = """
                {"doctor_id": "\(doctor.id)", "start_time": "\(formattedStartTime)", "end_time": "\(formattedEndTime)"}
                """
                
                // Create appointment data with all required fields
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId,
                    "doctor_id": doctor.id,
                    "hospital_id": doctor.hospitalId,
                    "appointment_date": formattedDate,
                    "status": "upcoming",
                    "reason": "medical_consultation".localized,
                    "isdone": false,
                    "is_premium": isPremium,
                    "slot_start_time": formattedStartTime,
                    "slot_end_time": formattedEndTime,
                    "slot": slotJson
                ]
                
                // Use the insert method (which uses REST API)
                print("🔄 Inserting appointment into database...")
                try await supabase.insert(into: "appointments", values: appointmentData)
                print("✅ Successfully inserted appointment")
                
                // Add to local state
                await MainActor.run {
                    // Create and add appointment to local state
                    AppointmentManager.shared.addAppointment(appointment)
                }
                
                // Refresh appointments from database
                if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                    print("🔄 Refreshing appointments after booking with user ID: \(userId)")
                    
                    // We should get the patient ID again and use that to fetch appointments
                    let patientResults = try await supabase.select(
                        from: "patients",
                        where: "user_id",
                        equals: userId
                    )
                    
                    if let patientData = patientResults.first,
                       let fetchedPatientId = patientData["id"] as? String ?? patientData["patient_id"] as? String {
                        try await hospitalVM.fetchAppointments(for: fetchedPatientId)
                        print("✅ Successfully refreshed appointments after booking")
                    } else {
                        print("⚠️ Could not find patient ID after booking")
                    }
                }
                
                print("✅ Appointment booking completed successfully")
                
                // Now that we've confirmed the appointment is saved, navigate
                navigateToHome()
                
            } catch {
                print("❌ Error saving appointment: \(error.localizedDescription)")
                // Keep the error state but don't prevent navigation
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "error_creating_appointment".localized + ": \(error.localizedDescription)"
                }
            }
        }
    }
}
