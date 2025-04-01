import SwiftUI
import class MediOps.SupabaseController

// Notification model for recent activities
struct DoctorNotification: Identifiable {
    let id = UUID()
    let message: String
    let date: Date
    let type: NotificationType
    let appointmentId: String
    var isRead: Bool = false
    
    enum NotificationType {
        case booked, cancelled, completed
        
        var color: Color {
            switch self {
            case .booked:
                return .blue
            case .cancelled:
                return .red
            case .completed:
                return .green
            }
        }
        
        var icon: String {
            switch self {
            case .booked:
                return "calendar.badge.plus"
            case .cancelled:
                return "calendar.badge.minus"
            case .completed:
                return "checkmark.circle"
            }
        }
    }
}

// Appointment Model - Using unique name to avoid conflicts
struct DoctorAppointmentModel: Identifiable {
    let id: String
    let patientId: String
    let patientName: String // Will be fetched separately
    let hospitalId: String
    let hospitalName: String // Will be fetched separately
    let appointmentDate: Date
    let bookingTime: Date
    let status: AppointmentStatusType
    let reason: String
    let isDone: Bool
    let isPremium: Bool?
    let slotId: Int
    let slotTime: String // Time slot
    let slotEndTime: String? // End time of the slot
}

// Unique enum for appointment status
enum AppointmentStatusType: String {
    case upcoming = "upcoming"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

struct DoctorHomeView: View {
    @State private var showProfileView = false
    @State private var navigateToRoleSelection = false
    @State private var selectedTab = "Upcoming"
    @State private var showNotifications = false
    
    // Appointment state
    @State private var isLoadingAppointments = true
    @State private var appointments: [DoctorAppointmentModel] = []
    @State private var notifications: [DoctorNotification] = []
    @State private var error: String? = nil
    @State private var doctorName: String = ""
    @State private var isLoadingDoctorInfo = true
    
    // Stats counters
    @State private var todayCount = 0
    @State private var upcomingCount = 0
    @State private var completedCount = 0
    
    var hasUnreadNotifications: Bool {
        notifications.contains { !$0.isRead }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                if isLoadingDoctorInfo {
                                    Text("Welcome, ")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    HStack(spacing: 10) {
                                        Text("Dr.")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    }
                                } else {
                                    Text("Welcome, ")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    Text(doctorName.isEmpty ? "Dr. Doctor" : doctorName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            }
                            Spacer()
                            
                        // Notification Bell
                            Button(action: {
                            showNotifications.toggle()
                            if showNotifications {
                                markNotificationsAsRead()
                            }
                        }) {
                            ZStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.teal)
                                
                                if hasUnreadNotifications {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 7, y: -7)
                                }
                            }
                            .padding(.trailing, 15)
                        }
                        
