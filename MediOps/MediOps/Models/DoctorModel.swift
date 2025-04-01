import Foundation

struct DoctorModel: Identifiable, Codable {
    let id: String
    let name: String
    let specialization: String
    let experience: Int
    let qualifications: [String]
    let licenseNo: String
    let rating: Double
    let consultationFee: Double
    
    init(id: String = UUID().uuidString,
         name: String,
         specialization: String,
         experience: Int,
         qualifications: [String],
         licenseNo: String,
         rating: Double = 4.5,
         consultationFee: Double = 250.0) {
        self.id = id
        self.name = name
        self.specialization = specialization
        self.experience = experience
        self.qualifications = qualifications
        self.licenseNo = licenseNo
        self.rating = rating
        self.consultationFee = consultationFee
    }
} 
