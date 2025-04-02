import Foundation

// MARK: - Appointment Models Namespace
enum AppointmentModels {
    // MARK: - Appointment Status
    enum Status: String, Codable {
        case upcoming = "upcoming"
        case completed = "completed"
        case cancelled = "cancelled"
        case missed = "missed"
    }
    
    // MARK: - Doctor Availability
    struct DoctorAvailabilitySlot: Identifiable, Codable {
        let id: Int
        let doctorId: String
        let date: Date
        let startTime: String
        let endTime: String
        let isAvailable: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case doctorId = "doctor_id"
            case date
            case startTime = "slot_time"
            case endTime = "slot_end_time"
            case isAvailable = "is_available"
        }
    }
    
    // MARK: - Appointment
    struct Appointment: Identifiable, Codable {
        let id: String
        let patientId: String
        let doctorId: String
        let hospitalId: String
        let availabilitySlotId: Int
        let appointmentDate: Date
        let bookingTime: Date
        let status: Status
        let createdAt: Date
        let updatedAt: Date
        let reason: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case patientId = "patient_id"
            case doctorId = "doctor_id"
            case hospitalId = "hospital_id"
            case availabilitySlotId = "availability_slot_id"
            case appointmentDate = "appointment_date"
            case bookingTime = "booking_time"
            case status
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case reason
        }
    }
} 
