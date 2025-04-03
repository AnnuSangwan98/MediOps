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
    @ObservedObject private var translationManager = TranslationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
    
    // Function to check if a time slot is in the past
    private func isSlotInPast(_ slot: DoctorAvailabilityModels.AppointmentSlot) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // If the date is in the past, the slot is in the past
        if isDateInPast(slot.date) {
            return true
        }
        
        // If it's today, check the time
        if calendar.isDateInToday(slot.date) {
            // Parse the slot's raw start time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            // Convert substring to string before using it
            let timeString = String(slot.rawStartTime.prefix(5))
            
            if let slotTime = timeFormatter.date(from: timeString) {
                // Create a date by combining today's date with the slot time
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let slotTimeComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
                components.hour = slotTimeComponents.hour
                components.minute = slotTimeComponents.minute
                
                if let slotDateTime = calendar.date(from: components) {
                    // Add a buffer of 15 minutes
                    let bufferedNow = calendar.date(byAdding: .minute, value: 15, to: now) ?? now
                    return slotDateTime < bufferedNow
                }
            }
        }
        
        return false
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Calendar
                DatePicker("select_date".localized, 
                         selection: $selectedDate,
                         in: Date()...maxDate,
                         displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(themeManager.colors.primary)
                    .padding()
                    .background(Color.white)
                    .onChange(of: selectedDate) { newDate in
                        selectedSlot = nil
                        Task {
                            await fetchAvailableSlots(for: newDate)
                        }
                    }
                
                // Time slots
                if isLoading {
                    ProgressView("loading_slots".localized)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.primary))
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(themeManager.colors.error)
                        .padding()
                } else if availableSlots.isEmpty {
                    Text("no_available_slots".localized)
                        .foregroundColor(themeManager.colors.subtext)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 10), count: 2), spacing: 15) {
                            ForEach(availableSlots) { slot in
                                let isSelected = selectedSlot?.id == slot.id
                                let isPast = isSlotInPast(slot)
                                let isFullyBooked = slot.remainingSlots == 0
                                
                                Button(action: {
                                    if !isPast && !isFullyBooked {
                                        selectedSlot = slot
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text("\(slot.startTime) - \(slot.endTime)")
                                            .font(.system(size: 13, weight: .medium))
                                            .minimumScaleFactor(0.8)
                                            .lineLimit(1)
                                        
                                        Text("\(slot.remainingSlots)/\(slot.totalSlots) slots".localized)
                                            .font(.system(size: 11))
                                            .foregroundColor(isFullyBooked ? themeManager.colors.error : themeManager.colors.subtext)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? themeManager.colors.primary : Color.white)
                                    .foregroundColor(isSelected ? .white : (isFullyBooked ? themeManager.colors.subtext : themeManager.colors.text))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isFullyBooked ? themeManager.colors.subtext : themeManager.colors.primary, lineWidth: 1)
                                    )
                                    .opacity(isPast || isFullyBooked ? 0.5 : 1.0)
                                }
                                .disabled(isPast || isFullyBooked)
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
                    Text("book_appointment".localized)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSlot != nil ? themeManager.colors.primary : themeManager.colors.subtext)
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
        .navigationTitle("book_appointment".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchDoctorAvailability()
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
                errorMessage = "no_doctor_availability".localized
                isLoading = false
                return
            }
            
            // Parse the availability data using the same structure from BookAppointmentView
            guard let id = availabilityData["id"] as? Int,
                  let doctorId = availabilityData["doctor_id"] as? String,
                  let hospitalId = availabilityData["hospital_id"] as? String,
                  let weeklyScheduleData = availabilityData["weekly_schedule"],
                  let effectiveFromStr = availabilityData["effective_from"] as? String else {
                errorMessage = "invalid_availability_data".localized
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
            errorMessage = "error_fetching_availability".localized + ": \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func fetchAvailableSlots(for date: Date) async {
        guard let availability = doctorAvailability else { return }
        
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        
        do {
            // First, fetch the doctor's max_appointments limit
            let supabase = SupabaseController.shared
            let doctorResults = try await supabase.select(
                from: "doctors",
                where: "id",
                equals: doctor.id
            )
            
            guard let doctorData = doctorResults.first,
                  let maxAppointments = doctorData["max_appointments"] as? Int else {
                errorMessage = "Could not fetch doctor's appointment limit"
                isLoading = false
                return
            }
            
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
            
            // Fetch all upcoming appointments for this doctor and date
            let existingAppointments = try await supabase.select(
                from: "appointments",
                where: "doctor_id",
                equals: doctor.id
            ).filter { appointment in
                guard let appointmentDate = appointment["appointment_date"] as? String,
                      let status = appointment["status"] as? String else { return false }
                return appointmentDate == dateString && status == "upcoming"
            }
            
            print("📊 Found \(existingAppointments.count) existing appointments for date: \(dateString)")
            
            // Count appointments per slot time
            var slotCounts: [String: Int] = [:]
            for appointment in existingAppointments {
                if let startTime = appointment["slot_start_time"] as? String {
                    let standardizedTime = standardizeRawTime(startTime)
                    slotCounts[standardizedTime] = (slotCounts[standardizedTime] ?? 0) + 1
                    print("📝 Slot \(standardizedTime) has \(slotCounts[standardizedTime]!) bookings")
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
                
                // Standardize the time format for comparison
                let standardizedStartTime = standardizeRawTime(startTime)
                
                // Calculate remaining slots for this specific time slot
                let bookedSlots = slotCounts[standardizedStartTime] ?? 0
                let remainingSlots = maxAppointments - bookedSlots
                
                print("🕒 Processing slot \(standardizedStartTime): booked=\(bookedSlots), remaining=\(remainingSlots), max=\(maxAppointments)")
                
                // Create slot even if no remaining slots (to show as fully booked)
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
                
                let isSlotAvailable = remainingSlots > 0
                
                let slot = DoctorAvailabilityModels.AppointmentSlot(
                    id: slotId,
                    doctorId: doctor.id,
                    date: date,
                    startTime: displayStartTime,
                    endTime: displayEndTime,
                    rawStartTime: rawStartTime,
                    rawEndTime: rawEndTime,
                    isAvailable: isSlotAvailable,
                    remainingSlots: remainingSlots,
                    totalSlots: maxAppointments
                )
                
                print("🎫 Created slot: \(displayStartTime)-\(displayEndTime) (Available: \(isSlotAvailable), Remaining: \(remainingSlots))")
                availableSlots.append(slot)
            }
            
            // Sort slots by start time using 24-hour format raw times for accurate sorting
            availableSlots.sort { slot1, slot2 in
                // Convert raw times to comparable format (remove any whitespace and ensure HH:MM format)
                let time1 = slot1.rawStartTime.trimmingCharacters(in: .whitespaces)
                let time2 = slot2.rawStartTime.trimmingCharacters(in: .whitespaces)
                return time1 < time2
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
        let cleanTime = timeString.trimmingCharacters(in: .whitespaces)
        let components = cleanTime.split(separator: ":")
        
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return cleanTime
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
}
