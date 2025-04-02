import SwiftUI

// Import SupabaseController
import class MediOps.SupabaseController
import struct MediOps.RoleSelectionView

// Doctor Availability Model
struct DoctorAvailability {
    let id: Int
    let doctorId: String
    let hospitalId: String
    let weeklySchedule: WeeklySchedule
    let effectiveFrom: Date
    let effectiveUntil: Date?
    let maxNormalPatients: Int
    let maxPremiumPatients: Int
}

// Weekly Schedule Structure
struct WeeklySchedule: Codable {
    var monday: [TimeSlot]?
    var tuesday: [TimeSlot]?
    var wednesday: [TimeSlot]?
    var thursday: [TimeSlot]?
    var friday: [TimeSlot]?
    var saturday: [TimeSlot]?
    var sunday: [TimeSlot]?
    
    struct TimeSlot: Codable, Identifiable {
        let start: String
        let end: String
        var id: String { start + end }
    }
}

struct DoctorProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var doctor: DoctorProfile?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEditSheet = false
    @State private var showPasswordSheet = false
    @State private var showLogoutAlert = false
    @State private var navigateToRoleSelection = false
    @State private var availability: DoctorAvailability?
    
    // Editable fields (moved to EditDoctorProfileView)
    
    // List of states in India for selection
    let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Delhi",
        "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
        "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
        "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
        "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ]
    
    // List of specializations for selection
    let specializations = [
        "General medicine", "Orthopaedics", "Gynaecology", "Cardiology", "Pathology & laboratory"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading profile...")
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Profile image and name section
                            VStack(spacing: 15) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.teal)
                                    .background(Circle().fill(Color.white))
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                                
                                Text(doctor?.name ?? "Doctor")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let doctorId = doctor?.id {
                                    Text(doctorId)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            
                            // Profile information section
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Professional Information")
                                
                                // Specialization
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Specialization")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.specialization ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Qualifications
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Qualifications")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.qualifications.joined(separator: ", ") ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // License Number
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("License Number")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.licenseNo ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Experience
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Experience")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text("\(doctor?.experience ?? 0) years")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Hospital
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hospital ID")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.hospitalId ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Contact Information
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Contact Information")
                                
                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.email ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Contact Number
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Contact Number")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.contactNumber ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Emergency Contact
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Emergency Contact")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.emergencyContactNumber ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Address Information
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Address Information")
                                
                                // Address Line
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Address")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.addressLine ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // City
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("City")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.city ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // State
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("State")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.state ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                                
                                // Pincode
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PIN Code")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor?.pincode ?? "Not specified")
                                        .font(.body)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Weekly Schedule Section
                            VStack(alignment: .leading, spacing: 15) {
                                SectionTitle(title: "Weekly Schedule")
                                
                                if let availability = availability {
                                    // Days selector with horizontal scroll
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 15) {
                                            ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                                                let slots = getTimeSlotsForDay(day.lowercased(), in: availability.weeklySchedule)
                                                DayScheduleCard(day: day, slots: slots)
                                            }
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.bottom, 5)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .foregroundColor(.gray)
                                        Text("No schedule available")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Add Password Reset Button before Logout
                            Button(action: {
                                showPasswordSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "lock.rotation")
                                    Text("Change Password")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color.teal)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 10)
                            
                            // Logout Button
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        Task {
                            await refreshDoctorProfile()
                        }
                    }
                }
            }
            .navigationTitle("Doctor Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isLoading {
                        Button(action: {
                            showEditSheet = true
                        }) {
                            Text("Edit")
                                .foregroundColor(.teal)
                        }
                    }
                }
            }
            .onAppear {
                loadDoctorData()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .fullScreenCover(isPresented: $navigateToRoleSelection) {
                RoleSelectionView()
            }
            .sheet(isPresented: $showEditSheet) {
                if let doctor = doctor {
                    EditDoctorProfileView(
                        doctor: doctor,
                        onSave: { updatedDoctor in
                            loadDoctorData() // Reload the data after update
                        }
                    )
                }
            }
            
            // Password Change Sheet
            .sheet(isPresented: $showPasswordSheet) {
                if let doctor = doctor {
                    ChangePasswordView(
                        doctorId: doctor.id,
                        onComplete: {
                            // Just dismiss the sheet on completion
                        }
                    )
                }
            }
        }
    }
    
    private func loadDoctorData() {
        Task {
            await refreshDoctorProfile()
        }
    }
    
    private func refreshDoctorProfile() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Get doctor ID from UserDefaults
        guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id") else {
            await MainActor.run {
                errorMessage = "Doctor ID not found. Please log in again."
                showError = true
                isLoading = false
            }
            return
        }
        
        do {
            // Fetch doctor data from Supabase
            let supabase = SupabaseController.shared
            let result = try await supabase.select(
                from: "doctors",
                where: "id",
                equals: doctorId
            )
            
            guard let doctorData = result.first else {
                await MainActor.run {
                    errorMessage = "Doctor profile not found"
                    showError = true
                    isLoading = false
                }
                return
            }
            
            // Parse the doctor data
            let doctorProfile = try parseDoctorData(doctorData)
            
            // Fetch availability data
            let availabilityResult = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctorId
            )
            
            // Create a variable to store the availability
            var doctorAvailability: DoctorAvailability? = nil
            
            if let availabilityData = availabilityResult.first {
                doctorAvailability = try parseAvailabilityData(availabilityData)
            }
            
            // Update UI
            await MainActor.run {
                self.doctor = doctorProfile
                self.availability = doctorAvailability
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func logout() {
        // Clear user data from UserDefaults
        UserDefaults.standard.removeObject(forKey: "current_doctor_id")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        // Navigate to role selection
        navigateToRoleSelection = true
    }
    
    private func parseDoctorData(_ data: [String: Any]) throws -> DoctorProfile {
        // Required fields
        guard let id = data["id"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing doctor ID"])
        }
        
        guard let name = data["name"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing doctor name"])
        }
        
        guard let specialization = data["specialization"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing specialization"])
        }
        
        guard let hospitalId = data["hospital_id"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing hospital ID"])
        }
        
        // Optional fields with defaults
        let qualifications = data["qualifications"] as? [String] ?? ["MBBS"]
        let licenseNo = data["license_no"] as? String ?? "Not specified"
        
        let experience: Int
        if let exp = data["experience"] as? Int {
            experience = exp
        } else if let expString = data["experience"] as? String, let exp = Int(expString) {
            experience = exp
        } else {
            experience = 0
        }
        
        let addressLine = data["address_line"] as? String ?? ""
        let state = data["state"] as? String ?? ""
        let city = data["city"] as? String ?? ""
        let pincode = data["pincode"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let contactNumber = data["contact_number"] as? String
        let emergencyContactNumber = data["emergency_contact_number"] as? String
        
        return DoctorProfile(
            id: id,
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
            emergencyContactNumber: emergencyContactNumber
        )
    }
    
    private func parseAvailabilityData(_ data: [String: Any]) throws -> DoctorAvailability {
        guard let id = data["id"] as? Int,
              let doctorId = data["doctor_id"] as? String,
              let hospitalId = data["hospital_id"] as? String,
              let scheduleData = data["weekly_schedule"] as? [String: Any],
              let maxNormalPatients = data["max_normal_patients"] as? Int,
              let maxPremiumPatients = data["max_premium_patients"] as? Int else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid availability data"])
        }
        
        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let effectiveFromStr = data["effective_from"] as? String,
              let effectiveFrom = dateFormatter.date(from: effectiveFromStr) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid effective_from date"])
        }
        
        var effectiveUntil: Date? = nil
        if let effectiveUntilStr = data["effective_until"] as? String {
            effectiveUntil = dateFormatter.date(from: effectiveUntilStr)
        }
        
        // Parse weekly schedule
        let weeklySchedule = try parseWeeklySchedule(scheduleData)
        
        return DoctorAvailability(
            id: id,
            doctorId: doctorId,
            hospitalId: hospitalId,
            weeklySchedule: weeklySchedule,
            effectiveFrom: effectiveFrom,
            effectiveUntil: effectiveUntil,
            maxNormalPatients: maxNormalPatients,
            maxPremiumPatients: maxPremiumPatients
        )
    }
    
    private func parseWeeklySchedule(_ data: [String: Any]) throws -> WeeklySchedule {
        var schedule = WeeklySchedule()
        
        let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        
        for day in days {
            // Debug print to see the raw data
            print("Raw data for \(day): \(data[day] ?? "nil")")
            
            // Handle the new schedule format where each day is a dictionary of time slots
            if let dayData = data[day] as? [String: Bool] {
                // Filter only the available time slots (where value is true)
                let availableSlots = dayData.filter { $0.value == true }
                
                // Convert the time slot strings to TimeSlot objects
                let timeSlots = availableSlots.keys.compactMap { timeRange -> WeeklySchedule.TimeSlot? in
                    // Split the time range (e.g., "9:00-10:00") into start and end times
                    let components = timeRange.split(separator: "-")
                    guard components.count == 2 else { return nil }
                    
                    let start = String(components[0])
                    let end = String(components[1])
                    
                    // Convert to proper time format if needed
                    let formattedStart = formatTimeForStorage(start)
                    let formattedEnd = formatTimeForStorage(end)
                    
                    return WeeklySchedule.TimeSlot(start: formattedStart, end: formattedEnd)
                }
                
                // Sort time slots by start time
                let sortedSlots = timeSlots.sorted { slot1, slot2 in
                    let time1 = convertTo24Hour(slot1.start)
                    let time2 = convertTo24Hour(slot2.start)
                    return time1 < time2
                }
                
                // Debug print for parsed slots
                print("Parsed slots for \(day): \(sortedSlots)")
                
                switch day {
                case "monday": schedule.monday = sortedSlots
                case "tuesday": schedule.tuesday = sortedSlots
                case "wednesday": schedule.wednesday = sortedSlots
                case "thursday": schedule.thursday = sortedSlots
                case "friday": schedule.friday = sortedSlots
                case "saturday": schedule.saturday = sortedSlots
                case "sunday": schedule.sunday = sortedSlots
                default: break
                }
            }
        }
        
        return schedule
    }
    
    // Helper function to format time for storage
    private func formatTimeForStorage(_ timeString: String) -> String {
        // Handle cases like "0:00" or "9:00"
        let components = timeString.split(separator: ":")
        guard components.count == 2 else { return timeString }
        
        let hour = Int(components[0]) ?? 0
        let minute = String(components[1])  // Convert SubString to String
        
        // Pad hour with leading zero if needed
        return String(format: "%02d:%@", hour, minute)
    }
    
    // Helper function to convert time to 24-hour format for sorting
    private func convertTo24Hour(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count == 2 else { return timeString }
        
        let hour = Int(components[0]) ?? 0
        return String(format: "%02d:%@", hour, String(components[1]))  // Convert SubString to String
    }
    
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        if let date = inputFormatter.date(from: timeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            return outputFormatter.string(from: date)
        }
        
        // If parsing fails, try to handle edge case of "0:00"
        if timeString == "0:00" {
            return "12:00 AM"
        }
        
        return timeString
    }
    
    // Add helper functions at the bottom of the struct
    private func getTimeSlotsForDay(_ day: String, in schedule: WeeklySchedule) -> [WeeklySchedule.TimeSlot] {
        switch day {
        case "monday": return schedule.monday ?? []
        case "tuesday": return schedule.tuesday ?? []
        case "wednesday": return schedule.wednesday ?? []
        case "thursday": return schedule.thursday ?? []
        case "friday": return schedule.friday ?? []
        case "saturday": return schedule.saturday ?? []
        case "sunday": return schedule.sunday ?? []
        default: return []
        }
    }
}

