enum AppointmentStatus: String {
    case upcoming = "upcoming"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct Appointment: Identifiable {
    let id: String
    let doctor: Doctor
    let date: Date
    let time: Date
    var status: AppointmentStatus
    var startTime: String?
    var endTime: String?
    
    // Add computed property to check if appointment is in the past
    var isPast: Bool {
        return date < Date()
    }
}