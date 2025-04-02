import Foundation
import SwiftUI

class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    private var isRefreshing = false // Track if refresh is in progress
    
    private init() {
        // Try to load any appointments from the last session
        if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
            Task {
                await refreshAppointmentsAsync()
            }
        }
    }
    
    func addAppointment(_ appointment: Appointment) {
        // Check if appointment already exists to avoid duplicates
        if !appointments.contains(where: { $0.id == appointment.id }) {
            appointments.append(appointment)
        }
    }
    
    func updateAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        } else {
            // If not found, add it
            addAppointment(appointment)
        }
    }
    
    func updateAppointments(_ newAppointments: [Appointment]) {
        // Create a dictionary of existing appointments for quick lookup
        var existingAppointments = [String: Appointment]()
        for appointment in appointments {
            existingAppointments[appointment.id] = appointment
        }
        
        // Create a dictionary of new appointments
        var updatedAppointments = [String: Appointment]()
        for appointment in newAppointments {
            updatedAppointments[appointment.id] = appointment
        }
        
        // Merge existing appointments with new ones, preserving newly added ones
        for (id, appointment) in existingAppointments {
            if updatedAppointments[id] == nil && appointment.status == .upcoming {
                // Keep any upcoming appointments that aren't in the new list
                updatedAppointments[id] = appointment
            }
        }
        
        // Update the appointments array
        appointments = Array(updatedAppointments.values)
    }
    
    func cancelAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .cancelled
            appointments[index] = appointment
            
            // Remove from Supabase
            Task {
                do {
                    try await updateAppointmentStatus(appointmentId: appointmentId, status: "cancelled")
                    
                    // Refresh appointments
                    if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                        let supabase = SupabaseController.shared
                        let patientResults = try await supabase.select(
                            from: "patients",
                            where: "user_id",
                            equals: userId
                        )
                        
                        if let patientData = patientResults.first, let patientId = patientData["id"] as? String {
                            try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                        }
                    }
                } catch {
                    // Error handled silently to prevent disrupting user experience
                }
            }
        }
    }
    
    private func updateAppointmentStatus(appointmentId: String, status: String) async throws {
        let url = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co/rest/v1/appointments?id=eq.\(appointmentId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "apikey")
        request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateData = ["status": status]
        let jsonData = try JSONSerialization.data(withJSONObject: updateData)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
            throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update appointment status"])
        }
    }
    
    func completeAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .completed
            appointments[index] = appointment
            
            // Update the completed status in Supabase
            Task {
                do {
                    try await updateAppointmentStatus(appointmentId: appointmentId, status: "completed")
                    
                    // Refresh appointments
                    if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                        let supabase = SupabaseController.shared
                        let patientResults = try await supabase.select(
                            from: "patients",
                            where: "user_id",
                            equals: userId
                        )
                        
                        if let patientData = patientResults.first, let patientId = patientData["id"] as? String {
                            try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                        }
                    }
                } catch {
                    // Error handled silently to prevent disrupting user experience
                }
            }
        }
    }
    
    @MainActor
    func setAppointments(_ newAppointments: [Appointment]) {
        // Create a set of IDs from new appointments for quick lookup
        let newAppointmentIds = Set(newAppointments.map { $0.id })
        
        // Keep only local appointments that are not in the new set and are upcoming
        let localOnlyAppointments = appointments.filter { appointment in
            !newAppointmentIds.contains(appointment.id) && appointment.status == .upcoming
        }
        
        // Combine local-only appointments with new appointments
        appointments = newAppointments + localOnlyAppointments
        
        // Sort appointments by date and time
        appointments.sort { (a1, a2) -> Bool in
            if a1.date == a2.date {
                return a1.time < a2.time
            }
            return a1.date < a2.date
        }
    }
    
    func clearAppointments() {
        appointments = []
    }
    
    func refreshAppointments() {
        Task {
            await refreshAppointmentsAsync()
        }
    }
    
    @MainActor
    private func refreshAppointmentsAsync() async {
        if isRefreshing {
            return
        }
        
        isRefreshing = true
        print("🔄 Starting appointment refresh")
        
        guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
            print("❌ No user ID found for refresh")
            isRefreshing = false
            return
        }
        
        do {
            let supabase = SupabaseController.shared
            
            print("🔍 Looking up patient record for user: \(userId)")
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            guard let patientData = patientResults.first else {
                print("❌ Could not find patient record for user: \(userId)")
                isRefreshing = false
                return
            }
            
            let patientId = (patientData["patient_id"] as? String) ?? (patientData["id"] as? String)
            
            guard let finalPatientId = patientId else {
                print("❌ Could not find patient_id for user: \(userId)")
                isRefreshing = false
                return
            }
            
            print("✅ Found patient_id: \(finalPatientId)")
            
            // Fetch appointments with specific columns
            let appointmentResults = try await supabase.select(
                        from: "appointments",
                        where: "patient_id",
                equals: finalPatientId
            )
            
            print("📊 Found \(appointmentResults.count) appointments in total")
            
            var newAppointments: [Appointment] = []
            for appointmentData in appointmentResults {
                if let appointmentId = appointmentData["id"] as? String,
                   let doctorId = appointmentData["doctor_id"] as? String,
                   let statusString = appointmentData["status"] as? String,
                   let appointmentDateString = appointmentData["appointment_date"] as? String {
                    
                    print("🔍 Processing appointment: \(appointmentId)")
                    print("   Raw status from DB: \(statusString)")
                    
                    // Parse the appointment date
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    guard let appointmentDate = dateFormatter.date(from: appointmentDateString) else {
                        print("⚠️ Could not parse appointment date: \(appointmentDateString)")
                        continue
                    }
                    
                    // Get appointment time information
                    var rawStartTime: String?
                    var rawEndTime: String?
                    
                    // First try to get from slot_start_time
                    if let startTime = appointmentData["slot_start_time"] as? String {
                        rawStartTime = startTime
                        print("📌 Found slot_start_time: \(startTime)")
                    }
                    
                    if let endTime = appointmentData["slot_end_time"] as? String {
                        rawEndTime = endTime
                        print("📌 Found slot_end_time: \(endTime)")
                    }
                    
                    // If not found, try extracting from slot JSON
                    if (rawStartTime == nil || rawEndTime == nil),
                       let slotJson = appointmentData["slot"] as? String,
                       let slotData = slotJson.data(using: .utf8) {
                        do {
                            if let slot = try JSONSerialization.jsonObject(with: slotData) as? [String: Any] {
                                if rawStartTime == nil, let slotStartTime = slot["start_time"] as? String {
                                    rawStartTime = slotStartTime
                                    print("📌 Found start time in slot JSON: \(slotStartTime)")
                                }
                                
                                if rawEndTime == nil, let slotEndTime = slot["end_time"] as? String {
                                    rawEndTime = slotEndTime
                                    print("📌 Found end time in slot JSON: \(slotEndTime)")
                                }
                            }
                        } catch {
                            print("⚠️ Error parsing slot JSON: \(error.localizedDescription)")
                        }
                    }
                    
                    // Use defaults if still not found
                    let finalRawStartTime = rawStartTime ?? "12:00:00"
                    let finalRawEndTime = rawEndTime ?? "13:00:00"
                    
                    // Format for display using our consistent helper
                    let displayStartTime = HospitalViewModel.shared.formatSlotTime(finalRawStartTime)
                    let displayEndTime = HospitalViewModel.shared.formatSlotTime(finalRawEndTime)
                    
                    print("🕒 Appointment times: Raw=(\(finalRawStartTime)-\(finalRawEndTime)) Display=(\(displayStartTime)-\(displayEndTime))")
                    
                    // Create time Date object for sorting
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
                    
                    var appointmentTime: Date
                    if let parsedTime = timeFormatter.date(from: finalRawStartTime) {
                        appointmentTime = parsedTime
                    } else if finalRawStartTime.count == 5 {
                        // Try adding seconds component
                        if let parsedTime = timeFormatter.date(from: finalRawStartTime + ":00") {
                            appointmentTime = parsedTime
                        } else {
                            appointmentTime = Date()
                        }
                    } else {
                        appointmentTime = Date()
                    }
                    
                    // Fetch doctor details
                    let doctorResults = try await supabase.select(
                        from: "doctors",
                        where: "id",
                        equals: doctorId
                    )
                    
                    if let doctorData = doctorResults.first,
                       let name = doctorData["name"] as? String,
                       let specialization = doctorData["specialization"] as? String {
                        
                        let doctor = Models.Doctor.createSimplifiedDoctor(
                            id: doctorId,
                            name: name,
                            specialization: specialization
                        )
                        
                        // Map the status string to AppointmentStatus
                        let status: AppointmentStatus
                        switch statusString.lowercased() {
                        case "completed":
                            status = .completed
                        case "cancelled":
                            status = .cancelled
                        case "missed":
                            status = .missed
                        default:
                            status = .upcoming
                        }
                        
                        print("   Mapped status: \(status.rawValue)")
                        
                        let appointment = Appointment(
                            id: appointmentId,
                            doctor: doctor,
                            date: appointmentDate,
                            time: appointmentTime,
                            status: status,
                            startTime: displayStartTime,
                            endTime: displayEndTime,
                            isPremium: appointmentData["is_premium"] as? Bool
                        )
                        
                        newAppointments.append(appointment)
                    }
                }
            }
            
            // Debug print appointment counts by status
            let completedCount = newAppointments.filter { $0.status == .completed }.count
            let upcomingCount = newAppointments.filter { $0.status == .upcoming }.count
            let cancelledCount = newAppointments.filter { $0.status == .cancelled }.count
            let missedCount = newAppointments.filter { $0.status == .missed }.count
            
            print("📊 Appointment Status Summary:")
            print("   Total: \(newAppointments.count)")
            print("   Completed: \(completedCount)")
            print("   Upcoming: \(upcomingCount)")
            print("   Cancelled: \(cancelledCount)")
            print("   Missed: \(missedCount)")
            
            // Update the appointments array
            self.appointments = newAppointments
            
            print("✅ Successfully refreshed appointments")
        } catch {
            print("❌ Error refreshing appointments: \(error.localizedDescription)")
        }
        
        isRefreshing = false
    }
}
