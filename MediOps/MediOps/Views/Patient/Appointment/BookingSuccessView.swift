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
            print("Failed to check if appointment exists: \(error.localizedDescription)")
            return false
        }
    }
    
    private func saveAndNavigate() {
        isLoading = true
        
        // Generate appointment ID in the format APPT[0-9]{3}[A-Z]
        let randomNum = String(format: "%03d", Int.random(in: 0...999))
        let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
        let appointmentId = "APPT\(randomNum)\(randomLetter)"
        
        // Store in Supabase and navigate to HomeTabView
        Task {
            do {
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
                
                print("✅ Found patient ID: \(patientId) for user ID: \(userId)")
                
                // Format date for database
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Get hospital ID or use a default
                let hospitalId = hospitalVM.selectedHospital?.id ?? doctor.hospitalId
                
                // FIRST - check for any existing doctor availability slots
                // This is to ensure we have a valid availability slot ID to reference
                print("🔍 Checking for valid availability slots for doctor: \(doctor.id)")
                let availabilityResults = try await supabase.select(
                    from: "doctor_availability",
                    where: "doctor_id",
                    equals: doctor.id
                )
                
                // If no availability slots exist, we need to create one
                if availabilityResults.isEmpty {
                    print("⚠️ No availability slots found for doctor. Creating dummy slot...")
                    
                    // Create a simple Encodable struct for the slot data
                    struct AvailabilitySlotData: Encodable {
                        let doctor_id: String
                        let date: String
                        let slot_time: String
                        let slot_end_time: String
                        let max_normal_patients: Int
                        let max_premium_patients: Int
                        let total_bookings: Int
                    }
                    
                    // Format date for the slot
                    let slotDate = dateFormatter.string(from: appointmentDate)
                    
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
                    
                    // Create slot data
                    let slotData = AvailabilitySlotData(
                        doctor_id: doctor.id,
                        date: slotDate,
                        slot_time: startTime,
                        slot_end_time: endTime,
                        max_normal_patients: 5,
                        max_premium_patients: 2,
                        total_bookings: 0
                    )
                    
                    // Insert the slot
                    try await supabase.insert(into: "doctor_availability", data: slotData)
                    
                    // Fetch the newly created slot to get its ID
                    let newSlotResults = try await supabase.select(
                        from: "doctor_availability",
                        where: "doctor_id",
                        equals: doctor.id
                    )
                    
                    guard let slotData = newSlotResults.first, let slotId = slotData["id"] as? Int else {
                        throw NSError(domain: "AppointmentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create availability slot"])
                    }
                    
                    print("✅ Created new availability slot with ID: \(slotId)")
                    
                    // Use our specialized method for direct appointment insertion with the new slot ID
                    try await supabase.insertAppointment(
                        id: appointmentId,
                        patientId: patientId,
                        doctorId: doctor.id,
                        hospitalId: hospitalId,
                        slotId: slotId,
                        date: appointmentDate,
                        reason: "Medical consultation"
                    )
                } else {
                    // Use an existing slot
                    guard let slotData = availabilityResults.first, let slotId = slotData["id"] as? Int else {
                        throw NSError(domain: "AppointmentError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get availability slot ID"])
                    }
                    
                    print("✅ Using existing availability slot with ID: \(slotId)")
                    
                    // Use our specialized method for direct appointment insertion with the existing slot ID
                    try await supabase.insertAppointment(
                        id: appointmentId,
                        patientId: patientId,
                        doctorId: doctor.id,
                        hospitalId: hospitalId,
                        slotId: slotId,
                        date: appointmentDate,
                        reason: "Medical consultation"
                    )
                }
                
                print("✅ Successfully saved appointment to Supabase")
                
                // Once successfully saved to Supabase, create and add local appointment object
                let appointment = Appointment(
                    id: appointmentId,
                    doctor: doctor.toModelDoctor(),
                    date: appointmentDate,
                    time: appointmentTime,
                    status: .upcoming
                )
                
                // Add to local state
                appointmentManager.addAppointment(appointment)
                
                // Post notification to dismiss all modals
                NotificationCenter.default.post(name: NSNotification.Name("DismissAllModals"), object: nil)
                
                // Refresh appointments from database
                try await hospitalVM.fetchAppointments(for: patientId)
                
                await MainActor.run {
                    isLoading = false
                    
                    // Navigate to HomeTabView
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let homeView = HomeTabView()
                            .environmentObject(hospitalVM)
                            .environmentObject(appointmentManager)
                        
                        window.rootViewController = UIHostingController(rootView: homeView)
                        window.makeKeyAndVisible()
                    }
                }
            } catch {
                // Try to check if despite the error, the appointment was actually created
                let appointmentMayExist = await checkIfAppointmentExists(appointmentId)
                
                if appointmentMayExist {
                    print("⚠️ Despite error, appointment appears to exist in database")
                    // Create local appointment anyway since it exists in database
                    let appointment = Appointment(
                        id: appointmentId,
                        doctor: doctor.toModelDoctor(),
                        date: appointmentDate,
                        time: appointmentTime, 
                        status: .upcoming
                    )
                    
                    appointmentManager.addAppointment(appointment)
                    
                    // Continue with navigation
                    await MainActor.run {
                        isLoading = false
                        
                        // Navigate to HomeTabView
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let homeView = HomeTabView()
                                .environmentObject(hospitalVM)
                                .environmentObject(appointmentManager)
                            
                            window.rootViewController = UIHostingController(rootView: homeView)
                            window.makeKeyAndVisible()
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        print("❌ ERROR: \(error.localizedDescription)")
                        errorMessage = "Error booking appointment: \(error.localizedDescription)"
                        showError = true
                    }
                }
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
    }
}
