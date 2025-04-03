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
    case missed = "missed"
    
    var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        case .missed:
            return .orange
        }
    }
}

struct DoctorHomeView: View {
    @State private var showProfileView = false
    @State private var navigateToRoleSelection = false
    @State private var selectedTab = "Upcoming"
    
    // Appointment state
    @State private var isLoadingAppointments = true
    @State private var appointments: [DoctorAppointmentModel] = []
    @State private var error: String? = nil
    @State private var doctorName: String = ""
    @State private var isLoadingDoctorInfo = true
    @State private var autoRefreshTimer: Timer? = nil
    
    // Stats counters
    @State private var todayCount = 0
    @State private var upcomingCount = 0
    @State private var completedCount = 0
    @State private var missedCount = 0
    
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
                            iconColor: .blue
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
                            TabButton(title: "Missed", selected: $selectedTab)
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
                                        let tabLowercased = selectedTab.lowercased()
                                        let statusLowercased = $0.status.rawValue.lowercased()
                                        return statusLowercased == tabLowercased
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
                        .refreshable {
                            // Refresh data when pulled down
                            await refreshData()
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
                startAutoRefreshTimer()
            }
            .onDisappear {
                stopAutoRefreshTimer()
            }
        }
    }
    
    // Start a timer to periodically check for missed appointments
    private func startAutoRefreshTimer() {
        // Cancel any existing timer
        stopAutoRefreshTimer()
        
        // Start a new timer that fires every 60 seconds
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                print("🔄 Auto-refresh timer fired - checking for missed appointments")
                await refreshData()
            }
        }
    }
    
    // Stop the auto-refresh timer
    private func stopAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    // Add a new async function to refresh all data
    private func refreshData() async {
        // Show loading state
        await MainActor.run {
            isLoadingDoctorInfo = true
            isLoadingAppointments = true
        }
        
        // Create a task group to fetch all data concurrently
        await withTaskGroup(of: Void.self) { group in
            // Fetch doctor data
            group.addTask {
                await fetchDoctorDataAsync()
            }
            
            // Fetch appointments
            group.addTask {
                await fetchDoctorAppointmentsAsync()
            }
            
            // Wait for all tasks to complete
            await group.waitForAll()
        }
    }
    
    // Async version of fetchDoctorData
    private func fetchDoctorDataAsync() async {
        guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id") else {
            await MainActor.run {
                isLoadingDoctorInfo = false
            }
            return
        }
        
        do {
            let supabase = SupabaseController.shared
            let result = try await supabase.select(
                from: "doctors",
                where: "id",
                equals: doctorId
            )
            
            if let doctorData = result.first {
                if let name = doctorData["name"] as? String, !name.isEmpty {
                    let formattedName: String
                    if name.hasPrefix("Dr.") || name.hasPrefix("Dr. ") {
                        formattedName = name
                    } else {
                        formattedName = "Dr. \(name)"
                    }
                    
                    await MainActor.run {
                        self.doctorName = formattedName
                        isLoadingDoctorInfo = false
                    }
                } else {
                    // Fallback to ID or default
                    let doctorDisplayName: String
                    if let id = doctorData["id"] as? String, !id.isEmpty {
                        doctorDisplayName = "Dr. \(id)"
                    } else {
                        doctorDisplayName = "Dr. Doctor"
                    }
                    
                    await MainActor.run {
                        self.doctorName = doctorDisplayName
                        isLoadingDoctorInfo = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoadingDoctorInfo = false
                }
            }
        } catch {
            await MainActor.run {
                isLoadingDoctorInfo = false
            }
        }
    }
    
    // Async version of fetchDoctorAppointments
    private func fetchDoctorAppointmentsAsync() async {
        guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id") else {
            await MainActor.run {
                error = "Doctor ID not found. Please log in again."
                isLoadingAppointments = false
            }
            return
        }
        
        do {
            let supabase = SupabaseController.shared
            
            // First fetch appointments with all required fields
            let appointmentResults = try await supabase.select(
                from: "appointments",
                columns: "id, patient_id, doctor_id, hospital_id, appointment_date, booking_time, status, reason, isdone, is_premium, slot_start_time, slot_end_time, slot",
                where: "doctor_id",
                equals: doctorId
            )
            
            print("📊 Found \(appointmentResults.count) appointments for doctor: \(doctorId)")
            
            // Process each appointment
            var enhancedAppointments: [DoctorAppointmentModel] = []
            let now = Date()
            
            for appointmentData in appointmentResults {
                // Debug print
                print("Processing appointment: \(appointmentData)")
                
                // Required fields
                guard let id = appointmentData["id"] as? String,
                      let patientId = appointmentData["patient_id"] as? String,
                      let hospitalId = appointmentData["hospital_id"] as? String,
                      let appointmentDateString = appointmentData["appointment_date"] as? String,
                      var statusString = appointmentData["status"] as? String else {
                    print("⚠️ Skipping appointment due to missing required fields")
                    continue
                }
                
                // Parse appointment date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                guard let appointmentDate = dateFormatter.date(from: appointmentDateString) else {
                    print("⚠️ Could not parse date: \(appointmentDateString)")
                    continue
                }
                
                // Optional fields with defaults
                let bookingTimeString = appointmentData["booking_time"] as? String ?? ""
                let bookingTime = ISO8601DateFormatter().date(from: bookingTimeString) ?? Date()
                let reason = appointmentData["reason"] as? String ?? ""
                let isDone = appointmentData["isdone"] as? Bool ?? false
                let isPremium = appointmentData["is_premium"] as? Bool
                
                // Get slot times
                let slotStartTimeRaw = appointmentData["slot_start_time"] as? String
                let slotEndTimeRaw = appointmentData["slot_end_time"] as? String
                
                // Format times for display
                var slotStartTime = ""
                var slotEndTime: String? = nil
                
                // Date components for checking if appointment is missed
                var slotEndDateTime: Date? = nil
                
                // Format start time if available
                if let timeString = slotStartTimeRaw {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
                    if let timeDate = timeFormatter.date(from: timeString) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "h:mm a"
                        slotStartTime = displayFormatter.string(from: timeDate)
                    } else {
                        slotStartTime = timeString
                    }
                }
                
                // Format end time if available
                if let timeString = slotEndTimeRaw {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm:ss"
                    if let timeDate = timeFormatter.date(from: timeString) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "h:mm a"
                        slotEndTime = displayFormatter.string(from: timeDate)
                        
                        // Create a date by combining appointment date with slot end time
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: timeDate)
                        let minute = calendar.component(.minute, from: timeDate)
                        let second = calendar.component(.second, from: timeDate)
                        
                        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: appointmentDate)
                        endDateComponents.hour = hour
                        endDateComponents.minute = minute
                        endDateComponents.second = second
                        
                        slotEndDateTime = calendar.date(from: endDateComponents)
                    } else {
                        slotEndTime = timeString
                    }
                }
                
                // Debug slot time information
                print("Slot times - Start: \(slotStartTime), End: \(slotEndTime ?? "nil")")
                
                // Auto-mark as missed if:
                // 1. Status is "upcoming"
                // 2. Appointment end time has passed
                // 3. isDone is false
                if statusString.lowercased() == "upcoming" && !isDone {
                    if let endDateTime = slotEndDateTime, endDateTime < now {
                        print("🔄 Auto-marking appointment \(id) as missed (End time: \(endDateTime) has passed current time: \(now))")
                        statusString = "missed"
                        
                        // Update status in database
                        Task {
                            do {
                                try await supabase.update(
                                    table: "appointments",
                                    id: id,
                                    data: ["status": "missed"]
                                )
                                print("✅ Updated appointment \(id) status to missed in database")
                            } catch {
                                print("❌ Failed to update appointment status: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Parse status after potential auto-update
                guard let status = AppointmentStatusType(rawValue: statusString.lowercased()) else {
                    print("⚠️ Invalid status: \(statusString)")
                    continue
                }
                
                // Fetch patient details
                var patientName = "Unknown Patient"
                if let patientResult = try? await supabase.select(
                    from: "patients",
                    where: "patient_id",
                    equals: patientId
                ).first, let name = patientResult["name"] as? String {
                    patientName = name
                }
                
                // Fetch hospital details
                var hospitalName = "Unknown Hospital"
                if let hospitalResult = try? await supabase.select(
                    from: "hospitals",
                    where: "id",
                    equals: hospitalId
                ).first, let name = hospitalResult["hospital_name"] as? String {
                    hospitalName = name
                }
                
                // Create appointment model
                let appointment = DoctorAppointmentModel(
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
                    slotId: 0, // Not used anymore
                    slotTime: slotStartTime,
                    slotEndTime: slotEndTime
                )
                
                enhancedAppointments.append(appointment)
                print("✅ Successfully processed appointment: \(id)")
            }
            
            // Sort appointments by date and time
            enhancedAppointments.sort { (a1, a2) -> Bool in
                if a1.appointmentDate == a2.appointmentDate {
                    return a1.bookingTime < a2.bookingTime
                }
                return a1.appointmentDate < a2.appointmentDate
            }
            
            // Update UI on main thread
            await MainActor.run {
                self.appointments = enhancedAppointments
                updateCounts(enhancedAppointments)
                isLoadingAppointments = false
            }
            
            print("✅ Updated appointments list with \(enhancedAppointments.count) appointments")
            
        } catch {
            print("❌ Error fetching appointments: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to load appointments: \(error.localizedDescription)"
                isLoadingAppointments = false
            }
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
        missedCount = appointments.filter { $0.status == .missed }.count
        
        print("📊 Appointment counts - Today: \(todayCount), Upcoming: \(upcomingCount), Completed: \(completedCount), Missed: \(missedCount)")
    }
    
    private func fetchDoctorData() {
        Task {
            await fetchDoctorDataAsync()
        }
    }
    
    private func fetchDoctorAppointments() {
        Task {
            await fetchDoctorAppointmentsAsync()
        }
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
