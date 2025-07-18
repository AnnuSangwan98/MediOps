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
    let addressLine: String
    let state: String
    let city: String
    let pincode: String
    let email: String
    let contactNumber: String?
    let emergencyContactNumber: String?
    let doctorStatus: String
    let createdAt: Date?
    let updatedAt: Date?
    let isFirstTimeLogin: Bool
    let rating: Double // This is not in the database but useful for UI
    let consultationFee: Double // This is not in the database but useful for UI
    let maxAppointments: Int
    
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
            addressLine: addressLine,
            state: state,
            city: city,
            pincode: pincode,
            email: email,
            contactNumber: contactNumber,
            emergencyContactNumber: emergencyContactNumber,
            doctorStatus: doctorStatus,
            dateOfBirth: nil,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            maxAppointments: maxAppointments
        )
    }
}

@MainActor
class DoctorViewModel: ObservableObject {
    @Published var doctors: [LocalDoctor] = []
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    private let supabase = SupabaseController.shared
    
    func loadDoctors(for hospital: HospitalModel) async {
        isLoading = true
        doctors = [] // Clear previous data
        error = nil
        
        do {
            // Use standard select query instead of SQL execution
            let results = try await supabase.select(
                from: "doctors",
                where: "hospital_id",
                equals: hospital.id
            )
            
            // Filter active doctors client-side
            let activeResults = results.filter { 
                ($0["doctor_status"] as? String) == "active" 
            }
            
            // If no doctors found, just return empty array
            if activeResults.isEmpty {
                await MainActor.run {
                    self.doctors = []
                    self.isLoading = false
                }
                return
            }
            
            let parsedDoctors = activeResults.compactMap { data -> LocalDoctor? in
                do {
                    guard let id = data["id"] as? String,
                          let name = data["name"] as? String,
                          let specialization = data["specialization"] as? String,
                          let hospitalId = data["hospital_id"] as? String,
                          let experience = data["experience"] as? Int else {
                        return nil
                    }
                    
                    // Handle arrays properly - qualifications might come as a JSON array
                    var qualifications: [String] = []
                    if let qualArray = data["qualifications"] as? [String] {
                        qualifications = qualArray
                    } else if let qualString = data["qualifications"] as? String {
                        // Try to parse as JSON if it's a string
                        if qualString.hasPrefix("[") && qualString.hasSuffix("]") {
                            let jsonData = qualString.data(using: .utf8) ?? Data()
                            if let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
                                qualifications = parsed
                            }
                        }
                    }
                    
                    // If we still don't have qualifications, use default values
                    if qualifications.isEmpty {
                        qualifications = ["MBBS"]
                    }
                    
                    // Format date strings
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime]
                    
                    var createdAt: Date? = nil
                    if let createdString = data["created_at"] as? String {
                        createdAt = dateFormatter.date(from: createdString) ?? Date()
                    }
                    
                    var updatedAt: Date? = nil
                    if let updatedString = data["updated_at"] as? String {
                        updatedAt = dateFormatter.date(from: updatedString) ?? Date()
                    }
                    
                    // Parse max appointments with fallback
                    let maxAppointments: Int
                    if let max = data["max_appointments"] as? Int {
                        maxAppointments = max
                    } else if let maxString = data["max_appointments"] as? String, let max = Int(maxString) {
                        maxAppointments = max
                    } else {
                        maxAppointments = 8 // Default value if not found
                    }
                    
                    // Use model defaults for optional fields
                    let doctor = LocalDoctor(
                        id: id,
                        hospitalId: hospitalId,
                        name: name,
                        specialization: specialization,
                        qualifications: qualifications,
                        licenseNo: data["license_no"] as? String ?? "XX00000",
                        experience: experience,
                        addressLine: data["address_line"] as? String ?? "",
                        state: data["state"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        pincode: data["pincode"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        contactNumber: data["contact_number"] as? String,
                        emergencyContactNumber: data["emergency_contact_number"] as? String,
                        doctorStatus: data["doctor_status"] as? String ?? "active",
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        isFirstTimeLogin: data["is_first_time_login"] as? Bool ?? true,
                        rating: 4.5, // Default rating since not in DB
                        consultationFee: 500.0, // Default fee since not in DB
                        maxAppointments: maxAppointments
                    )
                    
                    return doctor
                } catch {
                    return nil
                }
            }
            
            await MainActor.run {
                self.doctors = parsedDoctors
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
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