import SwiftUI

struct AppointmentView: View {
    let doctor: HospitalDoctor
    var existingAppointment: Appointment? = nil
    var onUpdateAppointment: ((Appointment) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedSlot: DoctorAvailabilityModels.AppointmentSlot? = nil
    @State private var navigateToReviewAndPay = false
    @State private var availableSlots: [DoctorAvailabilityModels.AppointmentSlot] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var doctorAvailability: DoctorAvailabilityModels.EfficientAvailability? = nil
    
    // Maximum date is 7 days from today
    private var maxDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    private func formatTimeSlot(_ slot: DoctorAvailabilityModels.AppointmentSlot) -> String {
        return "\(slot.startTime) to \(slot.endTime)"
    }
    
    // Function to check if a date is in the past
    private func isDateInPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let inputDate = calendar.startOfDay(for: date)
        return inputDate < today
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Calendar
                DatePicker("Select Date", 
                         selection: $selectedDate,
                         in: Date()...maxDate,
                         displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color.white)
                    .onChange(of: selectedDate) { newDate in
                        // Reset selected time when date changes
                        selectedSlot = nil
                        // Fetch available slots for the new date
                        Task {
                            await fetchAvailableSlots(for: newDate)
                        }
                    }
                
                // Time slots
                if isLoading {
                    ProgressView("Loading available slots...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if availableSlots.isEmpty {
                    Text("No available slots for this date. Please select another date or doctor.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 10), count: 2), spacing: 15) {
                            ForEach(availableSlots) { slot in
                                let isSelected = selectedSlot?.id == slot.id
                                
                                Button(action: {
                                    print("🕒 SELECTED SLOT - Display: \(slot.startTime) to \(slot.endTime)")
                                    print("🕒 SELECTED SLOT - Raw: \(slot.rawStartTime) to \(slot.rawEndTime)")
                                    selectedSlot = slot
                                }) {
                                    VStack(spacing: 4) {
                                        Text("\(slot.startTime) - \(slot.endTime)")
                                            .font(.system(size: 13, weight: .medium))
                                            .minimumScaleFactor(0.8)
                                            .lineLimit(1)
                                        
                                        Text("\(slot.remainingSlots)/\(slot.totalSlots) slots")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Color.teal : Color.white)
                                    .foregroundColor(isSelected ? .white : .black)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.teal, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Book button
                Button(action: {
                    if selectedSlot != nil {
                        navigateToReviewAndPay = true
                    }
                }) {
                    Text("Book Appointment")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSlot != nil ? Color.teal : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedSlot == nil)
                .padding()
            }
            
            NavigationLink(
                destination: ReviewAndPayView(
                    doctor: doctor,
                    appointmentDate: selectedDate,
                    appointmentTime: selectedSlot?.date ?? Date(),
                    slotId: selectedSlot?.id ?? 0,
                    startTime: selectedSlot?.startTime ?? "",
                    endTime: selectedSlot?.endTime ?? "",
                    rawStartTime: selectedSlot?.rawStartTime ?? "",
                    rawEndTime: selectedSlot?.rawEndTime ?? ""
                ),
                isActive: $navigateToReviewAndPay
            ) {
                EmptyView()
            }
            .opacity(0)
        }
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Initial fetch of doctor availability
            await fetchDoctorAvailability()
            // Fetch available slots for the initial date
            await fetchAvailableSlots(for: selectedDate)
        }
    }
    
    private func fetchDoctorAvailability() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let supabase = SupabaseController.shared
            let results = try await supabase.select(
                from: "doctor_availability_efficient",
                where: "doctor_id",
                equals: doctor.id
            )
            
            guard let availabilityData = results.first else {
                errorMessage = "This doctor doesn't have any availability schedule set up yet."
                isLoading = false
                return
            }
            
            // Parse the availability data using the same structure from BookAppointmentView
            guard let id = availabilityData["id"] as? Int,
                  let doctorId = availabilityData["doctor_id"] as? String,
                  let hospitalId = availabilityData["hospital_id"] as? String,
                  let weeklyScheduleData = availabilityData["weekly_schedule"],
                  let effectiveFromStr = availabilityData["effective_from"] as? String else {
                errorMessage = "Invalid availability data format"
                isLoading = false
                return
            }
            
            // Parse weekly schedule
            let weeklySchedule = parseWeeklySchedule(weeklyScheduleData)
            
            // Parse dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            var effectiveFrom = Date()
            if let parsedDate = dateFormatter.date(from: effectiveFromStr) {
                effectiveFrom = parsedDate
            }
            
            var effectiveUntil: Date? = nil
            if let untilStr = availabilityData["effective_until"] as? String {
                effectiveUntil = dateFormatter.date(from: untilStr)
            }
            
            // Create availability object
            let availability = DoctorAvailabilityModels.EfficientAvailability(
                id: id,
                doctorId: doctorId, 
                hospitalId: hospitalId,
                weeklySchedule: weeklySchedule,
                effectiveFrom: effectiveFrom,
                effectiveUntil: effectiveUntil,
                maxNormalPatients: availabilityData["max_normal_patients"] as? Int ?? 5,
                maxPremiumPatients: availabilityData["max_premium_patients"] as? Int ?? 2,
                createdAt: nil,
                updatedAt: nil
            )
            
            self.doctorAvailability = availability
            
        } catch {
            errorMessage = "Error fetching doctor availability: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func fetchAvailableSlots(for date: Date) async {
        guard let availability = doctorAvailability else {
            if errorMessage == nil {
                errorMessage = "Doctor availability not loaded yet"
            }
            return
        }
        
        // Check if date is more than 7 days in the future
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: selectedDay)
        
        if let days = components.day, days > 7 {
            errorMessage = "Appointments can only be booked up to 7 days in advance"
            availableSlots = []
            return
        }
        
        isLoading = true
        availableSlots = []
        
        do {
            // Get the day of week
            let weekday = calendar.component(.weekday, from: date)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1]
            
            // Get available slots for the day
            guard let daySlots = availability.weeklySchedule[dayName] else {
                // No slots for this day
                isLoading = false
                return
            }
            
            // Get existing appointments for the date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            let supabase = SupabaseController.shared
            let existingAppointments = try await supabase.select(
                from: "appointments",
                where: "doctor_id",
                equals: doctor.id
            ).filter { appointment in
                guard let appointmentDate = appointment["appointment_date"] as? String,
                      let status = appointment["status"] as? String else { return false }
                return appointmentDate == dateString && status == "upcoming"
            }
            
            // Count appointments per slot time
            var slotCounts: [String: Int] = [:]
            for appointment in existingAppointments {
                if let startTime = appointment["slot_start_time"] as? String {
                    slotCounts[startTime, default: 0] += 1
                }
            }
            
            // Convert slots to AppointmentSlot objects
            var availableSlots: [DoctorAvailabilityModels.AppointmentSlot] = []
            
            // Only process slots that are marked as available (true) in the weekly schedule
            for (timeRange, isAvailable) in daySlots {
                // Skip slots that are not available in doctor's schedule
                if !isAvailable {
                    continue
                }
                
                let components = timeRange.split(separator: "-")
                guard components.count == 2 else { continue }
                
                let startTime = String(components[0]).trimmingCharacters(in: .whitespaces)
                let endTime = String(components[1]).trimmingCharacters(in: .whitespaces)
                
                // Calculate max and remaining slots
                let maxSlots = availability.maxNormalPatients + availability.maxPremiumPatients
                let bookedSlots = slotCounts[startTime] ?? 0
                let remainingSlots = maxSlots - bookedSlots
                
                // Only include slot if there are available slots remaining
                if remainingSlots > 0 {
                    // Generate a deterministic integer ID based on the components
                    let timeComponents = startTime.split(separator: ":").map { String($0) }
                    let hour = Int(timeComponents[0]) ?? 0
                    let minute = Int(timeComponents[1]) ?? 0
                    let dayComponent = calendar.component(.day, from: date)
                    let monthComponent = calendar.component(.month, from: date)
                    
                    // Create a unique integer ID combining date and time components
                    let slotId = (dayComponent * 10000) + (monthComponent * 100) + hour
                    
                    // Format time properly for 12-hour format with AM/PM
                    let displayStartTime = formatTimeWithAMPM(startTime)
                    let displayEndTime = formatTimeWithAMPM(endTime)
                    
                    // Store standardized raw times for database (24-hour format)
                    let rawStartTime = standardizeRawTime(startTime)
                    let rawEndTime = standardizeRawTime(endTime)
                    
                    let slot = DoctorAvailabilityModels.AppointmentSlot(
                        id: slotId,
                        doctorId: doctor.id,
                        date: date,
                        startTime: displayStartTime,
                        endTime: displayEndTime,
                        rawStartTime: rawStartTime,
                        rawEndTime: rawEndTime,
                        isAvailable: true,
                        remainingSlots: remainingSlots,
                        totalSlots: maxSlots
                    )
                    availableSlots.append(slot)
                }
            }
            
            // Sort slots by start time
            availableSlots.sort { slot1, slot2 in
                // Parse time strings to compare using raw time values
                return slot1.rawStartTime < slot2.rawStartTime
            }
            
            self.availableSlots = availableSlots
            
        } catch {
            errorMessage = "Error fetching available slots: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Helper function to parse weekly schedule from different formats
    private func parseWeeklySchedule(_ data: Any?) -> [String: [String: Bool]] {
        // If data is already in correct format, use it directly
        if let scheduleData = data as? [String: [String: Bool]] {
            return scheduleData
        }
        
        // If data is a string (JSON string), try to parse it
        if let jsonString = data as? String {
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    if let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Bool]] {
                        return parsed
                    }
                    
                    // Handle possible nested structure
                    if let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]] {
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
                    // Error parsing JSON
                }
            }
        }
        
        // If it's a dictionary with different structure, try to convert it
        if let dictData = data as? [String: Any] {
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
                return result
            }
        }
        
        return [:]
    }
    
    // Helper function to format time with AM/PM
    private func formatTimeWithAMPM(_ timeString: String) -> String {
        let timeParts = timeString.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard !timeParts.isEmpty else { return timeString }
        
        let hourStr = String(timeParts[0])
        guard let hour = Int(hourStr) else { return timeString }
        
        let minute = timeParts.count > 1 ? String(timeParts[1]) : "00"
        
        if hour == 0 {
            return "12:\(minute) AM"
        } else if hour < 12 {
            return "\(hour):\(minute) AM"
        } else if hour == 12 {
            return "12:\(minute) PM"
        } else {
            return "\(hour-12):\(minute) PM"
        }
    }
    
    // Helper function to standardize raw time to consistent 24-hour format (HH:MM)
    private func standardizeRawTime(_ timeString: String) -> String {
        let timeParts = timeString.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard !timeParts.isEmpty else { return timeString }
        
        let hourStr = String(timeParts[0])
        guard let hour = Int(hourStr) else { return timeString }
        
        let minute = timeParts.count > 1 ? String(timeParts[1]) : "00"
        
        // Ensure consistent format: HH:MM
        return String(format: "%d:%@", hour, minute)
    }
}
