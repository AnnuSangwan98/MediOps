import Foundation

struct Appointment: Identifiable {
    let id = UUID()
    let doctor: Doctor
    var date: Date
    var time: Date
    let status: AppointmentStatus
    
    enum AppointmentStatus: String {
        case upcoming = "Upcoming"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
} 