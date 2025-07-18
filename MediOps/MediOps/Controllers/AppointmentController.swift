import Foundation

class AppointmentController: ObservableObject {
    private let supabase = SupabaseController.shared
    
    @Published var appointments: [AppointmentModels.Appointment] = []
    @Published var availableSlots: [AppointmentModels.DoctorAvailability] = []
    
    // Create a new appointment
    func createAppointment(patientId: String, doctorId: String, hospitalId: String,
                         availabilitySlotId: Int, appointmentDate: Date, reason: String) async throws -> AppointmentModels.Appointment {
        // First, get the PAT format patient_id from the patients table
        let patientResults = try await supabase.select(
            from: "patients",
            where: "id",
            equals: patientId
        )
        
        guard let patientData = patientResults.first,
              let patFormatId = patientData["patient_id"] as? String else {
            throw NSError(domain: "AppointmentError", 
                         code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Could not find patient_id in PAT format"])
        }
        
        // Generate APPT format ID for the appointment
        let randomNum = String(format: "%03d", Int.random(in: 0...999))
        let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
        let appointmentId = "APPT\(randomNum)\(randomLetter)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: appointmentDate)
        
        // Create an Encodable struct for the appointment data
        struct AppointmentData: Encodable {
            let id: String
            let patient_id: String
            let doctor_id: String
            let hospital_id: String
            let appointment_date: String
            let reason: String
            let status: String
            let isdone: Bool
            let is_premium: Bool?
        }
        
        // Get premium status from patient data
        let isPremium = (patientData["user_type"] as? String) == "premium"
        
        let appointmentData = AppointmentData(
            id: appointmentId,
            patient_id: patFormatId,  // Using PAT format ID
            doctor_id: doctorId,
            hospital_id: hospitalId,
            appointment_date: formattedDate,
            reason: reason,
            status: "upcoming",
            isdone: false,
            is_premium: isPremium
        )
        
        do {
            try await supabase.insert(into: "appointments", data: appointmentData)
            
            // Fetch the created appointment to get all fields with default values
            let results = try await supabase.select(from: "appointments", where: "id", equals: appointmentId)
            guard let data = results.first else {
                throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch created appointment"])
            }
            
            // Parse the fetched appointment
            guard 
                let fetchedId = data["id"] as? String,
                let fetchedPatientId = data["patient_id"] as? String,
                let fetchedDoctorId = data["doctor_id"] as? String,
                let fetchedHospitalId = data["hospital_id"] as? String,
                let fetchedAppointmentDateString = data["appointment_date"] as? String,
                let fetchedBookingTimeString = data["booking_time"] as? String,
                let fetchedStatusString = data["status"] as? String,
                let fetchedReason = data["reason"] as? String,
                let fetchedCreatedAtString = data["created_at"] as? String,
                let fetchedUpdatedAtString = data["updated_at"] as? String,
                let status = AppointmentModels.Status(rawValue: fetchedStatusString)
            else {
                throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid appointment data"])
            }
            
            let timestampFormatter = ISO8601DateFormatter()
            
            let appointment = AppointmentModels.Appointment(
                id: fetchedId,
                patientId: fetchedPatientId,  // This will be the PAT format ID
                doctorId: fetchedDoctorId,
                hospitalId: fetchedHospitalId,
                availabilitySlotId: availabilitySlotId,
                appointmentDate: dateFormatter.date(from: fetchedAppointmentDateString) ?? Date(),
                bookingTime: timestampFormatter.date(from: fetchedBookingTimeString) ?? Date(),
                status: status,
                createdAt: timestampFormatter.date(from: fetchedCreatedAtString) ?? Date(),
                updatedAt: timestampFormatter.date(from: fetchedUpdatedAtString) ?? Date(),
                reason: fetchedReason
            )
            
            await MainActor.run {
                appointments.append(appointment)
            }
            
            return appointment
        } catch {
            print("Error creating appointment: \(error)")
            throw error
        }
    }
    
    // Get all appointments for a patient
    func getAppointments(forPatient patientId: String) async throws {
        do {
            let results = try await supabase.select(from: "appointments", where: "patient_id", equals: patientId)
            
            let dateFormatter = ISO8601DateFormatter()
            
            let fetchedAppointments = try results.map { data -> AppointmentModels.Appointment in
                guard 
                    let id = data["id"] as? String,
                    let doctorId = data["doctor_id"] as? String,
                    let hospitalId = data["hospital_id"] as? String,
                    let availabilitySlotId = data["availability_slot_id"] as? Int,
                    let appointmentDateString = data["appointment_date"] as? String,
                    let bookingTimeString = data["booking_time"] as? String,
                    let statusString = data["status"] as? String,
                    let reason = data["reason"] as? String,
                    let createdAtString = data["created_at"] as? String,
                    let updatedAtString = data["updated_at"] as? String,
                    let status = AppointmentModels.Status(rawValue: statusString)
                else {
                    throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid appointment data"])
                }
                
                return AppointmentModels.Appointment(
                    id: id,
                    patientId: patientId,
                    doctorId: doctorId,
                    hospitalId: hospitalId,
                    availabilitySlotId: availabilitySlotId,
                    appointmentDate: dateFormatter.date(from: appointmentDateString) ?? Date(),
                    bookingTime: dateFormatter.date(from: bookingTimeString) ?? Date(),
                    status: status,
                    createdAt: dateFormatter.date(from: createdAtString) ?? Date(),
                    updatedAt: dateFormatter.date(from: updatedAtString) ?? Date(),
                    reason: reason
                )
            }
            
            await MainActor.run {
                self.appointments = fetchedAppointments
            }
        } catch {
            print("Error fetching appointments: \(error)")
            throw error
        }
    }
    
    // Get available slots for a doctor
    func getAvailableSlots(forDoctor doctorId: String, date: Date) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        do {
            let results = try await supabase.select(
                from: "doctor_availability",
                where: "doctor_id",
                equals: doctorId
            )
            
            let slots = try results.map { data -> AppointmentModels.DoctorAvailability in
                guard
                    let id = data["id"] as? Int,
                    let startTime = data["slot_time"] as? String,
                    let endTime = data["slot_end_time"] as? String
                else {
                    throw NSError(domain: "AvailabilityError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid availability data"])
                }
                
                return AppointmentModels.DoctorAvailability(
                    id: id,
                    doctorId: doctorId,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    isAvailable: true
                )
            }
            
            await MainActor.run {
                self.availableSlots = slots
            }
        } catch {
            print("Error fetching available slots: \(error)")
            throw error
        }
    }
    
    // Update appointment status
    func updateAppointmentStatus(appointmentId: String, status: AppointmentModels.Status) async throws {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        
        struct UpdateData: Encodable {
            let status: String
            let updated_at: String
        }
        
        let updateData = UpdateData(
            status: status.rawValue,
            updated_at: dateFormatter.string(from: now)
        )
        
        do {
            try await supabase.update(
                table: "appointments",
                data: updateData,
                where: "id",
                equals: appointmentId
            )
            
            await MainActor.run {
                if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
                    let updatedAppointment = AppointmentModels.Appointment(
                        id: appointments[index].id,
                        patientId: appointments[index].patientId,
                        doctorId: appointments[index].doctorId,
                        hospitalId: appointments[index].hospitalId,
                        availabilitySlotId: appointments[index].availabilitySlotId,
                        appointmentDate: appointments[index].appointmentDate,
                        bookingTime: appointments[index].bookingTime,
                        status: status,
                        createdAt: appointments[index].createdAt,
                        updatedAt: now,
                        reason: appointments[index].reason
                    )
                    appointments[index] = updatedAppointment
                }
            }
        } catch {
            print("Error updating appointment status: \(error)")
            throw error
        }
    }
    
    // Cancel appointment
    func cancelAppointment(appointmentId: String) async throws {
        try await updateAppointmentStatus(appointmentId: appointmentId, status: .cancelled)
    }
} 