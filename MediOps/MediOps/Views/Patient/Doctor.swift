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
    @Published var doctors: [DoctorDetail] = [
        DoctorDetail(
            name: "Dr. Kevon Lane",
            specialization: "Gynecologist",
            qualification: "MBBS, BCS, (Health), MCPS (Gynae & Obs), MRCOG (Gynae & Obs) (UK)",
            experience: 5,
            rating: 4.9,
            numberOfRatings: 500,
            consultationFee: 200.0,
            isAvailableNow: true,
            availableSlots: []
        )
    ]
}
