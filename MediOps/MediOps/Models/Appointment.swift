import Foundation

enum AppointmentStatus: String, Codable {
    case upcoming
    case completed
    case cancelled
    case missed
}

struct Appointment: Identifiable, Codable {
    let id: String
    let doctor: Models.Doctor
    let date: Date
    let time: Date
    var status: AppointmentStatus
    let startTime: String?
    let endTime: String?
    let isPremium: Bool?
    
    init(id: String = UUID().uuidString,
         doctor: Models.Doctor,
         date: Date,
         time: Date,
         status: AppointmentStatus = .upcoming,
         startTime: String? = nil,
         endTime: String? = nil,
         isPremium: Bool? = nil) {
        self.id = id
        self.doctor = doctor
        self.date = date
        self.time = time
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.isPremium = isPremium
    }
    
    // Custom CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case doctor
        case date
        case time
        case status
        case startTime = "slot_time"
        case endTime = "slot_end_time"
        case isPremium = "is_premium"
    }
    
    // Custom initializer from decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        doctor = try container.decode(Models.Doctor.self, forKey: .doctor)
        date = try container.decode(Date.self, forKey: .date)
        time = try container.decode(Date.self, forKey: .time)
        status = try container.decode(AppointmentStatus.self, forKey: .status)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
    }
    
    // Custom encode method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(doctor, forKey: .doctor)
        try container.encode(date, forKey: .date)
        try container.encode(time, forKey: .time)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(isPremium, forKey: .isPremium)
    }
}

// Simple Doctor model for appointments
// This helps ensure compatibility across different Doctor model versions
extension Models.Doctor {
    static func createSimplifiedDoctor(id: String, name: String, specialization: String) -> Models.Doctor {
        // Create a minimal doctor with required fields
        return Models.Doctor(
            id: id,
            userId: nil,
            name: name,
            specialization: specialization,
            hospitalId: "HOSP001",
            qualifications: [],
            licenseNo: "",
            experience: 0,
            addressLine: "",
            state: "",
            city: "",
            pincode: "",
            email: "",
            contactNumber: nil,
            emergencyContactNumber: nil,
            doctorStatus: "active",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
} 