// Doctor Profile Model
struct DoctorProfile {
    let id: String
    let name: String
    let specialization: String
    let hospitalId: String
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
}

// Edit Doctor Profile View - Modal Sheet
struct EditDoctorProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let doctor: DoctorProfile
    var onSave: (DoctorProfile) -> Void
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Editable fields
    @State private var addressLine: String
    @State private var city: String
    @State private var state: String
    @State private var pincode: String
    @State private var email: String
    @State private var contactNumber: String
    @State private var emergencyContactNumber: String
    
    // List of states in India for selection
    let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Delhi",
        "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
        "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
        "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
        "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ]
    
    // List of specializations for selection
    let specializations = [
        "General medicine", "Orthopaedics", "Gynaecology", "Cardiology", "Pathology & laboratory"
    ]
    
    init(doctor: DoctorProfile, onSave: @escaping (DoctorProfile) -> Void) {
        self.doctor = doctor
        self.onSave = onSave
        
        // Initialize state variables with doctor data
        _addressLine = State(initialValue: doctor.addressLine)
        _city = State(initialValue: doctor.city)
        _state = State(initialValue: doctor.state)
        _pincode = State(initialValue: doctor.pincode)
        _email = State(initialValue: doctor.email)
        _contactNumber = State(initialValue: doctor.contactNumber ?? "")
        _emergencyContactNumber = State(initialValue: doctor.emergencyContactNumber ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Saving profile...")
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Profile image and name section
                            VStack(spacing: 15) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.teal)
                                    .background(Circle().fill(Color.white))
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                                
                                Text(doctor.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            
                            // Professional Information
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Professional Information")
                                
                                // Specialization (display only)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Specialization")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Text(doctor.specialization)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Contact Information
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Contact Information")
                                
                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                                
                                // Contact Number
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Contact Number")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Contact Number", text: $contactNumber)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                        .onChange(of: contactNumber) { _, newValue in
                                            if newValue.count > 10 {
                                                contactNumber = String(newValue.prefix(10))
                                            }
                                            // Filter only digits
                                            contactNumber = newValue.filter { $0.isNumber }
                                        }
                                }
                                
                                // Emergency Contact
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Emergency Contact")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Emergency Contact", text: $emergencyContactNumber)
                                        .keyboardType(.phonePad)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                        .onChange(of: emergencyContactNumber) { _, newValue in
                                            if newValue.count > 10 {
                                                emergencyContactNumber = String(newValue.prefix(10))
                                            }
                                            // Filter only digits
                                            emergencyContactNumber = newValue.filter { $0.isNumber }
                                        }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Address Information
                            VStack(alignment: .leading, spacing: 20) {
                                SectionTitle(title: "Address Information")
                                
                                // Address Line
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Address")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("Address Line", text: $addressLine)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                                
                                // City
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("City")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("City", text: $city)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                                
                                // State
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("State")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Picker("State", selection: $state) {
                                        ForEach(indianStates, id: \.self) { state in
                                            Text(state).tag(state)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                                
                                // Pincode
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("PIN Code")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    TextField("PIN Code", text: $pincode)
                                        .keyboardType(.numberPad)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .shadow(color: .gray.opacity(0.1), radius: 2)
                                        .onChange(of: pincode) { _, newValue in
                                            if newValue.count > 6 {
                                                pincode = String(newValue.prefix(6))
                                            }
                                            // Filter only digits
                                            pincode = newValue.filter { $0.isNumber }
                                        }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        // Create the update data using encodable struct
        struct DoctorUpdateData: Encodable {
            let address_line: String
            let city: String
            let state: String
            let pincode: String
            let email: String
            let contact_number: String?
            let emergency_contact_number: String?
        }
        
        let updateData = DoctorUpdateData(
            address_line: addressLine,
            city: city,
            state: state,
            pincode: pincode,
            email: email,
            contact_number: contactNumber.isEmpty ? nil : contactNumber,
            emergency_contact_number: emergencyContactNumber.isEmpty ? nil : emergencyContactNumber
        )
        
        Task {
            do {
                // Update doctor data in Supabase
                let supabase = SupabaseController.shared
                try await supabase.update(
                    table: "doctors",
                    data: updateData,
                    where: "id",
                    equals: doctor.id
                )
                
                // Update the doctor profile locally
                let updatedDoctor = DoctorProfile(
                    id: doctor.id,
                    name: doctor.name,
                    specialization: doctor.specialization,
                    hospitalId: doctor.hospitalId,
                    qualifications: doctor.qualifications,
                    licenseNo: doctor.licenseNo,
                    experience: doctor.experience,
                    addressLine: addressLine,
                    state: state,
                    city: city,
                    pincode: pincode,
                    email: email,
                    contactNumber: contactNumber.isEmpty ? nil : contactNumber,
                    emergencyContactNumber: emergencyContactNumber.isEmpty ? nil : emergencyContactNumber
                )
                
                await MainActor.run {
                    isLoading = false
                    onSave(updatedDoctor)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// Section Title Component
struct SectionTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.teal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Password Change View
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let doctorId: String
    var onComplete: () -> Void
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Password visibility toggles
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    // Password validation states
    @State private var isValidLength = false
    @State private var hasUppercase = false
    @State private var hasNumber = false
    @State private var passwordsMatch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Updating password...")
                } else {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Password change form
                            VStack(alignment: .leading, spacing: 20) {
                                // Current Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Password")
                                        .font(.headline)
                                        .foregroundColor(.teal)
                                    
                                    HStack {
                                        if showCurrentPassword {
                                            TextField("Enter current password", text: $currentPassword)
                                        } else {
                                            SecureField("Enter current password", text: $currentPassword)
                                        }
                                        
                                        Button(action: {
                                            showCurrentPassword.toggle()
                                        }) {
                                            Image(systemName: showCurrentPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .gray.opacity(0.1), radius: 2)
                                }
                                
                                // New Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("New Password")
                                        .font(.headline)
                                        .foregroundColor(.teal)
                                    
                                    HStack {
                                        if showNewPassword {
                                            TextField("Enter new password", text: $newPassword)
                                        } else {
                                            SecureField("Enter new password", text: $newPassword)
                                        }
                                        
                                        Button(action: {
                                            showNewPassword.toggle()
                                        }) {
                                            Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .gray.opacity(0.1), radius: 2)
                                    .onChange(of: newPassword) { _, newValue in
                                        validatePassword(newValue)
                                    }
                                    
                                    // Password requirements
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Image(systemName: isValidLength ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(isValidLength ? .green : .gray)
                                            Text("At least 8 characters")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        HStack {
                                            Image(systemName: hasUppercase ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(hasUppercase ? .green : .gray)
                                            Text("At least 1 uppercase letter")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        HStack {
                                            Image(systemName: hasNumber ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(hasNumber ? .green : .gray)
                                            Text("At least 1 number")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.top, 5)
                                }
                                
                                // Confirm Password
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.headline)
                                        .foregroundColor(.teal)
                                    
                                    HStack {
                                        if showConfirmPassword {
                                            TextField("Confirm new password", text: $confirmPassword)
                                        } else {
                                            SecureField("Confirm new password", text: $confirmPassword)
                                        }
                                        
                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(color: .gray.opacity(0.1), radius: 2)
                                    .onChange(of: confirmPassword) { _, newValue in
                                        passwordsMatch = newValue == newPassword
                                    }
                                    
                                    if !confirmPassword.isEmpty {
                                        HStack {
                                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(passwordsMatch ? .green : .red)
                                            Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                                                .font(.caption)
                                                .foregroundColor(passwordsMatch ? .green : .red)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding(.horizontal)
                            
                            // Update Password Button
                            Button(action: {
                                updatePassword()
                            }) {
                                Text("Update Password")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(canUpdate ? Color.teal : Color.gray)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .disabled(!canUpdate)
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    onComplete()
                    dismiss()
                }
            } message: {
                Text("Your password has been updated successfully!")
            }
        }
    }
    
    // Check if password update is possible
    private var canUpdate: Bool {
        return !currentPassword.isEmpty && isValidLength && hasUppercase && hasNumber && passwordsMatch
    }
    
    // Validate password
    private func validatePassword(_ password: String) {
        isValidLength = password.count >= 8
        hasUppercase = password.contains { $0.isUppercase }
        hasNumber = password.contains { $0.isNumber }
        passwordsMatch = password == confirmPassword
    }
    
    // Update password in Supabase
    private func updatePassword() {
        isLoading = true
        
        Task {
            do {
                // Call Supabase to verify current password
                let supabase = SupabaseController.shared
                
                // Try to verify the current password by querying the doctor
                let result = try await supabase.select(
                    from: "doctors",
                    where: "id",
                    equals: doctorId
                )
                
                guard let doctorData = result.first,
                      let storedPassword = doctorData["password"] as? String,
                      storedPassword == currentPassword else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current password is incorrect"])
                }
                
                // Update password
                try await supabase.update(
                    table: "doctors",
                    data: ["password": newPassword],
                    where: "id",
                    equals: doctorId
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// DayScheduleCard - New component for displaying a day's schedule
struct DayScheduleCard: View {
    let day: String
    let slots: [WeeklySchedule.TimeSlot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Day header with slot count
            HStack {
                Text(day)
                    .font(.headline)
                    .foregroundColor(.teal)
                
                if !slots.isEmpty {
                    Text("(\(slots.count))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 4)
            
            if slots.isEmpty {
                Text("No slots available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
            } else {
                // Time slots scrollable list
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(slots) { slot in
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.teal)
                                    .font(.system(size: 14))
                                Text("\(formatTime(slot.start)) - \(formatTime(slot.end))")
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.teal.opacity(0.1))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(height: 250) // Fixed height for the scrollable area
            }
        }
        .frame(width: 280)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.gray.opacity(0.1), radius: 6)
    }
    
    // Helper function to format time
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm"
        
        if let date = inputFormatter.date(from: timeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h:mm a"
            return outputFormatter.string(from: date)
        }
        
        // If parsing fails, try to handle edge case of "0:00"
        if timeString == "0:00" {
            return "12:00 AM"
        }
        
        return timeString
    }
}

#Preview {
    DoctorProfileView()
} 