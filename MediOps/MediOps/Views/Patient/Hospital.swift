import Foundation

struct Hospital: Identifiable {
    let id = UUID()
    let name: String
    let city: String
    let address: String
    let specialties: [String]
    let rating: Double
    let numberOfDoctors: Int
    let doctors: [DoctorDetail]
}

class HospitalViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = [
        Hospital(
            name: "City General Hospital",
            city: "New York",
            address: "123 Medical Ave",
            specialties: ["Cardiology", "Neurology"],
            rating: 4.5,
            numberOfDoctors: 50,
            doctors: [
                DoctorDetail(
                    name: "Dr. John Smith",
                    specialization: "Cardiologist",
                    qualification: "MD, FACC",
                    experience: 15,
                    rating: 4.8,
                    numberOfRatings: 300,
                    consultationFee: 250.0,
                    isAvailableNow: true,
                    availableSlots: []
                ),
                DoctorDetail(
                    name: "Dr. Sarah Johnson",
                    specialization: "Neurologist",
                    qualification: "MD, PhD",
                    experience: 12,
                    rating: 4.7,
                    numberOfRatings: 250,
                    consultationFee: 220.0,
                    isAvailableNow: false,
                    availableSlots: []
                )
            ]
        ),
        Hospital(
            name: "Central Medical Center",
            city: "Los Angeles",
            address: "456 Health St",
            specialties: ["Oncology", "Pediatrics"],
            rating: 4.3,
            numberOfDoctors: 40,
            doctors: [
                DoctorDetail(
                    name: "Dr. Michael Chen",
                    specialization: "Oncologist",
                    qualification: "MD, PhD",
                    experience: 18,
                    rating: 4.9,
                    numberOfRatings: 400,
                    consultationFee: 280.0,
                    isAvailableNow: true,
                    availableSlots: []
                ),
                DoctorDetail(
                    name: "Dr. Emily Brown",
                    specialization: "Pediatrician",
                    qualification: "MD, FAAP",
                    experience: 10,
                    rating: 4.6,
                    numberOfRatings: 350,
                    consultationFee: 180.0,
                    isAvailableNow: true,
                    availableSlots: []
                )
            ]
        ),
        Hospital(
            name: "Apollo Hospital",
            city: "Mumbai",
            address: "789 Wellness Rd",
            specialties: ["Orthopedics", "Gynecology"],
            rating: 4.7,
            numberOfDoctors: 60,
            doctors: [
                DoctorDetail(
                    name: "Dr. Rajesh Kumar",
                    specialization: "Orthopedic Surgeon",
                    qualification: "MS (Ortho), DNB",
                    experience: 20,
                    rating: 4.8,
                    numberOfRatings: 450,
                    consultationFee: 200.0,
                    isAvailableNow: true,
                    availableSlots: []
                ),
                DoctorDetail(
                    name: "Dr. Priya Sharma",
                    specialization: "Gynecologist",
                    qualification: "MD, DGO",
                    experience: 15,
                    rating: 4.7,
                    numberOfRatings: 380,
                    consultationFee: 180.0,
                    isAvailableNow: false,
                    availableSlots: []
                )
            ]
        ),
        Hospital(
            name: "Kaira Hospital",
            city: "Pune",
            address: "101 Wellness Rd",
            specialties: ["Cardiology", "Orthopedics"],
            rating: 4.6,
            numberOfDoctors: 55,
            doctors: [
                DoctorDetail(
                    name: "Dr. Amit Patel",
                    specialization: "Cardiologist",
                    qualification: "DM (Cardiology)",
                    experience: 16,
                    rating: 4.8,
                    numberOfRatings: 320,
                    consultationFee: 220.0,
                    isAvailableNow: true,
                    availableSlots: []
                ),
                DoctorDetail(
                    name: "Dr. Neha Gupta",
                    specialization: "Orthopedic Surgeon",
                    qualification: "MS (Ortho)",
                    experience: 12,
                    rating: 4.6,
                    numberOfRatings: 280,
                    consultationFee: 190.0,
                    isAvailableNow: true,
                    availableSlots: []
                )
            ]
        ),
        Hospital(
            name: "Kailash Hospital",
            city: "Pune",
            address: "102 Wellness Rd",
            specialties: ["Cardiology", "Orthopedics"],
            rating: 4.6,
            numberOfDoctors: 55,
            doctors: [
                DoctorDetail(
                    name: "Dr. Vikram Singh",
                    specialization: "Cardiologist",
                    qualification: "DM (Cardiology)",
                    experience: 14,
                    rating: 4.7,
                    numberOfRatings: 290,
                    consultationFee: 210.0,
                    isAvailableNow: false,
                    availableSlots: []
                ),
                DoctorDetail(
                    name: "Dr. Anjali Desai",
                    specialization: "Orthopedic Surgeon",
                    qualification: "MS (Ortho)",
                    experience: 11,
                    rating: 4.5,
                    numberOfRatings: 260,
                    consultationFee: 180.0,
                    isAvailableNow: true,
                    availableSlots: []
                )
            ]
        )
    ]
    
    @Published var searchText = ""
    @Published var selectedCity: String? = nil
    
    var filteredHospitals: [Hospital] {
        // Only filter hospitals if there's a search query
        guard !searchText.isEmpty else { return [] }
        
        var result = hospitals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        
        if let selectedCity = selectedCity {
            result = result.filter { $0.city == selectedCity }
        }
        
        return result
    }
    
    var availableCities: [String] {
        Array(Set(hospitals.map { $0.city })).sorted()
    }
}
