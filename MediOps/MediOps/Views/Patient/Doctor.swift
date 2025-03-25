import Foundation

struct DoctorDetail: Identifiable {
    let id = UUID()
    let name: String
    let specialization: String
    let qualification: String
    let experience: Int
    let rating: Double
    let numberOfRatings: Int
    let consultationFee: Double
    let isAvailableNow: Bool
    let availableSlots: [Date]
}

class DoctorViewModel: ObservableObject {
    @Published var doctors: [DoctorDetail] = []
    
    func loadDoctors(for hospital: Hospitals) {
        doctors = hospital.doctors
    }
}
