import Foundation

// MARK: - Doctor Availability Models Namespace
enum DoctorAvailabilityModels {
    // MARK: - Efficient Doctor Availability (for database)
    struct EfficientAvailability: Identifiable, Codable {
        let id: Int
        let doctorId: String
        let hospitalId: String
        let weeklySchedule: [String: [String: Bool]]
        let effectiveFrom: Date
        let effectiveUntil: Date?
        let maxNormalPatients: Int
        let maxPremiumPatients: Int
        let createdAt: Date?
        let updatedAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case id
            case doctorId = "doctor_id"
            case hospitalId = "hospital_id"
            case weeklySchedule = "weekly_schedule"
            case effectiveFrom = "effective_from"
            case effectiveUntil = "effective_until"
            case maxNormalPatients = "max_normal_patients"
            case maxPremiumPatients = "max_premium_patients"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
        
        // Helper method to check if a specific date and time slot is available
        func isSlotAvailable(on date: Date, at time: String) -> Bool {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1] // weekday is 1-based
            
            // Check if date is within effective range
            let startOfDay = calendar.startOfDay(for: date)
            let startOfEffectiveFrom = calendar.startOfDay(for: effectiveFrom)
            
            guard startOfDay >= startOfEffectiveFrom else { return false }
            
            if let until = effectiveUntil {
                let startOfUntil = calendar.startOfDay(for: until)
                guard startOfDay <= startOfUntil else { return false }
            }
            
            // Check if the time slot exists and is available
            return weeklySchedule[dayName]?[time] ?? false
        }
        
        // Helper method to get all available slots for a specific date
        func getAvailableSlots(for date: Date) -> [(startTime: String, endTime: String)] {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let dayName = dayNames[weekday - 1]
            
            // Check if date is within effective range
            let startOfDay = calendar.startOfDay(for: date)
            let startOfEffectiveFrom = calendar.startOfDay(for: effectiveFrom)
            
            guard startOfDay >= startOfEffectiveFrom else { return [] }
            
            if let until = effectiveUntil {
                let startOfUntil = calendar.startOfDay(for: until)
                guard startOfDay <= startOfUntil else { return [] }
            }
            
            // Get available slots for the day
            guard let daySchedule = weeklySchedule[dayName] else { return [] }
            
            print("📊 DoctorAvailability - Getting available slots for \(dayName)")
            print("📊 DoctorAvailability - Day schedule has \(daySchedule.count) slots")
            
            // FIXED: Process all slots from the day's schedule and only include ones marked as available
            var availableSlots: [(startTime: String, endTime: String)] = []
            
            // Filter slots that are marked as available (true)
            for (timeRange, isAvailable) in daySchedule {
                if isAvailable {
                    // Parse the time range (format: "start-end")
                    let components = timeRange.split(separator: "-")
                    if components.count == 2 {
                        let startTime = String(components[0])
                        let endTime = String(components[1])
                        availableSlots.append((startTime: startTime, endTime: endTime))
                        print("✅ DoctorAvailability - Added available slot: \(startTime) - \(endTime)")
                    } else {
                        print("⚠️ DoctorAvailability - Invalid time range format: \(timeRange)")
                    }
                } else {
                    print("⏭️ DoctorAvailability - Skipping unavailable slot: \(timeRange)")
                }
            }
            
            // Sort slots by start time
            availableSlots.sort { slot1, slot2 in
                return slot1.startTime < slot2.startTime
            }
            
            return availableSlots
        }
    }
    
    // MARK: - Appointment Availability (for UI)
    struct AppointmentSlot: Identifiable, Codable {
        let id: Int
        let doctorId: String
        let date: Date
        let startTime: String
        let endTime: String
        let rawStartTime: String  // For database storage (24-hour format: "HH:MM")
        let rawEndTime: String    // For database storage (24-hour format: "HH:MM")
        let isAvailable: Bool
        let remainingSlots: Int
        let totalSlots: Int
        
        // Helper method to format time string for display
        static func formatTimeForDisplay(_ timeString: String) -> String {
            // Clean the input time string
            var cleanedTimeString = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Make sure it has seconds component if needed
            if cleanedTimeString.count == 5 && cleanedTimeString.contains(":") {
                cleanedTimeString += ":00"
            }
            
            // Try multiple formats to parse the time
            let inputFormats = ["HH:mm:ss", "HH:mm", "h:mm a", "h:mm:ss a"]
            let formatter = DateFormatter()
            
            var parsedDate: Date? = nil
            
            // Try each format until one works
            for format in inputFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: cleanedTimeString) {
                    parsedDate = date
                    break
                }
            }
            
            // If we got a valid date, format it for display
            if let parsedDate = parsedDate {
                formatter.dateFormat = "h:mm a"
                let result = formatter.string(from: parsedDate)
                print("🕒 Formatted \(timeString) to \(result) for display")
                return result
            }
            
            print("⚠️ Could not format time: \(timeString) - using as is")
            return timeString
        }
        
        // Helper method to convert display time to raw time
        static func convertToRawTime(_ displayTime: String) -> String {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            
            // Try to parse the display time
            if let date = displayFormatter.date(from: displayTime) {
                // Format to raw time format
                let rawFormatter = DateFormatter()
                rawFormatter.dateFormat = "HH:mm:ss"
                let result = rawFormatter.string(from: date)
                print("🕒 Converted \(displayTime) to \(result) for storage")
                return result
            }
            
            // Try parsing if input is already in 24-hour format
            let alternateFormatter = DateFormatter()
            alternateFormatter.dateFormat = "HH:mm"
            
            if let date = alternateFormatter.date(from: displayTime) {
                let rawFormatter = DateFormatter()
                rawFormatter.dateFormat = "HH:mm:ss"
                let result = rawFormatter.string(from: date)
                print("🕒 Converted \(displayTime) to \(result) for storage (24h format)")
                return result
            }
            
            // If all else fails, try to manually parse
            let parts = displayTime.split(separator: " ")
            guard parts.count == 2,
                  let timePart = parts.first,
                  let ampm = parts.last else {
                print("⚠️ Could not convert time: \(displayTime) - using as is")
                return displayTime
            }
            
            let timeComponents = timePart.split(separator: ":")
            guard let hourStr = timeComponents.first,
                  let hour = Int(hourStr) else {
                print("⚠️ Could not parse hour from: \(displayTime) - using as is")
                return displayTime
            }
            
            let minute = timeComponents.count > 1 ? String(timeComponents[1]) : "00"
            
            var adjustedHour = hour
            if ampm.uppercased() == "PM" && hour < 12 {
                adjustedHour += 12
            } else if ampm.uppercased() == "AM" && hour == 12 {
                adjustedHour = 0
            }
            
            let result = String(format: "%02d:%@:00", adjustedHour, minute)
            print("🕒 Manually converted \(displayTime) to \(result) for storage")
            return result
        }
    }
}