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
        let isAvailable: Bool
        let remainingSlots: Int
        let totalSlots: Int
        
        // Helper method to format time string for display
        static func formatTimeForDisplay(_ timeString: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            
            if let date = formatter.date(from: timeString) {
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: date)
            }
            
            return timeString
        }
    }
}