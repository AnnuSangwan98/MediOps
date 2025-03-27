import Foundation

enum AppointmentStatus: String, Codable {
    case upcoming
    case completed
    case cancelled
}

struct Appointment: Identifiable, Codable {
    let id: String
    let doctor: Doctor
    let date: Date
    let time: Date
    var status: AppointmentStatus
    
    init(id: String = UUID().uuidString,
         doctor: Doctor,
         date: Date,
         time: Date,
         status: AppointmentStatus = .upcoming) {
        self.id = id
        self.doctor = doctor
        self.date = date
        self.time = time
        self.status = status
    }
} 