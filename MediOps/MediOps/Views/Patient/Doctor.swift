import Foundation
import SwiftUI

@MainActor
class DoctorViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseController.shared
    
    func loadDoctors(for hospital: HospitalModel) async {
        isLoading = true
        print("Loading doctors for hospital: \(hospital.id)")
        
        do {
            // First try to fetch using hospital_id
            var results = try await supabase.select(
                from: "doctors",
                where: "hospital_id",
                equals: hospital.id
            )
            
            print("Initial query returned \(results.count) doctors")
            
            // If no results, try without the where clause to see all doctors
            if results.isEmpty {
                print("No doctors found with hospital_id, fetching all doctors")
                results = try await supabase.select(from: "doctors")
                print("Found \(results.count) total doctors")
            }
            
            self.doctors = results.compactMap { data in
                do {
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let specialization = data["specialization"] as? String,
                          let experience = data["experience"] as? Int
                    else {
                        print("Failed to parse required doctor data: \(data)")
                        return nil
                    }
                    
                    // Optional fields with default values
                    let hospitalId = data["hospital_id"] as? String ?? hospital.id
                    let qualifications = data["qualifications"] as? [String] ?? []
                    let licenseNo = data["license_no"] as? String ?? "N/A"
                    let email = data["email"] as? String ?? ""
                    let status = data["doctor_status"] as? String ?? "active"
                    let rating = data["rating"] as? Double ?? 4.5
                    let consultationFee = data["consultation_fee"] as? Double ?? 500.0
                    
                    return Doctor(
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
                } catch {
                    print("Error parsing doctor data: \(error)")
                    return nil
                }
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
    let doctor: Doctor
    
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