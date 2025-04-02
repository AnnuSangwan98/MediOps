import Foundation

struct DoctorAvailability: Identifiable, Codable {
    let id: Int
    let doctorId: String
    let hospitalId: String
    var weeklySchedule: [String: [String: Bool]]
    var effectiveFrom: Date
    var effectiveUntil: Date?
    var maxNormalPatients: Int
    var maxPremiumPatients: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case doctorId = "doctor_id"
        case hospitalId = "hospital_id"
        case weeklySchedule = "weekly_schedule"
        case effectiveFrom = "effective_from"
        case effectiveUntil = "effective_until"
        case maxNormalPatients = "max_normal_patients"
        case maxPremiumPatients = "max_premium_patients"
    }
    
    // Convenience initializer for AdminController
    init(doctorId: String, weeklySchedule: [String: [String: Bool]], maxNormalPatients: Int, maxPremiumPatients: Int) {
        self.id = 0 // This will be set by the database
        self.doctorId = doctorId
        self.hospitalId = "" // This should be set appropriately
        self.weeklySchedule = weeklySchedule
        self.effectiveFrom = Date()
        self.effectiveUntil = nil
        self.maxNormalPatients = maxNormalPatients
        self.maxPremiumPatients = maxPremiumPatients
    }
}

// Helper struct for time slots
struct TimeSlot: Codable, Identifiable {
    let start: String
    let end: String
    var id: String { start + end }
} 