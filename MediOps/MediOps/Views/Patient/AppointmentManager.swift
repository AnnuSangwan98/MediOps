import SwiftUI

class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    
    private init() {}
    
    func addAppointment(_ appointment: Appointment) {
        appointments.append(appointment)
        objectWillChange.send()
    }
} 