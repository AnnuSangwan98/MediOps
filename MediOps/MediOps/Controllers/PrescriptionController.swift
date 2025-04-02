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
        prescription = nil // Reset prescription
        
        do {
            // 1. Fetch prescription
            print("🔍 Fetching prescription for appointment: \(appointmentId)")
            let prescriptionResults = try await supabase.select(
                from: "prescriptions",
                where: "appointment_id",
                equals: appointmentId
            )
            
            print("📋 Found \(prescriptionResults.count) prescriptions")
            
            if let prescriptionData = prescriptionResults.first {
                print("✅ Found prescription data: \(prescriptionData)")
                
                // Manual mapping to ensure all fields are properly handled
                let prescription = Prescription(
                    id: prescriptionData["id"] as? String ?? UUID().uuidString,
                    appointmentId: prescriptionData["appointment_id"] as? String ?? appointmentId,
                    doctorId: prescriptionData["doctor_id"] as? String ?? doctorId,
                    patientId: prescriptionData["patient_id"] as? String ?? "",
                    prescriptionDate: prescriptionData["prescription_date"] as? String ?? "",
                    medications: prescriptionData["medications"] as? [String: String] ?? [:],
                    labTests: prescriptionData["lab_tests"] as? [String: String],
                    precautions: prescriptionData["precautions"] as? String,
                    previousPrescriptionURL: prescriptionData["previous_prescription_url"] as? String,
                    labReportsURL: prescriptionData["lab_reports_url"] as? String,
                    additionalNotes: prescriptionData["additional_notes"] as? String,
                    createdAt: prescriptionData["created_at"] as? String ?? ""
                )
                
                self.prescription = prescription
                print("✅ Successfully mapped prescription data")
            } else {
                print("⚠️ No prescription found for appointment: \(appointmentId)")
            }
            
            // 2. Fetch doctor details
            print("🔍 Fetching doctor details for ID: \(doctorId)")
            let doctorResults = try await supabase.select(
                from: "doctors",
                where: "id",
                equals: doctorId
            )
            
            if let doctorData = doctorResults.first {
                print("✅ Found doctor data")
                let hospitalId = doctorData["hospital_id"] as? String ?? ""
                
                let doctor = HospitalDoctor(
                    id: doctorData["id"] as? String ?? "",
                    hospitalId: doctorData["hospital_id"] as? String ?? "",
                    name: doctorData["name"] as? String ?? "",
                    specialization: doctorData["specialization"] as? String ?? "",
                    qualifications: doctorData["qualifications"] as? [String] ?? [],
                    licenseNo: doctorData["license_no"] as? String ?? "",
                    experience: doctorData["experience"] as? Int ?? 0,
                    email: doctorData["email"] as? String ?? "",
                    contactNumber: doctorData["contact_number"] as? String,
                    doctorStatus: doctorData["doctor_status"] as? String ?? "active",
                    rating: 0.0,
                    consultationFee: 0.0
                )
                
                self.doctor = doctor
                
                // 3. Fetch hospital details
                if !hospitalId.isEmpty {
                    print("🔍 Fetching hospital details for ID: \(hospitalId)")
                    let hospitalResults = try await supabase.select(
                        from: "hospitals",
                        where: "id",
                        equals: hospitalId
                    )
                    
                    if let hospitalData = hospitalResults.first {
                        print("✅ Found hospital data")
                        let hospital = HospitalModel(
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
                            rating: 0.0
                        )
                        
                        self.hospital = hospital
                    }
                }
            }
            
        } catch {
            print("❌ Error fetching prescription details: \(error)")
            self.error = error
        }
        
        self.isLoading = false
    }
}
