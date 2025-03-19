import Foundation

struct Hospital: Identifiable {
    let id = UUID()
    let name: String
    let city: String
    let address: String
    let specialties: [String]
    let rating: Double
    let numberOfDoctors: Int
}

class HospitalViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = [
        Hospital(name: "City General Hospital", city: "New York", address: "123 Medical Ave", specialties: ["Cardiology", "Neurology"], rating: 4.5, numberOfDoctors: 50),
        Hospital(name: "Central Medical Center", city: "Los Angeles", address: "456 Health St", specialties: ["Oncology", "Pediatrics"], rating: 4.3, numberOfDoctors: 40),
        Hospital(name: "Apollo Hospital", city: "Mumbai", address: "789 Wellness Rd", specialties: ["Orthopedics", "Gynecology"], rating: 4.7, numberOfDoctors: 60),
        Hospital(name: "Kaira Hospital", city: "Pune", address: "101 Wellness Rd", specialties: ["Cardiology", "Orthopedics"], rating: 4.6, numberOfDoctors: 55),
        Hospital(name: "Kailash Hospital", city: "Pune", address: "102 Wellness Rd", specialties: ["Cardiology", "Orthopedics"], rating: 4.6, numberOfDoctors: 55)
        // Add more sample data as needed
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
