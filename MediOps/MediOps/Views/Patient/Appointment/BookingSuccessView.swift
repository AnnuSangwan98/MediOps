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
    
    private func formatTime() -> String {
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
                Text("Thanks, your booking has been confirmed.")
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Please check your email for receipt and booking details.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Appointment details card
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    // Doctor avatar and info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.headline)
                            Text(doctor.specialization)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Date and time
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.teal)
                        
                        Text(appointmentDate, style: .date)
                            .foregroundColor(.black)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.teal)
                        
                        Text(formatTime())
                            .foregroundColor(.black)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 5)
            
            Spacer()
            
            Button(action: {
                saveAndNavigate()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                } else {
                    Text("Done")
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
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
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
    
    private func saveAndNavigate() {
        // Prevent multiple taps
        if isLoading {
            print("⚠️ Already processing, ignoring additional tap")
            return
        }
        
        isLoading = true
        
        // Generate appointment ID if not already generated
        if appointmentId.isEmpty {
            let randomNum = String(format: "%03d", Int.random(in: 0...999))
            let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
            appointmentId = "APPT\(randomNum)\(randomLetter)"
            print("📋 Generated new appointment ID: \(appointmentId)")
        } else {
            print("📋 Using existing appointment ID: \(appointmentId)")
        }
        
        // Create a date for the appointment time based on rawStartTime
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let appointmentTime = timeFormatter.date(from: rawStartTime) ?? Date()
        
        // Create appointment object for local state
        let appointment = Appointment(
            id: appointmentId,
            doctor: doctor.toModelDoctor(),
            date: appointmentDate,
            time: appointmentTime,
            status: .upcoming,
            isPremium: isPremium
        )
        
        Task {
            do {
                // First ensure we have a valid patient_id
                guard let userId = userId else {
                    print("❌ No user ID found")
                    throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                }
                
                let supabase = SupabaseController.shared
                
                // Get patient_id using ensurePatientHasPatientId
                let patientResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patientData = patientResults.first,
                      let patientId = patientData["patient_id"] as? String else {
                    print("❌ Could not get or create patient_id")
                    throw NSError(domain: "AppointmentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not verify patient record"])
                }
                
                print("✅ Got patient_id: \(patientId)")
                
                // Format date for database
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedDate = dateFormatter.string(from: appointmentDate)
                
                // Use the raw times passed from previous views
                let startTime = rawStartTime
                let endTime = rawEndTime
                
                // Create appointment data
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId,
                    "doctor_id": doctor.id,
                    "hospital_id": doctor.hospitalId,
                    "appointment_date": formattedDate,
                    "status": "upcoming",
                    "reason": "Medical consultation",
                    "isdone": false,
                    "is_premium": isPremium,
                    "slot_start_time": startTime,
                    "slot_end_time": endTime,
                    "slot": "{\"doctor_id\": \"\(doctor.id)\", \"start_time\": \"\(startTime)\", \"end_time\": \"\(endTime)\"}"
                ]
                
                // Try to insert the appointment
                print("🔄 Inserting appointment into database...")
                try await supabase.insert(into: "appointments", values: appointmentData)
                print("✅ Successfully inserted appointment")
                
                // Verify the appointment exists
                let verifyAppointment = try await supabase.select(
                    from: "appointments",
                    where: "id",
                    equals: appointmentId
                )
                
                if verifyAppointment.isEmpty {
                    print("⚠️ Appointment not found after insert, trying alternative method...")
                    // Try alternative insert method
                    try await supabase.executeSQL(sql: """
                        INSERT INTO appointments (
                            id, patient_id, doctor_id, hospital_id, appointment_date,
                            status, reason, isdone, is_premium,
                            slot_start_time, slot_end_time, slot
                        ) VALUES (
                            '\(appointmentId)', '\(patientId)', '\(doctor.id)', '\(doctor.hospitalId)', '\(formattedDate)',
                            'upcoming', 'Medical consultation', false, \(isPremium),
                            '\(startTime)', '\(endTime)', '{"doctor_id": "\(doctor.id)", "start_time": "\(startTime)", "end_time": "\(endTime)"}'
                        )
                    """)
                }
                
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
                
            } catch {
                print("❌ Error saving appointment: \(error.localizedDescription)")
                // Keep the error state but don't prevent navigation
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = "Error saving appointment: \(error.localizedDescription)"
                }
            }
        }
    }
}
