import Foundation
import SwiftUI

class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    private var isRefreshing = false // Track if refresh is in progress
    
    private init() {
        print("🏥 AppointmentManager initialized")
        // Try to load any appointments from the last session
        if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
            print("🔄 Found user ID at initialization: \(userId)")
            Task {
                do {
                    try await HospitalViewModel.shared.fetchAppointments(for: userId)
                    print("✅ Initial appointments loaded successfully")
                } catch {
                    print("⚠️ Could not load initial appointments: \(error.localizedDescription)")
                }
            }
        } else {
            print("⚠️ No user ID found at initialization")
        }
    }
    
    func addAppointment(_ appointment: Appointment) {
        // Check if appointment already exists to avoid duplicates
        if !appointments.contains(where: { $0.id == appointment.id }) {
            appointments.append(appointment)
            print("✅ Added appointment with ID: \(appointment.id), total count: \(appointments.count)")
        } else {
            print("⚠️ Appointment already exists with ID: \(appointment.id)")
        }
    }
    
    func updateAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
            print("✅ Updated appointment with ID: \(appointment.id)")
        } else {
            // If not found, add it
            addAppointment(appointment)
        }
    }
    
    func cancelAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .cancelled
            appointments[index] = appointment
            print("✅ Cancelled appointment with ID: \(appointmentId)")
            
            // Remove from Supabase
            Task {
                do {
                    print("🔄 Deleting appointment from database: \(appointmentId)")
                    
                    // Option 1: Update the status to cancelled
                    try await updateAppointmentStatus(appointmentId: appointmentId, status: "cancelled")
                    print("✅ Updated appointment status to cancelled in database")
                    
                    // Refresh appointments
                    if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                        print("🔄 Refreshing appointments after cancellation")
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
                    print("❌ Failed to cancel appointment in database: \(error.localizedDescription)")
                }
            }
        } else {
            print("⚠️ Could not find appointment with ID: \(appointmentId) to cancel")
        }
    }
    
    private func updateAppointmentStatus(appointmentId: String, status: String) async throws {
        print("🔄 Updating appointment status: \(appointmentId) -> \(status)")
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
        
        print("✅ Appointment status updated in database: \(appointmentId) -> \(status)")
    }
    
    func completeAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .completed
            appointments[index] = appointment
            print("✅ Completed appointment with ID: \(appointmentId)")
            
            // Update the completed status in Supabase
            Task {
                do {
                    print("🔄 Updating appointment status in database...")
                    try await updateAppointmentStatus(appointmentId: appointmentId, status: "completed")
                    print("✅ Appointment status updated in database: \(appointmentId) -> completed")
                    
                    // Refresh appointments
                    if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                        print("🔄 Refreshing appointments after marking as completed")
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
                    print("❌ Failed to update appointment status in database: \(error.localizedDescription)")
                }
            }
        } else {
            print("⚠️ Could not find appointment with ID: \(appointmentId) to mark as completed")
        }
    }
    
    @MainActor
    func setAppointments(_ newAppointments: [Appointment]) {
        appointments = newAppointments
        print("✅ Set \(appointments.count) appointments from database")
    }
    
    func clearAppointments() {
        appointments = []
        print("🗑 Cleared all appointments")
    }
    
    func refreshAppointments() {
        Task {
            await refreshAppointmentsAsync()
        }
    }
    
    @MainActor
    private func refreshAppointmentsAsync() async {
        // If already refreshing, don't start another refresh
        if isRefreshing {
            print("⚠️ Refresh already in progress, skipping this request")
            return
        }
        
        isRefreshing = true
        
        guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
            print("⚠️ Cannot refresh appointments - no user ID found")
            isRefreshing = false
            return
        }
        
        print("🔄 Refreshing appointments for user: \(userId)")
        
        // Save current appointments count to verify we don't lose data
        let currentAppointmentsCount = appointments.count
        print("📊 Current appointments count before refresh: \(currentAppointmentsCount)")
        
        do {
            // First, get the patient ID associated with this user ID
            print("🔍 Getting patient ID for user: \(userId)")
            let supabase = SupabaseController.shared
            
            // Query patients table to get patient ID for current user
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            if let patientData = patientResults.first, let patientId = patientData["id"] as? String {
                print("✅ Found patient ID: \(patientId) for user ID: \(userId)")
                
                // Now fetch appointments using the patient ID
                try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                print("✅ Appointments refresh operation completed for patient ID: \(patientId)")
                
                // Verify that we didn't lose appointments
                if currentAppointmentsCount > 0 && self.appointments.isEmpty {
                    print("⚠️ CAUTION: Appointment count went from \(currentAppointmentsCount) to 0")
                    print("⚠️ This likely indicates a data inconsistency issue")
                    
                    // Check if appointments table has any data for this patient ID
                    let verificationResults = try await supabase.select(
                        from: "appointments",
                        where: "patient_id",
                        equals: patientId
                    )
                    
                    if !verificationResults.isEmpty {
                        print("🔄 Found \(verificationResults.count) appointments in verification check - should not be 0")
                        print("🔄 Will retry fetch once more")
                        
                        // Try one more time after a short delay
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                    }
                }
                
                // Check if we still have no appointments after refresh
                if self.appointments.isEmpty {
                    print("🔍 DIAGNOSTIC: No appointments found after refresh")
                    print("🔍 DIAGNOSTIC: Running additional checks...")
                    
                    // Check if appointments table has any data
                    let allAppointments = try await supabase.select(from: "appointments")
                    
                    print("📊 DIAGNOSTIC: Total appointments in database: \(allAppointments.count)")
                    
                    // If there are appointments in the database but none for this patient
                    if !allAppointments.isEmpty {
                        let patientIds = allAppointments.compactMap { $0["patient_id"] as? String }
                        print("👤 DIAGNOSTIC: Patient IDs in database: \(patientIds)")
                        
                        // Check if any patient ID matches our patient ID
                        if patientIds.contains(patientId) {
                            print("⚠️ DIAGNOSTIC: Found appointments for patient ID: \(patientId) but they were not loaded correctly")
                        } else {
                            print("⚠️ DIAGNOSTIC: No appointments found for patient ID: \(patientId)")
                        }
                        
                        // Suggest creating a test appointment
                        print("💡 SUGGESTION: Try creating a test appointment using the 'Create Test Appointment' button")
                    }
                }
            } else {
                print("⚠️ No patient record found for user ID: \(userId)")
                print("🔍 DIAGNOSTIC: Checking patients table for available records")
                
                // Check patients table for existing records
                let allPatients = try await supabase.select(from: "patients")
                print("📊 DIAGNOSTIC: Total patients in database: \(allPatients.count)")
                
                if !allPatients.isEmpty {
                    let userIds = allPatients.compactMap { $0["user_id"] as? String }
                    let patientIds = allPatients.compactMap { $0["id"] as? String }
                    print("👤 DIAGNOSTIC: User IDs in patients table: \(userIds)")
                    print("👤 DIAGNOSTIC: Patient IDs in patients table: \(patientIds)")
                }
            }
        } catch {
            print("❌ Failed to refresh appointments: \(error.localizedDescription)")
        }
        
        isRefreshing = false
    }
}

