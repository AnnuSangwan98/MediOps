import SwiftUI

class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    
    private init() {}
    
    func addAppointment(_ appointment: Appointment) {
        appointments.append(appointment)
        objectWillChange.send()
    }
    
    func cancelAppointment(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments.remove(at: index)
            objectWillChange.send()
        }
    }
    
    func updateAppointment(_ updatedAppointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == updatedAppointment.id }) {
            appointments[index] = updatedAppointment
            objectWillChange.send()
        }
    }
    
    // Get only upcoming appointments
    var upcomingAppointments: [Appointment] {
        appointments.filter { $0.status == .upcoming }
    }
}


