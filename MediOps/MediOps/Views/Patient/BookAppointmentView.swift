import SwiftUI

struct BookAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @AppStorage("current_user_id") private var userId: String?
    
    @State private var selectedDoctor: HospitalDoctor? = nil
    @State private var selectedHospital: HospitalModel? = nil
    @State private var selectedDate = Date()
    @State private var selectedSlot: AppointmentModels.DoctorAvailability?
    @State private var reason: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
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
                                if newDoctor != nil {
                                    hospitalVM.selectedDoctor = newDoctor
                                    Task {
                                        await hospitalVM.fetchAvailableSlots(for: selectedDate)
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
                        if selectedDoctor != nil {
                            Task {
                                await hospitalVM.fetchAvailableSlots(for: newDate)
                            }
                        }
                    }
                    
                    // Available Time Slots
                    if selectedDoctor != nil {
                        if hospitalVM.isLoading {
                            HStack {
                                Text("Loading available slots...")
                                Spacer()
                                ProgressView()
                            }
                        } else if hospitalVM.availableSlots.isEmpty {
                            Text("No available slots on this date")
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
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedDoctor != nil &&
        selectedHospital != nil &&
        selectedSlot != nil &&
        !reason.isEmpty
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
            // Get the patient ID for this user ID
            print("🔍 Getting patient ID for user: \(userId)")
            let supabase = SupabaseController.shared
            
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            guard let patientData = patientResults.first, let patientId = patientData["id"] as? String else {
                isLoading = false
                print("⚠️ No patient record found for user ID: \(userId)")
                alertMessage = "No patient record found. Please complete your profile first."
                showAlert = true
                return
            }
            
            print("✅ Found patient ID: \(patientId) for user ID: \(userId)")
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
            
            // Create appointment data with explicit timestamp
            var appointmentData: [String: Any] = [
                "id": appointmentId,
                "patient_id": patientId,
                "doctor_id": doctor.id,
                "hospital_id": hospital.id,
                "availability_slot_id": slot.id,
                "appointment_date": dateFormatter.string(from: selectedDate),
                "status": "upcoming",
                "reason": reason
            ]
            
            // Insert into database - try direct method
            print("🔄 Creating appointment with ID: \(appointmentId)")
            
            let url = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co/rest/v1/appointments")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "apikey")
            request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            let jsonData = try JSONSerialization.data(withJSONObject: appointmentData)
            request.httpBody = jsonData
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                
                // Try to get error details
                if let errorStr = String(data: responseData, encoding: .utf8) {
                    print("❌ Error details: \(errorStr)")
                }
                
                throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create appointment. Status code: \(httpResponse.statusCode)"])
            }
            
            // Try to parse the response data to confirm success
            if let responseStr = String(data: responseData, encoding: .utf8) {
                print("✅ Supabase response: \(responseStr)")
            }
            
            print("✅ Successfully saved appointment to Supabase")
            
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
                status: .upcoming
            )
            
            // Add to local state
            appointmentManager.addAppointment(appointment)
            
            // Refresh appointments from database to ensure consistency
            try await hospitalVM.fetchAppointments(for: patientId)
            
            // Display success message
            isLoading = false
            alertMessage = "Appointment booked successfully for \(selectedDate.formatted(date: .long, time: .omitted))!"
            showAlert = true
        } catch {
            isLoading = false
            print("❌ Error booking appointment: \(error.localizedDescription)")
            alertMessage = "Failed to book appointment: \(error.localizedDescription)"
            showAlert = true
        }
    }
} 