                        // Profile Link
                        NavigationLink(destination: DoctorProfileView()) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                    // Statistics Cards
                    HStack(spacing: 15) {
                        // Today's Appointments
                        StatisticsCard(
                            value: "\(todayCount)",
                            title: "Today",
                            icon: "calendar",
                            iconColor: .teal
                        )
                        
                        // Remaining Appointments
                        StatisticsCard(
                            value: "\(upcomingCount)",
                            title: "Upcoming",
                            icon: "clock.fill",
                            iconColor: .orange
                        )
                        
                        // Completed Appointments
                        StatisticsCard(
                            value: "\(completedCount)",
                            title: "Completed",
                            icon: "checkmark.circle.fill",
                            iconColor: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Appointment Overview Header
                        VStack(alignment: .leading, spacing: 15) {
                        Text("Appointment Overview")
                                .font(.title2)
                                .fontWeight(.bold)
                        
                        // Appointment Tabs
                        HStack {
                            TabButton(title: "Upcoming", selected: $selectedTab)
                            TabButton(title: "Cancelled", selected: $selectedTab)
                            TabButton(title: "Completed", selected: $selectedTab)
                        }
                    }
                                .padding(.horizontal)
                            
                    // Only this part is scrollable - Appointment List
                    if isLoadingAppointments {
                        ProgressView("Loading appointments...")
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack {
                                if let errorMessage = error {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: .gray.opacity(0.1), radius: 5)
                                        .padding(.horizontal)
                                } else {
                                    let filteredAppointments = appointments.filter { 
                                        $0.status.rawValue.lowercased() == selectedTab.lowercased() 
                                    }
                                    
                                    if filteredAppointments.isEmpty {
                                        Text("No \(selectedTab.lowercased()) appointments found")
                                .foregroundColor(.gray)
                                            .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                                            .padding(.horizontal)
                                    } else {
                                        ForEach(filteredAppointments) { appointment in
                                            DoctorAppointmentCard(appointment: appointment)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                // Add spacing at the bottom for better scrolling
                                Spacer()
                                    .frame(height: 50)
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $navigateToRoleSelection) {
                RoleSelectionView()
            }
            .onAppear {
                fetchDoctorData()
                fetchDoctorAppointments()
            }
            .overlay(
                ZStack {
                    if showNotifications {
                        // Semi-transparent background
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showNotifications = false
                            }
                            .transition(.opacity)
                        
                        // Notification popup centered on screen
                        NotificationsPopover(notifications: notifications)
                            .frame(maxWidth: 320)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            )
            .animation(.easeInOut(duration: 0.2), value: showNotifications)
        }
    }
    
    private func fetchDoctorData() {
        isLoadingDoctorInfo = true
        
        // Get doctor ID from UserDefaults
        guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id") else {
            print("ERROR: Doctor ID not found in UserDefaults")
            // Set loading to false and continue with empty doctor name
            isLoadingDoctorInfo = false
            return
        }
        
        print("FETCH DOCTOR: Loading doctor info for ID: \(doctorId)")
        
        Task {
            do {
                let supabase = SupabaseController.shared
                
                // Fetch doctor information
                let result = try await supabase.select(
                    from: "doctors",
                    where: "id",
                    equals: doctorId
                )
                
                if result.isEmpty {
                    print("FETCH DOCTOR: No records found for doctor ID: \(doctorId)")
                    await MainActor.run {
                        isLoadingDoctorInfo = false
                        // Keep doctorName empty, UI will show fallback
                    }
                    return
                }
                
                guard let doctorData = result.first else {
                    print("FETCH DOCTOR: Result is not empty but first item is nil")
                    await MainActor.run {
                        isLoadingDoctorInfo = false
                    }
                    return
                }
                
                // Extract doctor name with detailed logging
                if let name = doctorData["name"] as? String, !name.isEmpty {
                    print("FETCH DOCTOR: Successfully retrieved doctor name: \(name)")
                    
                    // Ensure the name includes the Dr. prefix
                    let formattedName: String
                    if name.hasPrefix("Dr.") || name.hasPrefix("Dr. ") {
                        formattedName = name // Keep as is if already has Dr. prefix
                    } else {
                        formattedName = "Dr. \(name)" // Add prefix if not present
                    }
                    
                    print("FETCH DOCTOR: Formatted name with Dr. prefix: \(formattedName)")
                    
                    await MainActor.run {
                        self.doctorName = formattedName
                        isLoadingDoctorInfo = false
                    }
                } else {
                    print("FETCH DOCTOR: Doctor record found but name field is missing, empty, or not a string")
                    
                    // Debug available fields
                    let availableFields = Array(doctorData.keys).joined(separator: ", ")
                    print("FETCH DOCTOR: Available fields: \(availableFields)")
                    
                    // Try to extract ID as a last resort if name is not available
                    let doctorDisplayName: String
                    if let id = doctorData["id"] as? String, !id.isEmpty {
                        doctorDisplayName = "Dr. \(id)" // Always add prefix to ID
                        print("FETCH DOCTOR: Using ID as fallback with Dr. prefix: \(doctorDisplayName)")
                    } else {
                        doctorDisplayName = "Dr. Doctor" // Default with prefix
                        print("FETCH DOCTOR: Using default name with Dr. prefix")
                    }
                    
                    await MainActor.run {
                        self.doctorName = doctorDisplayName
                        isLoadingDoctorInfo = false
                    }
                }
            } catch {
                print("FETCH DOCTOR ERROR: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingDoctorInfo = false
                    // Keep doctorName empty, UI will show fallback
                }
            }
        }
    }
    
    private func fetchDoctorAppointments() {
        isLoadingAppointments = true
        error = nil
        
        // Get doctor ID from UserDefaults
        guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id") else {
            error = "Doctor ID not found. Please log in again."
            isLoadingAppointments = false
            return
        }
        
        Task {
            do {
                let supabase = SupabaseController.shared
                
                // Use standard select method with specific fields
                let result = try await supabase.select(
                    from: "appointments",
                    columns: "id, patient_id, doctor_id, hospital_id, appointment_date, booking_time, status, reason, isdone, is_premium, availability_slot_id, slot_time, slot_end_time",
                    where: "doctor_id",
                    equals: doctorId
                )
                
                // Parse result
                let appointments = try parseAppointments(result)
                
                // Fetch additional details for each appointment (patient, hospital)
                var enhancedAppointments: [DoctorAppointmentModel] = []
                
                for appointment in appointments {
                    // Load patient details
                    var patientName = "Unknown Patient"
                    if let patientResult = try? await supabase.select(
                        from: "patients",
                        where: "patient_id",
                        equals: appointment.patientId
                    ).first, let name = patientResult["name"] as? String {
                        patientName = name
                    }
                    
                    // Load hospital details
                    var hospitalName = "Unknown Hospital"
                    if let hospitalResult = try? await supabase.select(
                        from: "hospitals",
                        where: "id",
                        equals: appointment.hospitalId
                    ).first, let name = hospitalResult["name"] as? String {
                        hospitalName = name
                    }
                    
                    // Create enhanced appointment - keep original slot times
                    let enhancedAppointment = DoctorAppointmentModel(
                        id: appointment.id,
                        patientId: appointment.patientId,
                        patientName: patientName,
                        hospitalId: appointment.hospitalId,
                        hospitalName: hospitalName,
                        appointmentDate: appointment.appointmentDate,
                        bookingTime: appointment.bookingTime,
                        status: appointment.status,
                        reason: appointment.reason,
                        isDone: appointment.isDone,
                        isPremium: appointment.isPremium,
                        slotId: appointment.slotId,
                        slotTime: appointment.slotTime,
                        slotEndTime: appointment.slotEndTime
                    )
                    
                    enhancedAppointments.append(enhancedAppointment)
                }
                
                // Generate notifications from appointments (recent bookings, cancellations, completions)
                let recentNotifications = generateNotifications(from: enhancedAppointments)
                
                // Update UI on main thread
                await MainActor.run {
                    self.appointments = enhancedAppointments
                    self.notifications = recentNotifications
                    updateCounts(enhancedAppointments)
                    isLoadingAppointments = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load appointments: \(error.localizedDescription)"
                    isLoadingAppointments = false
                }
            }
        }
    }
    
    private func markNotificationsAsRead() {
        // Mark all notifications as read
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
    
    private func generateNotifications(from appointments: [DoctorAppointmentModel]) -> [DoctorNotification] {
        // Sort appointments by booking time, most recent first
        let sortedAppointments = appointments.sorted { $0.bookingTime > $1.bookingTime }
        
        // Take up to 10 most recent appointments
        let recentAppointments = Array(sortedAppointments.prefix(10))
        
        // Get existing notifications to preserve read status
        let existingNotificationIds = Dictionary(uniqueKeysWithValues: 
            notifications.map { ($0.appointmentId, $0.isRead) })
        
        // Convert to notifications
        return recentAppointments.map { appointment in
            let type: DoctorNotification.NotificationType
            let message: String
            
            switch appointment.status {
            case .upcoming:
                type = .booked
                message = "New appointment with \(appointment.patientName) booked for \(formatDate(appointment.appointmentDate))"
            case .cancelled:
                type = .cancelled
                message = "Appointment with \(appointment.patientName) on \(formatDate(appointment.appointmentDate)) was cancelled"
            case .completed:
                type = .completed
                message = "Appointment with \(appointment.patientName) on \(formatDate(appointment.appointmentDate)) was completed"
            }
            
            // Preserve read status for existing notifications, otherwise mark as unread
            let isRead = existingNotificationIds[appointment.id] ?? false
            
            var notification = DoctorNotification(
                message: message,
                date: appointment.bookingTime,
                type: type,
                appointmentId: appointment.id
            )
            notification.isRead = isRead
            return notification
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func parseAppointments(_ data: [[String: Any]]) throws -> [DoctorAppointmentModel] {
        // Initialize date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        // Time formatter for slot times
        let slotTimeFormatter = DateFormatter()
        slotTimeFormatter.dateFormat = "HH:mm:ss"
        
        return try data.map { appointmentData in
            // Required fields
            guard let id = appointmentData["id"] as? String else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing appointment ID"])
            }
            
            guard let patientId = appointmentData["patient_id"] as? String else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing patient ID"])
            }
            
            guard let hospitalId = appointmentData["hospital_id"] as? String else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing hospital ID"])
            }
            
            guard let appointmentDateString = appointmentData["appointment_date"] as? String,
                  let appointmentDate = dateFormatter.date(from: appointmentDateString) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid appointment date"])
            }
            
            guard let statusString = appointmentData["status"] as? String,
                  let status = AppointmentStatusType(rawValue: statusString.lowercased()) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid status"])
            }
            
            guard let slotId = appointmentData["availability_slot_id"] as? Int else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing slot ID"])
            }
            
            // Optional fields with defaults
            let bookingTimeString = appointmentData["booking_time"] as? String ?? ""
            let bookingTime = timeFormatter.date(from: bookingTimeString) ?? Date()
            
            let reason = appointmentData["reason"] as? String ?? ""
            let isDone = appointmentData["isdone"] as? Bool ?? false
            let isPremium = appointmentData["is_premium"] as? Bool
            
            // Get slot times directly from the appointment
            var slotTime = ""
            if let slotTimeString = appointmentData["slot_time"] as? String {
                // Format time from "HH:MM:SS" to "HH:MM AM/PM"
                if let timeDate = slotTimeFormatter.date(from: slotTimeString) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "h:mm a"
                    slotTime = displayFormatter.string(from: timeDate)
                } else {
                    slotTime = slotTimeString
                }
            }
            
