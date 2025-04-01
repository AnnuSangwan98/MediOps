import Foundation
import SwiftUI

// Local Doctor model that includes rating and consultationFee
struct LocalDoctor: Identifiable, Codable {
    let id: String
    let hospitalId: String
    let name: String
    let specialization: String
    let qualifications: [String]
    let licenseNo: String
    let experience: Int
    let email: String
    let contactNumber: String?
    let doctorStatus: String
    let rating: Double
    let consultationFee: Double
    
    // Convert this LocalDoctor to Models.Doctor for use in appointments
    func toModelDoctor() -> Models.Doctor {
        return Models.Doctor(
            id: id,
            userId: nil,
            name: name,
            specialization: specialization,
            hospitalId: hospitalId,
            qualifications: qualifications,
            licenseNo: licenseNo,
            experience: experience,
            addressLine: "",
            state: "",
            city: "",
            pincode: "",
            email: email,
            contactNumber: contactNumber,
            emergencyContactNumber: nil,
            doctorStatus: doctorStatus,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

@MainActor
class DoctorViewModel: ObservableObject {
    @Published var doctors: [LocalDoctor] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseController.shared
    
    func loadDoctors(for hospital: HospitalModel) async {
        isLoading = true
        print("Loading doctors for hospital: \(hospital.id)")
        
        do {
            // Only fetch doctors for the specific hospital
            let results = try await supabase.select(
                from: "doctors",
                where: "hospital_id",
                equals: hospital.id
            )
            
            print("Query returned \(results.count) doctors")
            
            self.doctors = results.compactMap { data in
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let specialization = data["specialization"] as? String,
                      let experience = data["experience"] as? Int
                else {
                    print("Failed to parse required doctor data: \(data)")
                    return nil
                }
                
                let hospitalId = data["hospital_id"] as? String ?? hospital.id
                let qualifications = data["qualifications"] as? [String] ?? []
                let licenseNo = data["license_no"] as? String ?? "N/A"
                let email = data["email"] as? String ?? ""
                let status = data["doctor_status"] as? String ?? "active"
                let rating = data["rating"] as? Double ?? 4.5
                let consultationFee = data["consultation_fee"] as? Double ?? 500.0
                
                return LocalDoctor(
                    id: id,
                    hospitalId: hospitalId,
                    name: name,
                    specialization: specialization,
                    qualifications: qualifications,
                    licenseNo: licenseNo,
                    experience: experience,
                    email: email,
                    contactNumber: data["contact_number"] as? String,
                    doctorStatus: status,
                    rating: rating,
                    consultationFee: consultationFee
                )
            }
            
            print("Successfully parsed \(self.doctors.count) doctors")
            isLoading = false
        } catch {
            print("Error fetching doctors: \(error)")
            isLoading = false
        }
    }
}

struct DoctorView: View {
    let doctor: HospitalDoctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(doctor.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(doctor.specialization)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.teal)
                Text("\(doctor.experience) years experience")
                    .font(.subheadline)
            }
            
            Text("Qualifications:")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(doctor.qualifications.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let contact = doctor.contactNumber {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.teal)
                    Text(contact)
                        .font(.subheadline)
                }
            }
            
            Text("License No: \(doctor.licenseNo)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
