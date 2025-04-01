import SwiftUI

struct BookingSuccessView: View {
    let doctor: HospitalDoctor
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appointmentManager = AppointmentManager.shared
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var appointmentCreated = false // Track if appointment was created
    @State private var appointmentId = "" // Store the appointment ID to avoid regenerating it
    @AppStorage("current_user_id") private var userId: String?
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: time)
        
        // Calculate end time (1 hour after start time)
        if let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: time) {
            let endTimeString = formatter.string(from: endTime)
            return "\(startTime) to \(endTimeString)"
        }
        
        return startTime
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
        
        // Create appointment object immediately for local state
        let appointment = Appointment(
            id: appointmentId,
            doctor: doctor.toModelDoctor(),
            date: appointmentDate,
            time: appointmentTime,
            status: .upcoming
        )
        
        // Add to local state right away
        appointmentManager.addAppointment(appointment)
        
        // Navigate to HomeTabView immediately - this speeds up the UX
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            print("🔄 Navigating to HomeTabView")
            let homeView = HomeTabView()
                .environmentObject(hospitalVM)
                .environmentObject(appointmentManager)
            
            window.rootViewController = UIHostingController(rootView: homeView)
            window.makeKeyAndVisible()
        }
        
        // Post notification to dismiss all modals
        NotificationCenter.default.post(name: NSNotification.Name("DismissAllModals"), object: nil)
        
        // Now handle the database operations in the background
        Task {
            do {
                // Prevent duplicate appointments - check for existing appointments with this doctor on this date
                print("🔍 Checking for existing appointments with this doctor on this date")
                guard let userId = userId else {
                    throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                }
                
                // First get the patient ID for this user
                let supabase = SupabaseController.shared
                let patientResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patientData = patientResults.first, let patientId = patientData["id"] as? String else {
                    throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Patient record not found"])
                }
                
                // Format date for database
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let formattedDate = dateFormatter.string(from: appointmentDate)
                
                // Check for existing appointments with this doctor on this date
                let checkSQL = """
                SELECT id FROM appointments 
                WHERE patient_id = '\(patientId)' 
                AND doctor_id = '\(doctor.id)' 
                AND appointment_date = '\(formattedDate)'::date
                LIMIT 1;
                """
                
                let existingAppointments = try await supabase.executeSQL(sql: checkSQL)
                if !existingAppointments.isEmpty {
                    print("⚠️ Found existing appointment with this doctor on this date: \(existingAppointments)")
                    if let appointmentDict = existingAppointments.first,
                       let existingId = appointmentDict["id"] as? String {
                        print("✅ Using existing appointment ID: \(existingId)")
                        appointmentId = existingId
                        appointmentCreated = true
                        return
                    }
                }
                
                // First check if the appointment already exists in the database
                let exists = await checkIfAppointmentExists(appointmentId)
                if exists {
                    print("✅ Appointment already exists in database, skipping creation")
                    appointmentCreated = true
                    return
                }
                
                print("🔄 Starting appointment creation for ID: \(appointmentId)")
                
                // We already have userId and patientId from earlier check
                print("✅ Found patient ID: \(patientId) for user ID: \(userId)")
                
                // Format times as strings (e.g., "09:00" and "10:00")
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let startTime = timeFormatter.string(from: appointmentTime)
                
                // Calculate end time (1 hour after start)
                let endTime: String
                if let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: appointmentTime) {
                    endTime = timeFormatter.string(from: endDate)
                } else {
                    endTime = "23:59:00" // Fallback
                }
                
                // Get hospital ID
                let hospitalId = hospitalVM.selectedHospital?.id ?? doctor.hospitalId
                
                // Create slot JSON
                let slotJsonb = """
                {"doctor_id": "\(doctor.id)", "start_time": "\(startTime)", "end_time": "\(endTime)"}
                """
                
                print("📊 APPOINTMENT DETAILS:")
                print("- ID: \(appointmentId)")
                print("- Patient ID: \(patientId)")
                print("- Doctor ID: \(doctor.id)")
                print("- Hospital ID: \(hospitalId)")
                print("- Date: \(formattedDate)")
                print("- Time: \(startTime) - \(endTime)")
                print("- Slot JSON: \(slotJsonb)")
                
                // Use direct REST API approach - most reliable method
                print("🔄 Using direct REST API approach")
                
                // Create the URL for appointments endpoint
                guard let url = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co/rest/v1/appointments") else {
                    throw NSError(domain: "AppointmentError", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                }
                
                // Create a request
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "apikey")
                request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                
                // Prepare appointment data
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId,
                    "doctor_id": doctor.id,
                    "hospital_id": hospitalId,
                    "appointment_date": formattedDate,
                    "status": "upcoming",
                    "reason": "Medical consultation",
                    "isdone": false,
                    "is_premium": false,
                    "slot_start_time": startTime,
                    "slot_end_time": endTime,
                    "slot": slotJsonb
                ]
                
                // Encode data
                let jsonData = try JSONSerialization.data(withJSONObject: appointmentData)
                request.httpBody = jsonData
                
                // Print the raw JSON being sent for debugging
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📤 JSON Payload: \(jsonString)")
                }
                
                // Send request
                print("🔄 Sending API request...")
                let (responseData, response) = try await URLSession.shared.data(for: request)
                
                // Check response
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 API Response Code: \(httpResponse.statusCode)")
                    
                    // Print response headers
                    print("📥 Response Headers:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("  \(key): \(value)")
                    }
                    
                    // Print response body
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        print("📥 Response Body: \(responseString)")
                    }
                    
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        print("✅ API request successful")
                        appointmentCreated = true
                        
                        // Verify the appointment was created
                        let verifyExists = await checkIfAppointmentExists(appointmentId)
                        print("🔍 Verification after creation: \(verifyExists ? "EXISTS" : "NOT FOUND")")
                    } else {
                        throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode)"])
                    }
                } else {
                    throw NSError(domain: "AppointmentError", code: 101, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
                }
                
                // Refresh appointments
                try? await hospitalVM.fetchAppointments(for: patientId)
                
            } catch {
                print("❌ Error creating appointment: \(error.localizedDescription)")
                
                // If there was an error, check if the appointment exists anyway
                // (might have been created despite error)
                let exists = await checkIfAppointmentExists(appointmentId)
                
                if exists {
                    print("✅ Appointment exists in database despite error")
                    appointmentCreated = true
                } else {
                    // Try a direct alternative approach as a backup
                    do {
                        print("🔄 Attempting fallback direct SQL insertion")
                        
                        // We need to re-get the patient ID since we're in a different scope
                        guard let userId = userId else { 
                            print("❌ No user ID available for fallback approach")
                            return 
                        }
                        
                        // Get patient ID again for this scope
                        let supabase = SupabaseController.shared
                        let patientResults = try await supabase.select(
                            from: "patients",
                            where: "user_id",
                            equals: userId
                        )
                        
                        guard let patientData = patientResults.first, let patientId = patientData["id"] as? String else {
                            print("❌ No patient ID found for fallback approach")
                            return
                        }
                        
                        // Format date for database
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let formattedDate = dateFormatter.string(from: appointmentDate)
                        
                        // Format times as strings (e.g., "09:00" and "10:00")
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "HH:mm:ss"
                        let startTime = timeFormatter.string(from: appointmentTime)
                        
                        // Calculate end time (1 hour after start)
                        let endTime: String
                        if let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: appointmentTime) {
                            endTime = timeFormatter.string(from: endDate)
                        } else {
                            endTime = "23:59:00" // Fallback
                        }
                        
                        // Get hospital ID
                        let hospitalId = hospitalVM.selectedHospital?.id ?? doctor.hospitalId
                        
                        // Direct SQL approach to exactly match the schema requirements
                        print("🔄 Using direct SQL approach to match exact schema")
                        let slotJsonb = """
                        {"doctor_id": "\(doctor.id)", "start_time": "\(startTime)", "end_time": "\(endTime)"}
                        """
                        
                        // Use direct REST API approach here too for consistency
                        print("🔄 Using direct REST API approach (fallback)")
                        
                        // Create the URL for appointments endpoint
                        guard let url = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co/rest/v1/appointments") else {
                            throw NSError(domain: "AppointmentError", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                        }
                        
                        // Create a request
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "apikey")
                        request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "Authorization")
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
                        
                        // Prepare appointment data
                        let appointmentData: [String: Any] = [
                            "id": appointmentId,
                            "patient_id": patientId,
                            "doctor_id": doctor.id,
                            "hospital_id": hospitalId,
                            "appointment_date": formattedDate,
                            "status": "upcoming",
                            "reason": "Medical consultation",
                            "isdone": false,
                            "is_premium": false,
                            "slot_start_time": startTime,
                            "slot_end_time": endTime,
                            "slot": slotJsonb
                        ]
                        
                        // Print detailed information
                        print("📊 FALLBACK APPOINTMENT DETAILS:")
                        print("- ID: \(appointmentId)")
                        print("- Patient ID: \(patientId)")
                        print("- Doctor ID: \(doctor.id)")
                        print("- Hospital ID: \(hospitalId)")
                        print("- Date: \(formattedDate)")
                        
                        // Encode data
                        let jsonData = try JSONSerialization.data(withJSONObject: appointmentData)
                        request.httpBody = jsonData
                        
                        // Print the raw JSON being sent for debugging
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            print("📤 FALLBACK JSON Payload: \(jsonString)")
                        }
                        
                        // Send request
                        print("🔄 Sending fallback API request...")
                        let (responseData, response) = try await URLSession.shared.data(for: request)
                        
                        // Check response
                        if let httpResponse = response as? HTTPURLResponse {
                            print("📥 Fallback API Response Code: \(httpResponse.statusCode)")
                            
                            // Print response body
                            if let responseString = String(data: responseData, encoding: .utf8) {
                                print("📥 Fallback Response Body: \(responseString)")
                            }
                            
                            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                                print("✅ Fallback API request successful")
                                appointmentCreated = true
                                
                                // Verify the appointment was created
                                let verifyExists = await checkIfAppointmentExists(appointmentId)
                                print("🔍 Fallback verification: \(verifyExists ? "EXISTS" : "NOT FOUND")")
                            } else {
                                print("❌ Fallback API request failed with status \(httpResponse.statusCode)")
                            }
                        }
                        
                        // Refresh appointments
                        try? await hospitalVM.fetchAppointments(for: patientId)
                    } catch {
                        print("❌ Fallback approach also failed: \(error.localizedDescription)")
                    }
                }
            }
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
                
                guard let patientData = patientResults.first, let patientId = patientData["id"] as? String else {
                    print("🩺 DIAGNOSTIC: No patient ID found for current user")
                    return
                }
                
                print("🩺 DIAGNOSTIC: Using patient ID: \(patientId) for test")
                
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
        VStack(spacing: 25) {
            // Success animation
            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                
                Text("Thanks, your booking has been confirmed.")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Please check your email for receipt and booking details.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Appointment details
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 15) {
                    Circle()
                        .fill(Color.teal)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(doctor.name)
                            .font(.headline)
                        Text(doctor.specialization)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar")
                    Text(appointmentDate.formatted(date: .long, time: .omitted))
                }
                
                HStack {
                    Image(systemName: "clock")
                    Text(formatTime(appointmentTime))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            
            Button(action: saveAndNavigate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    Text("Done")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $showError) {
            Alert(
                title: Text(errorMessage.contains("Error") ? "Error" : "Success"),
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
}
