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
                try? await HospitalViewModel.shared.fetchAppointments(for: userId)
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
        appointments = newAppointments
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
        // If already refreshing, don't start another refresh
        if isRefreshing {
            return
        }
        
        isRefreshing = true
        
        guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
            isRefreshing = false
            return
        }
        
        do {
            // First, get the patient ID associated with this user ID
            let supabase = SupabaseController.shared
            
            // Query patients table to get patient ID for current user
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            if let patientData = patientResults.first, let patientId = patientData["id"] as? String {
                // Now fetch appointments using the patient ID
                try await HospitalViewModel.shared.fetchAppointments(for: patientId)
            }
        } catch {
            // Error handled silently
        }
        
        isRefreshing = false
    }
}

