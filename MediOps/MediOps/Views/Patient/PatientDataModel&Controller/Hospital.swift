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
    let is_premium: Bool
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
    @Published var availableSlots: [DoctorAvailabilityModels.AppointmentSlot] = []
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
            
            print("📆 Fetching slots for doctor \(doctor.name) (ID: \(doctor.id)) on \(dateString)")
            
            // Get the day of week for useful debugging
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1]
            print("📅 Selected day is \(dayName)")
            
            // Query the doctor_availability_efficient table
            let availabilityResults = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctor.id
            )
            
            print("📊 Found \(availabilityResults.count) availability records for doctor")
            
            guard let availabilityData = availabilityResults.first else {
                print("❌ No schedule found for doctor")
                await MainActor.run {
                    self.availableSlots = []
                    self.isLoading = false
                }
                return
            }
            
            // Debug: Print raw availability data
            print("📋 Raw availability data: \(availabilityData)")
            
            // Parse the availability data
            let availability = try DoctorAvailabilityModels.EfficientAvailability(
                id: availabilityData["id"] as? Int ?? 0,
                doctorId: availabilityData["doctor_id"] as? String ?? "",
                hospitalId: availabilityData["hospital_id"] as? String ?? "",
                weeklySchedule: parseWeeklySchedule(availabilityData["weekly_schedule"]),
                effectiveFrom: parseDate(availabilityData["effective_from"]) ?? Date(),
                effectiveUntil: parseDate(availabilityData["effective_until"]),
                maxNormalPatients: availabilityData["max_normal_patients"] as? Int ?? 5,
                maxPremiumPatients: availabilityData["max_premium_patients"] as? Int ?? 2,
                createdAt: parseDate(availabilityData["created_at"]),
                updatedAt: parseDate(availabilityData["updated_at"])
            )
            
            // Debug: Print parsed weekly schedule 
            if let weeklySchedule = availability.weeklySchedule[dayName] {
                print("📅 \(dayName) schedule has \(weeklySchedule.count) time slots")
                let availableSlots = weeklySchedule.filter { $0.value == true }
                print("  - Available slots: \(availableSlots.count)")
                print("  - Unavailable slots: \(weeklySchedule.count - availableSlots.count)")
                
                // Print some sample slots
                if !availableSlots.isEmpty {
                    print("  - Sample available slots: \(Array(availableSlots.keys.prefix(3)))")
                }
            } else {
                print("❌ No schedule defined for \(dayName)")
            }
            
            // Get available slots for the date
            let availableTimeSlots = availability.getAvailableSlots(for: date)
            print("🕒 getAvailableSlots returned \(availableTimeSlots.count) slots")
            
            // Debug: Print available time slots
            for (index, slot) in availableTimeSlots.enumerated() {
                print("  \(index+1). \(slot.startTime) - \(slot.endTime)")
            }
            
            // Get existing appointments for this date to check slot capacity
            let existingAppointments = try await supabase.select(
                from: "appointments",
                where: "doctor_id",
                equals: doctor.id
            ).filter { appointment in
                guard let appointmentDate = appointment["appointment_date"] as? String,
                      let status = appointment["status"] as? String else {
                    return false
                }
                return appointmentDate == dateString && status == "upcoming"
            }
            
            print("📝 Found \(existingAppointments.count) existing appointments for this date")
            
            // Count appointments per slot
            var slotCounts: [String: Int] = [:]
            for appointment in existingAppointments {
                if let startTime = appointment["slot_start_time"] as? String {
                    slotCounts[startTime, default: 0] += 1
                    print("  - Slot \(startTime) has \(slotCounts[startTime]!) bookings")
                }
            }
            
            // Convert available time slots to AppointmentSlot
            var availableSlots: [DoctorAvailabilityModels.AppointmentSlot] = []
            var slotId = 1
            
            for (index, timeSlot) in availableTimeSlots.enumerated() {
                let currentCount = slotCounts[timeSlot.startTime] ?? 0
                let maxPatientsPerSlot = availability.maxNormalPatients + availability.maxPremiumPatients
                let remainingSlots = maxPatientsPerSlot - currentCount
                
                print("  • Slot \(timeSlot.startTime)-\(timeSlot.endTime): \(remainingSlots)/\(maxPatientsPerSlot) available")
                
                if remainingSlots > 0 {
                    let formattedStartTime = DoctorAvailabilityModels.AppointmentSlot.formatTimeForDisplay(timeSlot.startTime)
                    let formattedEndTime = DoctorAvailabilityModels.AppointmentSlot.formatTimeForDisplay(timeSlot.endTime)
                    
                    let slot = DoctorAvailabilityModels.AppointmentSlot(
                        id: slotId,
                        doctorId: doctor.id,
                        date: date,
                        startTime: formattedStartTime,
                        endTime: formattedEndTime,
                        rawStartTime: timeSlot.startTime,
                        rawEndTime: timeSlot.endTime,
                        isAvailable: true,
                        remainingSlots: remainingSlots,
                        totalSlots: maxPatientsPerSlot
                    )
                    availableSlots.append(slot)
                    print("    ✓ Added to available slots")
                    slotId += 1
                } else {
                    print("    ✗ Skipped (fully booked)")
                }
            }
            
            print("📊 Final available slots: \(availableSlots.count)")
            
            await MainActor.run {
                self.availableSlots = availableSlots
                self.isLoading = false
            }
            
        } catch {
            print("❌ Error fetching available slots: \(error)")
            await MainActor.run {
                self.error = error
                self.availableSlots = []
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Appointment Methods
    
    /// Book an appointment
    func bookAppointment(patientId: String, slotId: Int, date: Date, time: Date, reason: String = "Regular checkup", isPremium: Bool = false) async throws {
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
            reason: reason,
            is_premium: isPremium
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
                status: .upcoming,
                startTime: nil,
                endTime: nil,
                isPremium: isPremium
            )
            
            // Add to appointment manager
            await MainActor.run {
                AppointmentManager.shared.addAppointment(appointment)
                print("Added appointment to AppointmentManager")
            }
            
            // Refresh appointments from database
            if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                print("🔄 Refreshing appointments after booking with user ID: \(userId)")
                try await fetchAppointments(for: userId)
                
                // Refresh available slots to update counts
                await fetchAvailableSlots(for: date)
            }
            
        } catch {
            print("Error booking appointment: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetch appointments for a patient
    func fetchAppointments(for patientId: String) async throws {
        print("🔄 Fetching appointments for patient: \(patientId)")
        
        let supabase = SupabaseController.shared
        
        // Use select with filter conditions instead of raw SQL
        let results = try await supabase.select(
            from: "appointments",
            where: "patient_id",
            equals: patientId
        ).filter { appointment in
            guard let status = appointment["status"] as? String else { return false }
            return ["completed", "cancelled", "missed"].contains(status)
        }
        
        print("📋 Found \(results.count) appointments")
        
        // Clear existing data first
        await MainActor.run {
            self.upcomingAppointments = []
            self.completedAppointments = []
            self.missedAppointments = []
        }
        
        var completed: [Appointment] = []
        var cancelled: [Appointment] = []
        var missed: [Appointment] = []
        
        for appointmentData in results {
            guard let id = appointmentData["id"] as? String,
                  let doctorId = appointmentData["doctor_id"] as? String,
                  let hospitalId = appointmentData["hospital_id"] as? String,
                  let appointmentDateStr = appointmentData["appointment_date"] as? String,
                  let statusStr = appointmentData["status"] as? String else {
                print("⚠️ Skipping appointment with missing required data")
                continue
            }
            
            print("📝 Processing appointment: \(id) with status: \(statusStr)")
            
            // Get raw time from the appointment data
            let rawStartTime = appointmentData["slot_start_time"] as? String ?? "12:00:00"
            let rawEndTime = appointmentData["slot_end_time"] as? String ?? "13:00:00"
            
            // Format the times for display
            let displayStartTime = formatSlotTime(rawStartTime)
            let displayEndTime = formatSlotTime(rawEndTime)
            
            // Parse appointment date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let appointmentDate = dateFormatter.date(from: appointmentDateStr) else {
                print("⚠️ Could not parse appointment date: \(appointmentDateStr)")
                continue
            }
            
            // Create the appointment time as a Date object for sorting
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss" 
            let timeDate = timeFormatter.date(from: rawStartTime) ?? Date()
            
            // Fetch doctor details
            if let doctor = await fetchDoctor(id: doctorId, hospitalId: hospitalId) {
                let status = AppointmentStatus(rawValue: statusStr.lowercased()) ?? .upcoming
                let appointment = Appointment(
                    id: id,
                    doctor: doctor,
                    date: appointmentDate,
                    time: timeDate,
                    status: status,
                    startTime: displayStartTime,
                    endTime: displayEndTime,
                    isPremium: appointmentData["is_premium"] as? Bool ?? false
                )
                
                // Categorize the appointment based on status
                switch status {
                case .completed:
                    completed.append(appointment)
                    print("✅ Added completed appointment: \(id)")
                case .cancelled:
                    cancelled.append(appointment)
                    print("❌ Added cancelled appointment: \(id)")
                case .missed:
                    missed.append(appointment)
                    print("⚠️ Added missed appointment: \(id)")
                default:
                    break
                }
            }
        }
        
        // Sort appointments by date/time in descending order
        let sortByDateTime: (Appointment, Appointment) -> Bool = { (a1, a2) in
            if Calendar.current.isDate(a1.date, inSameDayAs: a2.date) {
                return a1.time > a2.time // Changed to descending order
            }
            return a1.date > a2.date // Changed to descending order
        }
        
        completed.sort(by: sortByDateTime)
        cancelled.sort(by: sortByDateTime)
        missed.sort(by: sortByDateTime)
        
        await MainActor.run {
            self.completedAppointments = completed + cancelled
            self.missedAppointments = missed
        }
        
        print("✅ Successfully processed appointments:")
        print("   - Completed: \(completed.count)")
        print("   - Cancelled: \(cancelled.count)")
        print("   - Missed: \(missed.count)")
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
    @Published var upcomingAppointments: [Appointment] = []
    @Published var completedAppointments: [Appointment] = []
    @Published var missedAppointments: [Appointment] = []
    
    // Helper function to convert between status types
    private func convertToModelStatus(_ status: AppointmentStatus) -> AppointmentModels.Status {
        switch status {
        case .upcoming:
            return .upcoming
        case .completed:
            return .completed
        case .cancelled:
            return .cancelled
        case .missed:
            return .missed
        }
    }
    
    // Create a local Appointment from an AppointmentModels.Appointment
    private func createLocalAppointment(from modelAppointment: AppointmentModels.Appointment, with doctor: HospitalDoctor) -> Appointment {
        return Appointment(
            id: modelAppointment.id,
            doctor: doctor.toModelDoctor(),
            date: modelAppointment.appointmentDate,
            time: modelAppointment.bookingTime,
            status: convertFromModelStatus(modelAppointment.status)
        )
    }
    
    // Convert from AppointmentModels.Status to AppointmentStatus
    private func convertFromModelStatus(_ status: AppointmentModels.Status) -> AppointmentStatus {
        switch status {
        case .upcoming:
            return .upcoming
        case .completed:
            return .completed
        case .cancelled:
            return .cancelled
        case .missed:
            return .missed
        }
    }
    
    private func debugAppointmentFetching(userId: String) async {
        print("\n🔍 DEBUG: Starting appointment fetch diagnosis")
        print("--------------------------------------------")
        
        do {
            // 1. Check user ID
            print("1️⃣ Checking user ID: \(userId)")
            
            // 2. Check patient record
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            if let patientData = patientResults.first {
                print("2️⃣ Found patient record:")
                print("   - ID: \(patientData["id"] as? String ?? "nil")")
                print("   - Patient ID: \(patientData["patient_id"] as? String ?? "nil")")
                print("   - User ID: \(patientData["user_id"] as? String ?? "nil")")
                
                // 3. Check appointments
                if let patientId = patientData["patient_id"] as? String {
                    print("\n3️⃣ Checking appointments for patient_id: \(patientId)")
                    
                    let appointmentResults = try await supabase.select(
                        from: "appointments",
                        where: "patient_id",
                        equals: patientId
                    )
                    
                    print("   Found \(appointmentResults.count) total appointments")
                    
                    for (index, appointment) in appointmentResults.enumerated() {
                        print("\n   Appointment \(index + 1):")
                        print("   - ID: \(appointment["id"] as? String ?? "nil")")
                        print("   - Status: \(appointment["status"] as? String ?? "nil")")
                        print("   - Date: \(appointment["appointment_date"] as? String ?? "nil")")
                        print("   - Doctor ID: \(appointment["doctor_id"] as? String ?? "nil")")
                    }
                } else {
                    print("❌ No patient_id found in patient record")
                }
            } else {
                print("❌ No patient record found for user ID: \(userId)")
            }
            
        } catch {
            print("❌ Error during diagnosis: \(error.localizedDescription)")
        }
        
        print("\n--------------------------------------------")
    }
    
    /// Call this function to debug appointment fetching
    func debugAppointments() {
        if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
            Task {
                await debugAppointmentFetching(userId: userId)
            }
        } else {
            print("❌ No user ID found in UserDefaults")
        }
    }
    
    // MARK: - Helper Parsing Functions
    
    /// Parse weekly schedule data from JSON
    private func parseWeeklySchedule(_ data: Any?) -> [String: [String: Bool]] {
        print("🔍 Parsing weekly schedule: \(String(describing: data))")
        
        // If data is already in correct format, use it directly
        if let scheduleData = data as? [String: [String: Bool]] {
            print("✅ Weekly schedule is already in correct format")
            return scheduleData
        }
        
        // If data is a string (JSON string), try to parse it
        if let jsonString = data as? String {
            print("🔄 Weekly schedule is a JSON string, attempting to parse")
            
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    if let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Bool]] {
                        print("✅ Successfully parsed JSON string to dictionary")
                        return parsed
                    }
                    
                    // Handle possible nested structure
                    if let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]] {
                        print("🔄 Parsed to [String: [String: Any]], converting to [String: [String: Bool]]")
                        
                        var result: [String: [String: Bool]] = [:]
                        for (day, slots) in parsed {
                            var daySlots: [String: Bool] = [:]
                            for (time, value) in slots {
                                if let boolValue = value as? Bool {
                                    daySlots[time] = boolValue
                                } else if let intValue = value as? Int {
                                    daySlots[time] = intValue != 0
                                } else if let stringValue = value as? String {
                                    daySlots[time] = stringValue.lowercased() == "true"
                                }
                            }
                            result[day] = daySlots
                        }
                        return result
                    }
                } catch {
                    print("❌ Error parsing JSON string: \(error)")
                }
            }
        }
        
        // If it's a dictionary with different structure, try to convert it
        if let dictData = data as? [String: Any] {
            print("🔄 Weekly schedule is a dictionary with different structure")
            
            var result: [String: [String: Bool]] = [:]
            let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            
            for day in days {
                if let dayData = dictData[day] as? [String: Any] {
                    var daySlots: [String: Bool] = [:]
                    
                    for (slot, value) in dayData {
                        if let boolValue = value as? Bool {
                            daySlots[slot] = boolValue
                        } else if let intValue = value as? Int {
                            daySlots[slot] = intValue != 0
                        } else if let stringValue = value as? String {
                            daySlots[slot] = stringValue.lowercased() == "true"
                        }
                    }
                    
                    result[day] = daySlots
                }
            }
            
            if !result.isEmpty {
                print("✅ Successfully converted dictionary to required format")
                return result
            }
        }
        
        print("⚠️ Failed to parse weekly schedule data")
        return [:]
    }
    
    /// Parse date string from Supabase into Date object
    private func parseDate(_ dateString: Any?) -> Date? {
        guard let dateStr = dateString as? String else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateStr) {
            return date
        }
        
        // Try alternative format
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateStr)
    }
    
    // MARK: - Helper Methods for time formatting
    
    /// Format a database time string (HH:mm:ss) to display format (h:mm a)
    func formatSlotTime(_ rawTime: String) -> String {
        // Create input formatter for parsing the raw time
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        // Create output formatter for display format
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        // Try to parse using the standard format first
        if let date = inputFormatter.date(from: rawTime) {
            return outputFormatter.string(from: date)
        }
        
        // If standard format fails, try alternative formats
        let alternativeFormats = ["HH:mm", "h:mm a", "hh:mm a", "h:mm"]
        for format in alternativeFormats {
            inputFormatter.dateFormat = format
            if let date = inputFormatter.date(from: rawTime) {
                return outputFormatter.string(from: date)
            }
        }
        
        // If all parsing attempts fail, return the original string with a warning
        print("⚠️ Warning: Could not parse time format: \(rawTime)")
        return rawTime
    }
    
    // Add the fetchDoctor function if it's missing
    private func fetchDoctor(id doctorId: String, hospitalId: String) async -> Models.Doctor? {
        do {
            let results = try await supabase.select(
                from: "doctors",
                where: "id",
                equals: doctorId
            )
            
            guard let doctorData = results.first,
                  let name = doctorData["name"] as? String,
                  let specialization = doctorData["specialization"] as? String else {
                print("⚠️ Could not find doctor with ID: \(doctorId)")
                return nil
            }
            
            // Get additional fields with defaults if missing
            let qualifications = doctorData["qualifications"] as? [String] ?? []
            let licenseNo = doctorData["license_no"] as? String ?? ""
            let experience = doctorData["experience"] as? Int ?? 0
            let email = doctorData["email"] as? String ?? ""
            let contactNumber = doctorData["contact_number"] as? String
            let status = doctorData["doctor_status"] as? String ?? "active"
            
            return Models.Doctor(
                id: doctorId,
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
                doctorStatus: status,
                createdAt: Date(),
                updatedAt: Date()
            )
        } catch {
            print("⚠️ Error fetching doctor details: \(error.localizedDescription)")
            return nil
        }
    }
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
