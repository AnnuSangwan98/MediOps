import Foundation
import SwiftUI

// MARK: - Models
struct HospitalModel: Identifiable, Codable, Hashable {
    let id: String
    let hospitalName: String
    let hospitalAddress: String
    let hospitalState: String
    let hospitalCity: String
    let areaPincode: String
    let email: String
    let contactNumber: String
    let emergencyContactNumber: String
    let licence: String
    let hospitalAccreditation: String
    let type: String
    let hospitalProfileImage: String?
    let coverImage: String?
    let status: String
    let departments: [String]
    let numberOfDoctors: Int
    let numberOfAppointments: Int
    let description: String?
    let rating: Double
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HospitalModel, rhs: HospitalModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct Doctor: Identifiable, Codable, Hashable {
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
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Doctor, rhs: Doctor) -> Bool {
        lhs.id == rhs.id
    }
}

struct DoctorAvailability: Identifiable, Codable, Hashable {
    let id: Int
    let doctorId: String
    let date: Date
    let slotTime: Date
    let slotEndTime: Date
    let maxNormalPatients: Int
    let maxPremiumPatients: Int
    let totalBookings: Int
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DoctorAvailability, rhs: DoctorAvailability) -> Bool {
        lhs.id == rhs.id
    }
}

// Add this new struct for appointment data
struct AppointmentData: Codable {
    let id: String
    let patientId: String
    let doctorId: String
    let hospitalId: String
    let availabilitySlotId: String
    let appointmentDate: String
    let appointmentTime: String
    let status: String
    let doctorName: String
    let doctorSpecialization: String
    let hospitalName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case doctorId = "doctor_id"
        case hospitalId = "hospital_id"
        case availabilitySlotId = "availability_slot_id"
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case status
        case doctorName = "doctor_name"
        case doctorSpecialization = "doctor_specialization"
        case hospitalName = "hospital_name"
    }
}

@MainActor
class HospitalViewModel: ObservableObject {
    static let shared = HospitalViewModel()
    
    @Published var hospitals: [HospitalModel] = []
    @Published var searchText = ""
    @Published var selectedCity: String? = nil
    @Published var selectedHospital: HospitalModel? = nil
    @Published var selectedSpecialization: String? = nil
    @Published var doctors: [Doctor] = []
    @Published var selectedDoctor: Doctor? = nil
    @Published var availableSlots: [DoctorAvailability] = []
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    private let supabase = SupabaseController.shared
    
    private init() {} // Make initializer private for singleton
    
    // MARK: - Hospital Methods
    
    /// Fetch hospitals based on search text and selected city
    func fetchHospitals() async {
        isLoading = true
        error = nil
        
        do {
            // Construct the SQL query with proper escaping
            var conditions = ["status = 'active'"]
            
            if !searchText.isEmpty {
                let escapedSearch = searchText.replacingOccurrences(of: "'", with: "''")
                conditions.append("hospital_name ilike '%\(escapedSearch)%'")
            }
            
            if let city = selectedCity {
                let escapedCity = city.replacingOccurrences(of: "'", with: "''")
                conditions.append("hospital_city = '\(escapedCity)'")
            }
            
            let query = "select * from hospitals where \(conditions.joined(separator: " and "))"
            print("SUPABASE QUERY: \(query)") // Debug log
            
            let results = try await supabase.select(from: "hospitals")
            print("SUPABASE RESULTS: \(results.count) hospitals found") // Debug log
            
            self.hospitals = results.compactMap { data in
                guard let id = data["id"] as? String,
                      let name = data["hospital_name"] as? String,
                      let address = data["hospital_address"] as? String,
                      let state = data["hospital_state"] as? String,
                      let city = data["hospital_city"] as? String,
                      let pincode = data["area_pincode"] as? String,
                      let email = data["email"] as? String,
                      let contact = data["contact_number"] as? String,
                      let emergency = data["emergency_contact_number"] as? String,
                      let licence = data["licence"] as? String,
                      let accreditation = data["hospital_accreditation"] as? String,
                      let type = data["type"] as? String,
                      let status = data["status"] as? String,
                      let departments = data["departments"] as? [String],
                      let numDoctors = data["number_of_doctors"] as? Int,
                      let numAppointments = data["number_of_appointments"] as? Int
                else { 
                    print("Failed to parse hospital data: \(data)") // Debug log
                    return nil 
                }
                
                return HospitalModel(
                    id: id,
                    hospitalName: name,
                    hospitalAddress: address,
                    hospitalState: state,
                    hospitalCity: city,
                    areaPincode: pincode,
                    email: email,
                    contactNumber: contact,
                    emergencyContactNumber: emergency,
                    licence: licence,
                    hospitalAccreditation: accreditation,
                    type: type,
                    hospitalProfileImage: data["hospital_profile_image"] as? String,
                    coverImage: data["cover_image"] as? String,
                    status: status,
                    departments: departments,
                    numberOfDoctors: numDoctors,
                    numberOfAppointments: numAppointments,
                    description: data["description"] as? String,
                    rating: data["rating"] as? Double ?? 0.0
                )
            }
            
            print("VIEWMODEL: Parsed \(self.hospitals.count) hospitals") // Debug log
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Error fetching hospitals: \(error)")
        }
    }
    
    /// Fetch available cities from hospitals
    func fetchAvailableCities() async {
        do {
            let results = try await supabase.select(from: "hospitals", columns: "DISTINCT hospital_city")
            self.availableCities = results.compactMap { $0["hospital_city"] as? String }.sorted()
        } catch {
            print("Error fetching cities: \(error)")
        }
    }
    
    // MARK: - Doctor Methods
    
