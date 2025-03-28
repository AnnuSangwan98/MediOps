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

// Simple Doctor model for appointments
// This helps ensure compatibility across different Doctor model versions
extension Doctor {
    static func createSimplifiedDoctor(id: String, name: String, specialization: String) -> Doctor {
        // Use default values for any required fields that we don't have
        // The specific implementation will depend on which Doctor struct is referenced here
        return Doctor(
            id: id,
            hospitalId: "HOSP001",
            name: name,
            specialization: specialization,
            qualifications: [],
            licenseNo: "",
            experience: 0,
            email: "",
            contactNumber: nil,
            doctorStatus: "active",
            rating: 4.0,
            consultationFee: 0.0
        )
    }
} 