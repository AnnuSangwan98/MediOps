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

struct HospitalDoctor: Identifiable, Codable, Hashable {
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
    
    static func == (lhs: HospitalDoctor, rhs: HospitalDoctor) -> Bool {
        lhs.id == rhs.id
    }
}

// Add this new struct for appointment data
struct AppointmentData: Codable {
    let id: String
    let patient_id: String
    let doctor_id: String
    let hospital_id: String
    let availability_slot_id: Int
    let appointment_date: String
    let booking_time: String?
    let status: String
    let created_at: String?
    let updated_at: String?
    let reason: String
}

@MainActor
class HospitalViewModel: ObservableObject {
    static let shared = HospitalViewModel()
    
    @Published var hospitals: [HospitalModel] = []
    @Published var searchText = ""
    @Published var selectedCity: String? = nil
    @Published var selectedHospital: HospitalModel? = nil
    @Published var selectedSpecialization: String? = nil
    @Published var doctors: [HospitalDoctor] = []
    @Published var selectedDoctor: HospitalDoctor? = nil
    @Published var availableSlots: [AppointmentModels.DoctorAvailability] = []
    @Published var isLoading = false
    @Published var error: Error? = nil
    
    private let supabase = SupabaseController.shared
    
    private init() {
        print("🏥 HospitalViewModel initialized")
        // Load user data if available
        if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
            print("🔍 HospitalViewModel init with user ID: \(userId)")
            Task {
                do {
                    try await fetchAppointments(for: userId)
                } catch {
                    print("❌ Error loading initial appointments: \(error)")
                }
            }
        } else {
            print("⚠️ No user ID found during HospitalViewModel initialization")
        }
    } // Make initializer private for singleton
    
    // MARK: - Hospital Methods
    
    /// Fetch hospitals based on search text and selected city
    func fetchHospitals() async {
        isLoading = true
        error = nil
        
        do {
            print("🏥 HospitalViewModel: Starting hospital fetch")
            
            // Use direct custom SQL query to ensure filters are applied properly
            let queryTable = "hospitals"
            let queryEndpoint = "\(supabase.supabaseURL)/rest/v1/rpc/execute_sql"
            
            var queryParams: [String] = []
            // Always include active hospitals
            queryParams.append("status = 'active'")
            
            if !searchText.isEmpty {
                let escapedSearch = searchText.replacingOccurrences(of: "'", with: "''")
                queryParams.append("hospital_name ilike '%\(escapedSearch)%'")
            }
            
            if let city = selectedCity, !city.isEmpty {
                let escapedCity = city.replacingOccurrences(of: "'", with: "''")
                queryParams.append("hospital_city = '\(escapedCity)'")
            }
            
            // Try first with a direct table select (without SQL function)
            print("🏥 Attempting direct table fetch from \(queryTable)")
            var results: [[String: Any]] = []
            
            do {
                results = try await supabase.select(from: queryTable)
                print("🏥 Direct fetch successful! Found \(results.count) hospitals")
            } catch {
                print("⚠️ Direct fetch failed: \(error.localizedDescription)")
                print("🔄 Attempting backup fetch method...")
                
                // If simple fetch fails, try with an HTTP request directly
                let url = URL(string: "\(supabase.supabaseURL)/rest/v1/hospitals?select=*")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("🌐 Response status: \(httpResponse.statusCode)")
                        
                        if httpResponse.statusCode == 200 {
                            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                                results = jsonArray
                                print("✅ Backup fetch successful! Found \(results.count) hospitals")
                            } else {
                                print("❌ Failed to parse JSON from backup fetch")
                                if let responseString = String(data: data, encoding: .utf8) {
                                    print("Response data: \(responseString)")
                                }
                            }
                        } else {
                            print("❌ Backup fetch failed with status \(httpResponse.statusCode)")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("Error response: \(responseString)")
                            }
                        }
                    }
                } catch {
                    print("❌ Backup fetch failed with error: \(error.localizedDescription)")
                }
            }
            
            // Filter results client-side based on our conditions
            if !results.isEmpty {
                results = results.filter { data in
                    guard let status = data["status"] as? String else { return false }
                    
                    // Must be active
                    guard status == "active" else { return false }
                    
                    // Filter by search text if provided
                    if !searchText.isEmpty {
                        guard let name = data["hospital_name"] as? String,
                              name.lowercased().contains(searchText.lowercased()) else {
                            return false
                        }
                    }
                    
                    // Filter by city if provided
                    if let city = selectedCity, !city.isEmpty {
                        guard let hospitalCity = data["hospital_city"] as? String,
                              hospitalCity == city else {
                            return false
                        }
                    }
                    
                    return true
                }
            }
            
            // Convert to HospitalModel objects
            var hospitalModels: [HospitalModel] = []
            
            for data in results {
                do {
                    guard let id = data["id"] as? String,
                          let name = data["hospital_name"] as? String
                    else { 
                        print("⚠️ Missing required hospital data fields (id/name): \(data)")
                        continue
                    }
                    
                    // Handle optional or missing fields with defaults
                    let address = data["hospital_address"] as? String ?? "Address not provided"
                    let state = data["hospital_state"] as? String ?? "State not provided"
                    let city = data["hospital_city"] as? String ?? "City not provided"
                    let pincode = data["area_pincode"] as? String ?? "Pincode not provided"
                    let email = data["email"] as? String ?? "Email not provided"
                    let contact = data["contact_number"] as? String ?? "Contact not provided"
                    let emergency = data["emergency_contact_number"] as? String ?? "Emergency contact not provided"
                    let licence = data["licence"] as? String ?? "License not provided"
                    let accreditation = data["hospital_accreditation"] as? String ?? "Accreditation not provided"
                    let type = data["type"] as? String ?? "Type not provided"
                    let status = data["status"] as? String ?? "active"
                    let departments = data["departments"] as? [String] ?? []
                    let numAppointments = data["number_of_appointments"] as? Int ?? 0
                    
                    // Try to fetch doctor count, but continue if it fails
                    var numDoctors = 0
                    do {
                        let doctorResults = try await supabase.select(
                            from: "doctors",
                            where: "hospital_id",
                            equals: id
                        )
                        numDoctors = doctorResults.count
                    } catch {
                        print("⚠️ Failed to fetch doctors for hospital \(name): \(error.localizedDescription)")
                    }
                    
                    let hospital = HospitalModel(
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
                    
                    hospitalModels.append(hospital)
                    print("✅ Added hospital: \(name)")
                } catch {
                    print("❌ Error parsing hospital: \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.hospitals = hospitalModels
                self.isLoading = false
                print("🏥 VIEWMODEL: Updated with \(self.hospitals.count) hospitals")
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                print("❌ Error fetching hospitals: \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetch available cities from hospitals
    func fetchAvailableCities() async {
        do {
            // Correct SQL query for distinct values
            let results = try await supabase.select(from: "hospitals")
            
            // Extract unique city values
            let cities = results.compactMap { $0["hospital_city"] as? String }
            let uniqueCities = Array(Set(cities)).sorted()
            
            await MainActor.run {
                self.availableCities = uniqueCities
            }
            
            print("Fetched \(uniqueCities.count) unique cities")
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
                
                return HospitalDoctor(
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
                      let startTime = data["slot_time"] as? String,
                      let endTime = data["slot_end_time"] as? String
                else { 
                    print("Failed to parse doctor availability data: \(data)")
                    return nil 
                }
                
                // Default to true for isAvailable field
                let isAvailable = true
                
                return AppointmentModels.DoctorAvailability(
                    id: id,
                    doctorId: doctorId,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    isAvailable: isAvailable
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
    func bookAppointment(patientId: String, slotId: Int, date: Date, time: Date, reason: String = "Regular checkup") async throws {
        guard let doctor = selectedDoctor,
              let hospital = selectedHospital else { 
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No doctor or hospital selected"])
        }
        
        // Generate appointment ID in the format APPT[0-9]{3}[A-Z]
        let randomNum = String(format: "%03d", Int.random(in: 0...999))
        let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
        let appointmentId = "APPT\(randomNum)\(randomLetter)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Note: patientId should be the ID from the patients table, not the user ID
        print("📝 Creating appointment with patient ID: \(patientId)")
        
        let appointmentData = AppointmentData(
            id: appointmentId,
            patient_id: patientId,
            doctor_id: doctor.id,
            hospital_id: hospital.id,
            availability_slot_id: slotId,
            appointment_date: dateFormatter.string(from: date),
            booking_time: nil, // Let Supabase use default CURRENT_TIMESTAMP
            status: "upcoming",
            created_at: nil, // Let Supabase set this with CURRENT_TIMESTAMP
            updated_at: nil, // Let Supabase set this with CURRENT_TIMESTAMP
            reason: reason
        )
        
        do {
            print("Attempting to insert appointment with data:", appointmentData)
            try await supabase.insert(into: "appointments", data: appointmentData)
            print("Successfully booked appointment with ID: \(appointmentId)")
            
            // Create and add local appointment object
            let appointment = Appointment(
                id: appointmentId,
                doctor: doctor.toModelDoctor(),
                date: date,
                time: time,
                status: .upcoming
            )
            
            // Add to appointment manager
            await MainActor.run {
                AppointmentManager.shared.addAppointment(appointment)
                print("Added appointment to AppointmentManager")
            }
            
            // Refresh appointments from database
            if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                print("🔄 Refreshing appointments after booking with user ID: \(userId)")
                
                // We should get the patient ID again and use that to fetch appointments
                let patientResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                if let patientData = patientResults.first, let fetchedPatientId = patientData["id"] as? String {
                    try await fetchAppointments(for: fetchedPatientId)
                } else {
                    print("⚠️ Could not find patient ID after booking - using provided patient ID")
                    try await fetchAppointments(for: patientId)
                }
            } else {
                print("⚠️ No user ID found when trying to refresh appointments")
            }
        } catch {
            print("Error booking appointment: \(error)")
            print("Error details: \(String(describing: error))")
            throw error
        }
    }
    
    /// Fetch appointments for a patient
    func fetchAppointments(for patientId: String) async throws {
        print("🔍 Starting to fetch appointments for patient ID: \(patientId)")
        do {
            // First, check if the patient ID is valid
            if patientId.isEmpty {
                print("❌ Patient ID is empty")
                throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid patient ID"])
            }
            
            print("🔍 Querying appointments table for patient_id = \(patientId)")
            let results = try await supabase.select(
                from: "appointments",
                where: "patient_id",
                equals: patientId
            )
            print("✅ Found \(results.count) appointments in database")
            
            // Debug the raw response data if no appointments found
            if results.isEmpty {
                print("⚠️ No appointments found for patient ID: \(patientId)")
                
                // Try to query without filtering to check if the table has data
                print("🔍 Checking if appointments table has any data...")
                let allResults = try await supabase.select(from: "appointments")
                print("📊 Total appointments in database: \(allResults.count)")
                if !allResults.isEmpty {
                    print("📋 Sample appointment data: \(String(describing: allResults.first))")
                    if let firstAppt = allResults.first, let firstPatientId = firstAppt["patient_id"] as? String {
                        print("👤 First appointment's patient_id: \(firstPatientId)")
                    }
                }
                
                // Even if there are no appointments in the database, don't clear the local list
                // to prevent appointments from disappearing after booking
                return
            } else {
                print("📋 Sample appointment data: \(String(describing: results.first))")
            }
            
            // Use a temporary array to build new appointment list
            var appointments: [Appointment] = []
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let timestampFormatter = ISO8601DateFormatter()
            
            for data in results {
                guard let id = data["id"] as? String,
                      let doctorId = data["doctor_id"] as? String,
                      let dateString = data["appointment_date"] as? String,
                      let statusString = data["status"] as? String else {
                    print("⚠️ Skipping invalid appointment data")
                    continue
                }
                
                // Parse appointment date
                guard let date = dateFormatter.date(from: dateString) else {
                    print("⚠️ Invalid date format in appointment: \(dateString)")
                    continue
                }
                
                // Get doctor details
                print("🔍 Finding doctor with ID: \(doctorId)")
                let doctorResults = try await supabase.select(from: "doctors", where: "id", equals: doctorId)
                
                guard let doctorData = doctorResults.first else {
                    print("⚠️ Doctor not found for ID: \(doctorId)")
                    continue
                }
                
                guard let doctorName = doctorData["name"] as? String,
                      let specialization = doctorData["specialization"] as? String else {
                    print("⚠️ Invalid doctor data")
                    continue
                }
                
                let doctor = HospitalDoctor(
                    id: doctorId,
                    hospitalId: doctorData["hospital_id"] as? String ?? "HOSP001",
                    name: doctorName,
                    specialization: specialization,
                    qualifications: doctorData["qualifications"] as? [String] ?? [],
                    licenseNo: doctorData["license_no"] as? String ?? "",
                    experience: doctorData["experience"] as? Int ?? 0,
                    email: doctorData["email"] as? String ?? "",
                    contactNumber: doctorData["contact_number"] as? String,
                    doctorStatus: doctorData["doctor_status"] as? String ?? "active",
                    rating: doctorData["rating"] as? Double ?? 4.0,
                    consultationFee: doctorData["consultation_fee"] as? Double ?? 0.0
                )
                
                // Parse booking time
                var bookingTime = date
                if let bookingTimeString = data["booking_time"] as? String, 
                   let parsedTime = timestampFormatter.date(from: bookingTimeString) {
                    bookingTime = parsedTime
                    print("✅ Using booking time from database: \(bookingTimeString)")
                } else {
                    bookingTime = date
                    print("⚠️ Using appointment date as booking time because no valid booking_time found")
                }
                
                // Determine the appointment status
                let appointmentStatus: AppointmentStatus
                if let statusEnum = AppointmentStatus(rawValue: statusString) {
                    appointmentStatus = statusEnum
                    print("✅ Appointment status: \(appointmentStatus)")
                } else {
                    appointmentStatus = .upcoming
                    print("⚠️ Unknown status: \(statusString), defaulting to .upcoming")
                }
                
                let appointment = Appointment(
                    id: id,
                    doctor: doctor.toModelDoctor(),
                    date: date,
                    time: bookingTime,
                    status: appointmentStatus
                )
                
                appointments.append(appointment)
                print("✅ Added appointment: \(id) with status: \(appointmentStatus)")
            }
            
            // Update appointments asynchronously on the main thread
            await MainActor.run {
                if !appointments.isEmpty {
                    // Merge with existing appointments to prevent losing newly added ones
                    let existingIds = AppointmentManager.shared.appointments.map { $0.id }
                    let newAppointments = appointments.filter { !existingIds.contains($0.id) }
                    
                    // Add new appointments from database
                    for appointment in newAppointments {
                        AppointmentManager.shared.addAppointment(appointment)
                    }
                    
                    // Update existing appointments with latest status
                    for appointment in appointments {
                        if existingIds.contains(appointment.id) {
                            AppointmentManager.shared.updateAppointment(appointment)
                        }
                    }
                    
                    print("✅ Updated appointment list with \(appointments.count) appointments")
                } else {
                    print("⚠️ No appointments data to update")
                }
            }
        } catch {
            print("❌ Error fetching appointments: \(error)")
            throw error
        }
    }
    
    // MARK: - Computed Properties
    
    /// Get hospitals filtered by search text and selected city
    var filteredHospitals: [HospitalModel] {
        if searchText.isEmpty && selectedCity == nil {
            return hospitals
        }
        
        return hospitals.filter { hospital in
            let matchesSearch = searchText.isEmpty || 
                hospital.hospitalName.lowercased().contains(searchText.lowercased())
            
            let matchesCity = selectedCity == nil || 
                hospital.hospitalCity == selectedCity
            
            return matchesSearch && matchesCity
        }
    }
    
    // MARK: - Published Properties
    @Published var availableCities: [String] = []
    @Published var appointments: [AppointmentModels.Appointment] = []
}

// MARK: - Doctor Model Extensions
extension HospitalDoctor {
    // Convert HospitalDoctor to Models.Doctor for use in Appointment.swift
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