    /// Fetch doctors for selected hospital and specialization
    func fetchDoctors() async {
        guard let hospital = selectedHospital else { return }
        
        isLoading = true
        error = nil
        
        do {
            let results = try await supabase.select(
                from: "doctors",
                where: "hospital_id",
                equals: hospital.id
            )
            
            self.doctors = results.compactMap { data in
                guard let id = data["id"] as? String,
                      let hospitalId = data["hospital_id"] as? String,
                      let name = data["name"] as? String,
                      let specialization = data["specialization"] as? String,
                      let qualifications = data["qualifications"] as? [String],
                      let licenseNo = data["license_no"] as? String,
                      let experience = data["experience"] as? Int,
                      let email = data["email"] as? String,
                      let status = data["doctor_status"] as? String,
                      let rating = data["rating"] as? Double,
                      let consultationFee = data["consultation_fee"] as? Double
                else { return nil }
                
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
            }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Error fetching doctors: \(error)")
        }
    }
    
    /// Fetch available slots for selected doctor
    func fetchAvailableSlots(for date: Date) async {
        guard let doctor = selectedDoctor else { return }
        
        isLoading = true
        error = nil
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            let results = try await supabase.select(
                from: "doctor_availability",
                where: "doctor_id",
                equals: doctor.id
            )
            
            self.availableSlots = results.compactMap { data in
                guard let id = data["id"] as? Int,
                      let doctorId = data["doctor_id"] as? String,
                      let date = dateFormatter.date(from: data["date"] as? String ?? ""),
                      let slotTime = data["slot_time"] as? Date,
                      let slotEndTime = data["slot_end_time"] as? Date,
                      let maxNormal = data["max_normal_patients"] as? Int,
                      let maxPremium = data["max_premium_patients"] as? Int,
                      let totalBookings = data["total_bookings"] as? Int
                else { return nil }
                
                return DoctorAvailability(
                    id: id,
                    doctorId: doctorId,
                    date: date,
                    slotTime: slotTime,
                    slotEndTime: slotEndTime,
                    maxNormalPatients: maxNormal,
                    maxPremiumPatients: maxPremium,
                    totalBookings: totalBookings
                )
            }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Error fetching available slots: \(error)")
        }
    }
    
    // MARK: - Appointment Methods
    
    /// Book an appointment
    func bookAppointment(patientId: String, slotId: Int, date: Date, time: Date) async throws {
        guard let doctor = selectedDoctor,
              let hospital = selectedHospital else { 
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No doctor or hospital selected"])
        }
        
        let appointmentId = UUID().uuidString
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        let appointmentData = AppointmentData(
            id: appointmentId,
            patientId: patientId,
            doctorId: doctor.id,
            hospitalId: hospital.id,
            availabilitySlotId: String(slotId),
            appointmentDate: dateFormatter.string(from: date),
            appointmentTime: timeFormatter.string(from: time),
            status: "upcoming",
            doctorName: doctor.name,
            doctorSpecialization: doctor.specialization,
            hospitalName: hospital.hospitalName
        )
        
        do {
            try await supabase.insert(into: "appointments", data: appointmentData)
            print("Successfully booked appointment with ID: \(appointmentId)")
            
            // Update the appointments list after booking
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                try await fetchAppointments(for: userId)
            }
        } catch {
            print("Error booking appointment: \(error)")
            throw error
        }
    }
    
    /// Fetch appointments for a patient
    func fetchAppointments(for patientId: String) async throws {
        do {
            print("Fetching appointments for patient: \(patientId)")
            let results = try await supabase.select(
                from: "appointments",
                where: "patient_id",
                equals: patientId
            )
            print("Found \(results.count) appointments")
            
            let appointments = results.compactMap { data -> Appointment? in
                guard let id = data["id"] as? String,
                      let doctorId = data["doctor_id"] as? String,
                      let doctorName = data["doctor_name"] as? String,
                      let doctorSpecialization = data["doctor_specialization"] as? String,
                      let dateString = data["appointment_date"] as? String,
                      let timeString = data["appointment_time"] as? String,
                      let status = data["status"] as? String else {
                    print("Failed to parse appointment data: \(data)")
                    return nil
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                guard let date = dateFormatter.date(from: dateString) else {
                    print("Failed to parse date: \(dateString)")
                    return nil 
                }
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                guard let time = timeFormatter.date(from: timeString) else {
                    print("Failed to parse time: \(timeString)")
                    return nil 
                }
                
                let doctor = Doctor(
                    id: doctorId,
                    hospitalId: data["hospital_id"] as? String ?? "",
                    name: doctorName,
                    specialization: doctorSpecialization,
                    qualifications: [],
                    licenseNo: "",
                    experience: 0,
                    email: "",
                    contactNumber: nil,
                    doctorStatus: "active",
                    rating: 0.0,
                    consultationFee: 0.0
                )
                
                return Appointment(
                    doctor: doctor,
                    date: date,
                    time: time,
                    status: Appointment.AppointmentStatus(rawValue: status) ?? .upcoming
                )
            }
            
            await MainActor.run {
                AppointmentManager.shared.appointments = appointments
            }
        } catch {
            print("Error fetching appointments: \(error)")
            throw error
        }
    }
    
    var availableCities: [String] = []
    
    var filteredHospitals: [HospitalModel] {
        if searchText.isEmpty {
            return hospitals
        }
        return hospitals.filter { hospital in
            let nameMatch = hospital.hospitalName.localizedCaseInsensitiveContains(searchText)
            let cityMatch = selectedCity == nil || hospital.hospitalCity == selectedCity
            return nameMatch && cityMatch
        }
    }
}
