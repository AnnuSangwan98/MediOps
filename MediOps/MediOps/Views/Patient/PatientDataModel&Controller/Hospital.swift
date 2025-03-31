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
        // Load user data if available
        if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
            Task {
                do {
                    try await fetchAppointments(for: userId)
                } catch {
                    // Error handling
                }
            }
        }
    } // Make initializer private for singleton
    
    // MARK: - Hospital Methods
    
    /// Fetch hospitals based on search text and selected city
    func fetchHospitals() async {
        isLoading = true
        error = nil
        
        do {
            // Try first with a direct table select (without SQL function)
            let queryTable = "hospitals"
            var results: [[String: Any]] = []
            
            do {
                results = try await supabase.select(from: queryTable)
            } catch {
                // If simple fetch fails, try with an HTTP request directly
                let url = URL(string: "\(supabase.supabaseURL)/rest/v1/hospitals?select=*")!
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            results = jsonArray
                        }
                    }
                } catch {
                    // Handle silently
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
                        // Option 1: Try direct doctors table query
                        let doctorResults = try await supabase.select(
                            from: "doctors",
                            where: "hospital_id",
                            equals: id
                        )
                        
                        if !doctorResults.isEmpty {
                            // Count only active doctors
                            numDoctors = doctorResults.filter { ($0["doctor_status"] as? String) == "active" }.count
                        } else {
                            // Option 2: Try with direct data from hospital record
                            if let doctorCount = data["number_of_doctors"] as? Int {
                                numDoctors = doctorCount
                            }
                        }
                    } catch {
                        // Try to recover using any data in the hospital record itself
                        if let doctorCount = data["number_of_doctors"] as? Int {
                            numDoctors = doctorCount
                        }
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
                } catch {
                    // Silently handle parsing errors
                }
            }
            
            await MainActor.run {
                self.hospitals = hospitalModels
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
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
        } catch {
            // Handle silently
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
                      let status = data["doctor_status"] as? String else { return nil }
                
                // Use default values for optional fields
                let rating = data["rating"] as? Double ?? 4.5
                let consultationFee = data["consultation_fee"] as? Double ?? 1000.0
                
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
                
                // Get the slot time from availability_slots table
                var slotStartTime: String? = nil
                var slotEndTime: String? = nil
                
                if let slotId = data["availability_slot_id"] as? Int {
                    print("🔍 Looking up availability slot with ID: \(slotId)")
                    let slotResults = try await supabase.select(from: "availability_slots", where: "id", equals: String(slotId))
                    
                    if let slotData = slotResults.first {
                        print("✅ Found slot data: \(slotData)")
                        slotStartTime = slotData["slot_time"] as? String
                        slotEndTime = slotData["slot_end_time"] as? String
                        
                        print("⏰ Slot times - Start: \(slotStartTime ?? "Not found"), End: \(slotEndTime ?? "Not found")")
                        
                        // Check if the values are empty strings or nil
                        if slotStartTime == nil || slotStartTime?.isEmpty == true {
                            print("⚠️ Empty or missing slot_time for slotId \(slotId)")
                            
                            // Try to find alternative time fields in the slot data
                            for (key, value) in slotData {
                                if key.lowercased().contains("time") || key.lowercased().contains("slot") {
                                    print("   Found potential time field: \(key) = \(value)")
                                }
                            }
                        }
                    } else {
                        print("⚠️ No slot data found for ID: \(slotId)")
                        
                        // Try searching directly in the appointments table for time information
                        if let rawStartTime = data["slot_time"] as? String {
                            print("📌 Found slot_time directly in appointment data: \(rawStartTime)")
                            slotStartTime = rawStartTime
                        }
                        
                        if let rawEndTime = data["slot_end_time"] as? String {
                            print("📌 Found slot_end_time directly in appointment data: \(rawEndTime)")
                            slotEndTime = rawEndTime
                        }
                        
                        // Debug other time-related fields that might exist
                        for (key, value) in data {
                            if key.lowercased().contains("time") || key.lowercased().contains("slot") {
                                print("   Found potential time field in appointment: \(key) = \(value)")
                            }
                        }
                    }
                } else {
                    print("⚠️ No availability_slot_id found in appointment data")
                    
                    // Debug appointment data to find any time fields
                    for (key, value) in data {
                        if key.lowercased().contains("time") || key.lowercased().contains("slot") {
                            print("   Found potential time field: \(key) = \(value)")
                        }
                    }
                }
                
                let appointment = Appointment(
                    id: id,
                    doctor: doctor.toModelDoctor(),
                    date: date,
                    time: bookingTime,
                    status: appointmentStatus,
                    startTime: slotStartTime,
                    endTime: slotEndTime
                )
                
                // If we don't have the slot times but we do have a slot ID, try to fix times now
                if (slotStartTime == nil || slotStartTime?.isEmpty == true || 
                    slotEndTime == nil || slotEndTime?.isEmpty == true) {
                    if let slotId = data["availability_slot_id"] as? Int {
                        print("🔄 Attempting to fix missing time information for appointment \(id)")
                        Task {
                            do {
                                let success = try await supabase.fixAppointmentTimes(
                                    appointmentId: id,
                                    slotId: slotId
                                )
                                
                                if success {
                                    print("✅ Successfully fixed time information for appointment \(id)")
                                    // We'll reload this appointment in the next fetch
                                } else {
                                    print("⚠️ Could not fix time information for appointment \(id)")
                                }
                            } catch {
                                print("❌ Error fixing appointment times: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
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
    
    // MARK: - Helper Methods
    
    /// Update doctor counts for all hospitals
    func updateDoctorCounts() async {
        print("🔄 Updating doctor counts for all hospitals")
        
        var updatedHospitals: [HospitalModel] = []
        
        for hospital in hospitals {
            do {
                print("🔍 Fetching doctor count for hospital: \(hospital.hospitalName)")
                
                // First check only active doctors
                let activeCount = try await countDoctors(for: hospital.id, onlyActive: true)
                let totalCount = try await countDoctors(for: hospital.id, onlyActive: false)
                
                print("✅ Found \(activeCount) active doctors and \(totalCount) total doctors for hospital \(hospital.hospitalName)")
                
                // Only count active doctors for display
                let numDoctors = activeCount
                
                // Always update the database to ensure consistency
                try await supabase.update(
                    table: "hospitals", 
                    id: hospital.id,
                    data: ["number_of_doctors": numDoctors]
                )
                print("✅ Updated hospital record with doctor count: \(numDoctors)")
                
                // Create updated hospital with new doctor count
                let updatedHospital = HospitalModel(
                    id: hospital.id,
                    hospitalName: hospital.hospitalName,
                    hospitalAddress: hospital.hospitalAddress,
                    hospitalState: hospital.hospitalState,
                    hospitalCity: hospital.hospitalCity,
                    areaPincode: hospital.areaPincode,
                    email: hospital.email,
                    contactNumber: hospital.contactNumber,
                    emergencyContactNumber: hospital.emergencyContactNumber,
                    licence: hospital.licence,
                    hospitalAccreditation: hospital.hospitalAccreditation,
                    type: hospital.type,
                    hospitalProfileImage: hospital.hospitalProfileImage,
                    coverImage: hospital.coverImage,
                    status: hospital.status,
                    departments: hospital.departments,
                    numberOfDoctors: numDoctors,
                    numberOfAppointments: hospital.numberOfAppointments,
                    description: hospital.description,
                    rating: hospital.rating
                )
                
                updatedHospitals.append(updatedHospital)
                print("✅ Updated local hospital model with doctor count: \(numDoctors)")
            } catch {
                print("⚠️ Failed to update doctor count for \(hospital.hospitalName): \(error.localizedDescription)")
                updatedHospitals.append(hospital)
            }
        }
        
        print("🔄 Replacing hospital models with updated doctor counts")
        await MainActor.run {
            // Replace hospitals array with updated hospitals that have correct doctor counts
            self.hospitals = updatedHospitals
            print("✅ Updated hospital models with doctor counts: \(updatedHospitals.map { "\($0.hospitalName): \($0.numberOfDoctors)" }.joined(separator: ", "))")
        }
    }
    
    // Helper function to count doctors for a hospital
    private func countDoctors(for hospitalId: String, onlyActive: Bool) async throws -> Int {
        // Use standard select query instead of SQL execution
        let doctorResults = try await supabase.select(
            from: "doctors",
            where: "hospital_id",
            equals: hospitalId
        )
        
        if onlyActive {
            let activeCount = doctorResults.filter { ($0["doctor_status"] as? String ?? "") == "active" }.count
            return activeCount
        }
        
        return doctorResults.count
    }
    
    /// Add test doctors to all hospitals for testing the doctor count functionality
    func addTestDoctorsToHospitals() async {
        print("🧪 Adding test doctors to hospitals for count verification")
        
        let supabase = SupabaseController.shared
        
        // Keep track of which hospitals we've updated
        var updatedHospitals = Set<String>()
        
        // Valid specializations from the constraint
        let validSpecializations = [
            "General medicine",
            "Orthopaedics",
            "Gynaecology",
            "Cardiology",
            "Pathology & laboratory"
        ]
        
        // Valid qualifications from the constraint
        let validQualifications = ["MBBS", "MD", "MS"]
        
        // For each hospital
        for hospital in hospitals {
            // Skip if we've already added doctors to this hospital
            if updatedHospitals.contains(hospital.id) {
                continue
            }
            
            // Check current doctor count
            do {
                print("🔍 Checking current doctor count for hospital: \(hospital.hospitalName)")
                let activeCount = try await countDoctors(for: hospital.id, onlyActive: true)
                print("✅ Current active doctor count: \(activeCount)")
                
                // Only add doctors if there are none or very few
                if activeCount < 3 {
                    print("🏥 Adding test doctors to hospital: \(hospital.hospitalName)")
                    
                    // Add up to 3 doctors with valid specializations
                    for i in 1...3 {
                        // Create a valid doctor ID format (DOC followed by 3 digits)
                        let doctorId = "DOC\(String(format: "%03d", i + Int.random(in: 100...999)))"
                        
                        // Pick a valid specialization
                        let specialization = validSpecializations[i % validSpecializations.count]
                        
                        // Create valid qualifications array (must be from the valid options, max 3)
                        let numQualifications = min(i, 3)
                        var qualifications: [String] = []
                        for j in 0..<numQualifications {
                            qualifications.append(validQualifications[j % validQualifications.count])
                        }
                        
                        // Generate a valid license number (2 letters followed by 5 digits)
                        let licenseNo = "AB\(String(format: "%05d", Int.random(in: 10000...99999)))"
                        
                        // Generate valid contact numbers (10 digits)
                        let contactNumber = String(format: "%010d", Int.random(in: 6000000000...9999999999))
                        let emergencyContactNumber = String(format: "%010d", Int.random(in: 6000000000...9999999999))
                        
                        // Generate valid pincode (6 digits)
                        let pincode = String(format: "%06d", Int.random(in: 100000...999999))
                        
                        // Prepare doctor data with all required fields
                        let doctorData: [String: Any] = [
                            "id": doctorId,
                            "hospital_id": hospital.id,
                            "name": "Dr. \(randomName()) \(randomLastName())",
                            "specialization": specialization,
                            "qualifications": qualifications,
                            "license_no": licenseNo,
                            "experience": Int.random(in: 5...20),
                            "address_line": "Test Address Line, \(hospital.hospitalCity)",
                            "state": hospital.hospitalState,
                            "city": hospital.hospitalCity,
                            "pincode": pincode,
                            "email": "doctor\(i)@\(hospital.hospitalName.lowercased().replacingOccurrences(of: " ", with: "")).com",
                            "contact_number": contactNumber,
                            "emergency_contact_number": emergencyContactNumber,
                            "doctor_status": "active",
                            "is_first_time_login": true,
                            "password": "Test@123456"  // Valid password format per constraint
                        ]
                        
                        // First check if doctor already exists
                        let existingDoctors = try await supabase.select(
                            from: "doctors",
                            where: "id",
                            equals: doctorId
                        )
                        
                        if existingDoctors.isEmpty {
                            // Insert the doctor
                            try await supabase.insert(into: "doctors", values: doctorData)
                            print("✅ Added doctor: \(doctorData["name"]!) (ID: \(doctorId)) to \(hospital.hospitalName)")
                        } else {
                            // Update existing doctor to ensure it's active
                            try await supabase.update(
                                table: "doctors",
                                id: doctorId,
                                data: ["doctor_status": "active"]
                            )
                            print("✅ Updated existing doctor \(doctorId) to active status")
                        }
                    }
                    
                    updatedHospitals.insert(hospital.id)
                    print("✅ Finished adding doctors to \(hospital.hospitalName)")
                } else {
                    print("ℹ️ Hospital \(hospital.hospitalName) already has \(activeCount) doctors")
                }
            } catch {
                print("❌ Error checking/adding doctors for \(hospital.hospitalName): \(error.localizedDescription)")
            }
        }
        
        // Update doctor counts after adding
        if !updatedHospitals.isEmpty {
            print("🔄 Updating doctor counts after adding test doctors")
            await updateDoctorCounts()
        }
    }
    
    // Helper function to generate random names
    private func randomName() -> String {
        let firstNames = ["John", "Jane", "Alex", "Sarah", "Michael", "Emily", "David", "Lisa", "Robert", "Maria", "Ravi", "Priya", "Amit", "Sneha", "Rajesh"]
        return firstNames[Int.random(in: 0..<firstNames.count)]
    }
    
    // Helper function to generate random last names
    private func randomLastName() -> String {
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson", "Sharma", "Patel", "Kumar", "Singh", "Gupta"]
        return lastNames[Int.random(in: 0..<lastNames.count)]
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
