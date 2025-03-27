import Foundation

class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    
    private init() {}
    
    func addAppointment(_ appointment: Appointment) {
        appointments.append(appointment)
        saveAppointments()
    }
    
    func updateAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
            saveAppointments()
        }
    }
    
    func cancelAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .cancelled
            appointments[index] = appointment
            saveAppointments()
        }
    }
    
    func completeAppointment(_ appointmentId: String) {
        if let index = appointments.firstIndex(where: { $0.id == appointmentId }) {
            var appointment = appointments[index]
            appointment.status = .completed
            appointments[index] = appointment
            saveAppointments()
        }
    }
    
    private func saveAppointments() {
        // In a real app, this would save to a database or backend service
        // For now, we'll just keep it in memory
    }
    
    func loadAppointments() {
        // In a real app, this would load from a database or backend service
        // For now, we'll just keep it in memory
    }
} 