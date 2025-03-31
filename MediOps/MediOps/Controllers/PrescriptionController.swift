import Foundation
import Supabase

class PrescriptionController: ObservableObject {
    @Published var prescription: Prescription?
    @Published var doctor: HospitalDoctor?
    @Published var hospital: HospitalModel?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase = SupabaseController.shared
    
    @MainActor
    func fetchPrescriptionDetails(for appointmentId: String, doctorId: String) async {
        isLoading = true
        error = nil
        
        print("🔍 DEBUG: Fetching prescription for appointmentId: \(appointmentId)")
        
        do {
            // 1. First fetch prescription
            let prescriptionResults = try await supabase.select(
                from: "prescriptions",
                where: "appointment_id",
                equals: appointmentId
            )
            
            if let prescriptionData = prescriptionResults.first {
                print("✅ Found prescription data")
                let jsonData = try JSONSerialization.data(withJSONObject: prescriptionData)
                self.prescription = try JSONDecoder().decode(Prescription.self, from: jsonData)
                
                // 2. Get doctor ID from prescription and fetch doctor details
                if let doctorId = prescriptionData["doctor_id"] as? String {
                    print("🔍 Fetching doctor details for ID: \(doctorId)")
                    let doctorResults = try await supabase.select(
                        from: "doctors",
                        where: "id",
                        equals: doctorId
                    )
                    
                    if let doctorData = doctorResults.first {
                        print("✅ Found doctor data")
                        let hospitalId = doctorData["hospital_id"] as? String ?? ""
                        
                        // Create HospitalDoctor
                        self.doctor = HospitalDoctor(
                            id: doctorData["id"] as? String ?? "",
                            hospitalId: hospitalId,
                            name: doctorData["name"] as? String ?? "",
                            specialization: doctorData["specialization"] as? String ?? "",
                            qualifications: doctorData["qualifications"] as? [String] ?? [],
                            licenseNo: doctorData["license_no"] as? String ?? "",
                            experience: doctorData["experience"] as? Int ?? 0,
                            email: doctorData["email"] as? String ?? "",
                            contactNumber: doctorData["contact_number"] as? String,
                            doctorStatus: doctorData["doctor_status"] as? String ?? "active",
                            rating: doctorData["rating"] as? Double ?? 4.0,
                            consultationFee: doctorData["consultation_fee"] as? Double ?? 0.0
                        )
                        
                        // 3. Use hospital ID from doctor to fetch hospital details
                        if !hospitalId.isEmpty {
                            print("🔍 Fetching hospital details for ID: \(hospitalId)")
                            let hospitalResults = try await supabase.select(
                                from: "hospitals",
                                where: "id",
                                equals: hospitalId
                            )
                            
                            if let hospitalData = hospitalResults.first {
                                print("✅ Found hospital data")
                                self.hospital = HospitalModel(
                                    id: hospitalData["id"] as? String ?? "",
                                    hospitalName: hospitalData["hospital_name"] as? String ?? "",
                                    hospitalAddress: hospitalData["hospital_address"] as? String ?? "",
                                    hospitalState: hospitalData["hospital_state"] as? String ?? "",
                                    hospitalCity: hospitalData["hospital_city"] as? String ?? "",
                                    areaPincode: hospitalData["area_pincode"] as? String ?? "",
                                    email: hospitalData["email"] as? String ?? "",
                                    contactNumber: hospitalData["contact_number"] as? String ?? "",
                                    emergencyContactNumber: hospitalData["emergency_contact_number"] as? String ?? "",
                                    licence: hospitalData["licence"] as? String ?? "",
                                    hospitalAccreditation: hospitalData["hospital_accreditation"] as? String ?? "",
                                    type: hospitalData["type"] as? String ?? "",
                                    hospitalProfileImage: hospitalData["hospital_profile_image"] as? String,
                                    coverImage: hospitalData["cover_image"] as? String,
                                    status: hospitalData["status"] as? String ?? "active",
                                    departments: hospitalData["departments"] as? [String] ?? [],
                                    numberOfDoctors: hospitalData["number_of_doctors"] as? Int ?? 0,
                                    numberOfAppointments: hospitalData["number_of_appointments"] as? Int ?? 0,
                                    description: hospitalData["description"] as? String,
                                    rating: hospitalData["rating"] as? Double ?? 0.0
                                )
                            }
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Error fetching details: \(error.localizedDescription)")
            self.error = error
        }
        
        self.isLoading = false
    }
}