            // Handle slot end time
            var slotEndTime: String? = nil
            if let endTimeString = appointmentData["slot_end_time"] as? String {
                if let timeDate = slotTimeFormatter.date(from: endTimeString) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "h:mm a"
                    slotEndTime = displayFormatter.string(from: timeDate)
                } else {
                    slotEndTime = endTimeString
                }
            }
            
            // Debug slot times
            print("Appointment ID: \(id)")
            print("Raw slot_time: \(appointmentData["slot_time"] as? String ?? "nil")")
            print("Raw slot_end_time: \(appointmentData["slot_end_time"] as? String ?? "nil")")
            print("Formatted slotTime: \(slotTime)")
            print("Formatted slotEndTime: \(slotEndTime ?? "nil")")
            
            // Joined fields
            let patientName = appointmentData["patient_name"] as? String ?? "Unknown Patient"
            let hospitalName = appointmentData["hospital_name"] as? String ?? "Unknown Hospital"
            
            return DoctorAppointmentModel(
                id: id,
                patientId: patientId,
                patientName: patientName,
                hospitalId: hospitalId,
                hospitalName: hospitalName,
                appointmentDate: appointmentDate,
                bookingTime: bookingTime,
                status: status,
                reason: reason,
                isDone: isDone,
                isPremium: isPremium,
                slotId: slotId,
                slotTime: slotTime,
                slotEndTime: slotEndTime
            )
        }
    }
    
    private func updateCounts(_ appointments: [DoctorAppointmentModel]) {
        // Get today's date for comparison
        let today = Calendar.current.startOfDay(for: Date())
        
        // Count today's appointments
        todayCount = appointments.filter { 
            Calendar.current.isDate($0.appointmentDate, inSameDayAs: today) && 
            $0.status == .upcoming 
        }.count
        
        // Count by status
        upcomingCount = appointments.filter { $0.status == .upcoming }.count
        completedCount = appointments.filter { $0.status == .completed }.count
    }
}

