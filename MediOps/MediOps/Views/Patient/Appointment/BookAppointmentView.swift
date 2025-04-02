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
    @State private var selectedSlot: AppointmentModels.DoctorAvailabilitySlot?
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
                    "is_premium": false
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
} 
