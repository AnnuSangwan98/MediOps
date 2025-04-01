import Foundation

struct DoctorAvailability {
    let doctorId: String
    var weeklySchedule: [String: [String: Bool]] // [day: [timeSlot: isAvailable]]
    var maxNormalPatients: Int
    var maxPremiumPatients: Int
} 