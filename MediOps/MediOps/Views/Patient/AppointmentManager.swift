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
        appointments.removeAll { $0.id == appointment.id }
        objectWillChange.send()
    }
    func updateAppointment(_ updatedAppointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == updatedAppointment.id }) {
            appointments[index] = updatedAppointment
            objectWillChange.send()
        }
    }

}