// Notifications Popover View
struct NotificationsPopover: View {
    let notifications: [DoctorNotification]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            if notifications.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No recent notifications")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                            
                            if notification.id != notifications.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 300)
            }
        }
        .frame(width: 300)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 10)
        .zIndex(100)
    }
}

// Individual Notification Row
struct NotificationRow: View {
    let notification: DoctorNotification
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(notification.type.color)
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
    }
}

// Appointment Card View
struct DoctorAppointmentCard: View {
    let appointment: DoctorAppointmentModel
    @State private var showDetails = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: appointment.appointmentDate)
    }
    
    private var formattedTime: String {
        // Empty cases first
        if appointment.slotTime.isEmpty {
            if let endTime = appointment.slotEndTime, !endTime.isEmpty {
                return endTime
            }
            return "—" // Em dash for completely missing time
        }
        
        // When we have a start time
        if let endTime = appointment.slotEndTime, !endTime.isEmpty {
            return "\(appointment.slotTime) - \(endTime)"
        } else {
            return appointment.slotTime
        }
    }
    
    var body: some View {
        Button(action: {
            showDetails = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Patient info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.patientName)
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(appointment.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(appointment.status.color.opacity(0.2))
                        .foregroundColor(appointment.status.color)
                        .cornerRadius(6)
                }
                
                Divider()
                
                // Appointment details
                HStack(spacing: 15) {
                    // Date
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.teal)
                        }
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Time
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundColor(.teal)
                        }
                        
                        if !appointment.slotTime.isEmpty {
                            if let endTime = appointment.slotEndTime, !endTime.isEmpty {
                                // Both times available
                                HStack(spacing: 3) {
                                    Text(appointment.slotTime)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    Text("to")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(endTime)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                }
                            } else {
                                // Only start time
                                Text(appointment.slotTime)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        } else if let endTime = appointment.slotEndTime, !endTime.isEmpty {
                            // Only end time
                            Text(endTime)
                                .font(.subheadline)
                                .foregroundColor(.black)
                        } else {
                            // No time information
                            Text("—")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Premium indicator if applicable
                    if let isPremium = appointment.isPremium, isPremium {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Reason (if provided)
                if !appointment.reason.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reason")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(appointment.reason)
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .lineLimit(2)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.1), radius: 5)
            // Remove color scheme to avoid blue tint on button press
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showDetails) {
            DoctorAppointmentDetailsView(appointment: appointment)
        }
    }
}

// Statistics Card
struct StatisticsCard: View {
    let value: String
    let title: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
                Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

// Tab Button
struct TabButton: View {
    let title: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: {
            selected = title
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: selected == title ? .semibold : .regular))
                    .foregroundColor(selected == title ? .black : .gray)
                
                // Indicator
                Rectangle()
                    .fill(selected == title ? Color.teal : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(3)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DoctorDashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // TODO: Implement action
        }) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

#Preview {
    DoctorHomeView()
}
