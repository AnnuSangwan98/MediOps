//
//  HomeTabView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

// Define the missing ActiveSheet enum
enum ActiveSheet: Identifiable {
    case doctorList(hospital: HospitalModel)
    case patientProfile
    case addVitals
    
    var id: Int {
        switch self {
        case .doctorList: return 0
        case .patientProfile: return 1
        case .addVitals: return 2
        }
    }
}

struct HomeTabView: View {
    @ObservedObject var hospitalVM = HospitalViewModel.shared
    @StateObject var appointmentManager = AppointmentManager.shared
    @StateObject private var labReportManager = LabReportManager.shared
    @State private var showProfile = false
    @State private var showAddVitals = false
    @State private var selectedHospital: HospitalModel?
    @State private var activeSheet: ActiveSheet?
    @State private var coordinateSpace = UUID()
    @State private var profileController = PatientProfileController()
    @State private var selectedTab = 0
    @AppStorage("current_user_id") private var currentUserId: String?
    @AppStorage("userId") private var userId: String?
    @State private var selectedHistoryType = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                homeTab
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                    .onAppear {
                        // Refresh appointments each time home tab appears
                        if selectedTab == 0 {
                            print("📱 Home tab appeared - refreshing appointments")
                            appointmentManager.refreshAppointments()
                        }
                    }
                
                historyTab
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                        Text("History")
                    }
                    .tag(1)
                
                labReportsTab
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "doc.text.fill" : "doc.text")
                        Text("Lab Reports")
                    }
                    .tag(2)
                
                bloodDonateTab
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "drop.fill" : "drop")
                        Text("Blood Donate")
                    }
                    .tag(3)
            }
            .accentColor(.blue)
            .onAppear {
                // Customize the TabView appearance
                UITabBar.appearance().backgroundColor = UIColor.systemBackground
                UITabBar.appearance().backgroundImage = UIImage()
                
                print("📱 HomeTabView appeared with currentUserId: \(currentUserId ?? "nil") and userId: \(userId ?? "nil")")
                
                // Ensure user IDs are synchronized
                if let currentId = currentUserId, userId == nil {
                    print("📱 Synchronizing userId with currentUserId: \(currentId)")
                    userId = currentId
                } else if let id = userId, currentUserId == nil {
                    print("📱 Synchronizing currentUserId with userId: \(id)")
                    currentUserId = id
                }
                
                // If no userId is available, use a test ID
                if userId == nil && currentUserId == nil {
                    let testUserId = "USER_\(Int(Date().timeIntervalSince1970))"
                    print("⚠️ No user ID found. Setting test ID: \(testUserId)")
                    userId = testUserId
                    currentUserId = testUserId
                    UserDefaults.standard.synchronize()
                }
                
                // Load profile data for debugging
                Task {
                    if let id = userId ?? currentUserId {
                        print("📱 HomeTabView: Loading profile with user ID: \(id)")
                        await profileController.loadProfile(userId: id)
                        if let patient = profileController.patient {
                            print("📱 Successfully loaded profile for: \(patient.name)")
                            
                            // Fix appointment times when profile is loaded
                            print("🔧 Running appointment time fix")
                            try? await fixAppointmentTimes(for: patient.id)
                        } else if let error = profileController.error {
                            print("📱 Error loading profile: \(error.localizedDescription)")
                            
                            // Try creating a test patient if loading failed
                            print("📱 Attempting to create test patient...")
                            let success = await profileController.createAndInsertTestPatientInSupabase()
                            if success {
                                print("✅ Test patient created and loaded successfully")
                            } else {
                                print("❌ Failed to create test patient")
                            }
                        } else {
                            print("📱 No profile data loaded")
                        }
                    } else {
                        print("❌ HomeTabView: No user ID available for profile loading")
                    }
                }
                
                // Initial refresh of appointments
                appointmentManager.refreshAppointments()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom) // Only ignore bottom safe area, respect top
    }
    
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background color
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header - This will stay in place while scrolling
                    VStack(spacing: 15) {
                        headerSection
                            .padding(.top, 8)
                        
                        searchAndFilterSection
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 5)
                    .background(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
                    .zIndex(1) // Keep header on top
                    
                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 20) {
                            if !hospitalVM.searchText.isEmpty {
                                searchResultsSection
                                    .padding(.top, 5)
                            } else {
                                upcomingAppointmentsSection
                                    .padding(.top, 5)
                                
                                // Show all hospitals when not searching
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text("All Hospitals")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    if hospitalVM.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.5)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else if let error = hospitalVM.error {
                                        VStack {
                                            Text("Error loading hospitals")
                                                .foregroundColor(.red)
                                                .padding(.bottom, 4)
                                            
                                            Text(error.localizedDescription)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                            
                                            Button("Try Again") {
                                                Task {
                                                    await refreshHospitals()
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color.teal)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .padding(.top, 8)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                    } else if !hospitalVM.hospitals.isEmpty {
                                        ForEach(hospitalVM.hospitals) { hospital in
                                            NavigationLink {
                                                DoctorListView(hospital: hospital)
                                            } label: {
                                                HospitalCard(hospital: hospital)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal)
                                        }
                                    } else {
                                        VStack(spacing: 12) {
                                            Text("No hospitals found")
                                                .foregroundColor(.gray)
                                            
                                            Button("Refresh") {
                                                Task {
                                                    await refreshHospitals()
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(Color.teal)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                    }
                                }
                                .padding(.bottom, 30) // Extra padding at bottom for tab bar
                            }
                        }
                        .padding(.top, 10) // Add padding to separate from fixed header
                        .padding(.bottom, 80) // Extra padding at bottom for tab bar
                    }
                    .refreshable {
                        await refreshHospitals()
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .bottom) // Only ignore bottom safe area
            .task {
                print("🔄 Home tab task started - refreshing hospitals")
                await refreshHospitals()
                
                if let userId = userId {
                    print("🔄 Fetching appointments for user ID: \(userId)")
                    try? await hospitalVM.fetchAppointments(for: userId)
                    
                    // Load patient profile data
                    if profileController.patient == nil {
                        print("🔄 Loading patient profile data")
                        await profileController.loadProfile(userId: userId)
                    }
                }
            }
            .onAppear {
                if let userId = userId {
                    print("📱 Home tab appeared with user ID: \(userId)")
                    appointmentManager.refreshAppointments()
                    
                    // Ensure profile data is loaded when tab appears
                    if profileController.patient == nil {
                        Task {
                            await profileController.loadProfile(userId: userId)
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to refresh hospitals and cities
    private func refreshHospitals() async {
        // Check Supabase connectivity first
        let supabase = SupabaseController.shared
        let isConnected = await supabase.checkConnectivity()
        
        if isConnected {
            // Fetch hospitals and cities
            await hospitalVM.fetchHospitals()
            await hospitalVM.fetchAvailableCities()
            
            if !hospitalVM.hospitals.isEmpty {
                // Add test doctors to hospitals if needed
                await hospitalVM.addTestDoctorsToHospitals()
                
                // Update doctor counts for all hospitals
                await hospitalVM.updateDoctorCounts()
                
                // Ensure doctor counts are reflected immediately
                await MainActor.run {
                    // Force UI refresh for hospital cards
                    let updatedHospitals = hospitalVM.hospitals
                    hospitalVM.hospitals = []
                    
                    // Reapply the updated hospitals after a tiny delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.hospitalVM.hospitals = updatedHospitals
                    }
                }
            }
        } else {
            await MainActor.run {
                hospitalVM.error = NSError(
                    domain: "HospitalViewModel",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check your internet connection and try again."]
                )
            }
        }
    }
    
    private var historyTab: some View {
        NavigationStack {
            VStack {
                List {
                    // Explicitly filter for completed appointments
                    let completedAppointments = appointmentManager.appointments.filter { 
                        print("Appointment status: \($0.status.rawValue)") // Debug print
                        return $0.status == .completed 
                    }
                    let cancelledAppointments = appointmentManager.appointments.filter { $0.status == .cancelled }
                    
                    if completedAppointments.isEmpty && cancelledAppointments.isEmpty {
                        Text("No appointment history")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        if !completedAppointments.isEmpty {
                            Section(header: Text("Completed Appointments")) {
                                ForEach(completedAppointments) { appointment in
                                    NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                        AppointmentHistoryCard(appointment: appointment)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
                                    .listRowBackground(Color.green.opacity(0.1))
                                }
                            }
                        }
                        
                        if !cancelledAppointments.isEmpty {
                            Section(header: Text("Cancelled Appointments")) {
                                ForEach(cancelledAppointments) { appointment in
                                    AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.red.opacity(0.1))
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    print("🔄 Manually refreshing appointments history")
                    appointmentManager.refreshAppointments()
                }
            }
            .navigationTitle("Appointments History")
            .onAppear {
                print("📱 History tab appeared - refreshing appointments")
                appointmentManager.refreshAppointments()
            }
        }
    }
    
    private var labReportsTab: some View {
        NavigationStack {
            labReportsSection
                .navigationTitle("Lab Reports")
        }
    }
    
    private var bloodDonateTab: some View {
        NavigationStack {
            Color(.systemGray6)
                .ignoresSafeArea()
                .navigationTitle("Blood Donation")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Search Results")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(hospitalVM.filteredHospitals) { hospital in
                NavigationLink {
                    DoctorListView(hospital: hospital)
                } label: {
                    HospitalCard(hospital: hospital)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                if let patientName = profileController.patient?.name {
                    Text("Welcome Back, \(patientName)!")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Text("Welcome Back!")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            Spacer()

            Button(action: {
                // Create and initialize the profile controller before showing the sheet
                let controller = PatientProfileController()
                
                // Preload the patient data
                if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                       UserDefaults.standard.string(forKey: "current_user_id") {
                    Task {
                        await controller.loadProfile(userId: userId)
                        
                        // Show the profile after we've attempted to load data
                        DispatchQueue.main.async {
                            self.profileController = controller
                            self.showProfile = true
                        }
                    }
                } else {
                    // If no user ID, still show the profile with the empty controller
                    self.profileController = controller
                    self.showProfile = true
                }
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.teal)
            }
            .sheet(isPresented: $showProfile) {
                PatientProfileView(profileController: profileController)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchAndFilterSection: some View {
        HStack {
            HospitalSearchBar(searchText: $hospitalVM.searchText)
            cityFilterMenu
        }
        .padding(.horizontal)
    }

    private var cityFilterMenu: some View {
        Menu {
            ForEach(hospitalVM.availableCities, id: \.self) { city in
                Button(action: {
                    hospitalVM.selectedCity = hospitalVM.selectedCity == city ? nil : city
                }) {
                    HStack {
                        Text(city)
                        if hospitalVM.selectedCity == city {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Button("Clear Filter", action: { hospitalVM.selectedCity = nil })
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.teal)
                .font(.title2)
        }
    }

    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Upcoming Appointments")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if appointmentManager.appointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.1), radius: 5)
                    .padding(.horizontal)
            } else {
                ForEach(appointmentManager.appointments.filter { $0.status == .upcoming }) { appointment in
                    AppointmentCard(appointment: appointment)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }

    private var labReportsSection: some View {
        List {
            if labReportManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let error = labReportManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if labReportManager.labReports.isEmpty {
                Text("No lab reports available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(labReportManager.labReports) { report in
                    PatientLabReportCard(report: report)
                        .padding(.vertical, 4)
                }
            }
        }
        .refreshable {
            if let userId = userId {
                // First get the patient's PAT ID from patients table
                Task {
                    do {
//                        let patientData = try await SupabaseController.shared.select(
//                            from: "patients",
//                            columns: "patient_id",
//                            where: "id",
//                            equals: userId
//                        )
                        
                        struct PatientIds: Codable {
                            var patient_id: String
                        }

                        let patient: [PatientIds] = try await SupabaseController.shared.client
                            .from("patients")
                            .select("patient_id")
                            .eq("user_id", value: userId)
                            .execute()
                            .value
//
                        labReportManager.fetchLabReports(for: patient[0].patient_id)
//                        if let patientRecord = patientData.first,
//                           let patId = patientRecord["patient_id"] as? String {
//                            print("📍 Found patient_id: \(patId)")
//                            labReportManager.fetchLabReports(for: patId)
//                        }
                    } catch {
                        print("❌ Error getting patient ID: \(error)")
                    }
                }
            }
        }
        .onAppear {
            if let userId = userId {
                // First get the patient's PAT ID from patients table
                Task {
                    do {
                        let patientData = try await SupabaseController.shared.select(
                            from: "patients",
                            columns: "patient_id",
                            where: "id",
                            equals: userId
                        )
                        
                        if let patientRecord = patientData.first,
                           let patId = patientRecord["patient_id"] as? String {
                            print("📍 Found patient_id: \(patId)")
                            labReportManager.fetchLabReports(for: patId)
                        }
                    } catch {
                        print("❌ Error getting patient ID: \(error)")
                    }
                }
            }
        }
    }
    
    // Pull-to-refresh control
    struct RefreshControl: View {
        var coordinateSpace: CoordinateSpace
        var onRefresh: () -> Void
        
        @State private var isRefreshing = false
        
        var body: some View {
            GeometryReader { geometry in
                if geometry.frame(in: coordinateSpace).minY > 50 {
                    Spacer()
                        .onAppear {
                            if !isRefreshing {
                                isRefreshing = true
                                onRefresh()
                                
                                // Reset after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isRefreshing = false
                                }
                            }
                        }
                } else if geometry.frame(in: coordinateSpace).minY < 1 {
                    Spacer()
                        .onAppear {
                            isRefreshing = false
                        }
                }
                
                HStack {
                    Spacer()
                    if isRefreshing {
                        ProgressView()
                    } else if geometry.frame(in: coordinateSpace).minY > 20 {
                        Text("Release to refresh")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if geometry.frame(in: coordinateSpace).minY > 5 {
                        Text("Pull to refresh")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .frame(height: geometry.frame(in: coordinateSpace).minY > 0 ? geometry.frame(in: coordinateSpace).minY : 0)
                .offset(y: -10)
            }
            .frame(height: 50)
        }
    }

    // Helper function to fix appointment times
    private func fixAppointmentTimes(for patientId: String) async throws {
        print("🔧 TIMEFIXER: Starting fix for patient ID: \(patientId)")
        let supabase = SupabaseController.shared
        
        // Get all appointments for this patient
        let appointments = try await supabase.select(
            from: "appointments",
            where: "patient_id",
            equals: patientId
        )
        
        print("🔍 TIMEFIXER: Found \(appointments.count) appointments to check")
        
        var fixedCount = 0
        for data in appointments {
            guard let id = data["id"] as? String,
                  let slotId = data["availability_slot_id"] as? Int else {
                print("⚠️ TIMEFIXER: Skipping appointment without ID or slot ID")
                continue
            }
            
            let hasValidStartTime = data["slot_time"] as? String != nil && !(data["slot_time"] as? String)!.isEmpty
            let hasValidEndTime = data["slot_end_time"] as? String != nil && !(data["slot_end_time"] as? String)!.isEmpty
            
            // Only fix appointments with missing or empty time slots
            if !hasValidStartTime || !hasValidEndTime {
                print("🔧 TIMEFIXER: Fixing time slots for appointment \(id)")
                do {
                    // Generate time slots based on slot ID
                    let baseHour = 9 + (slotId % 8) // This gives hours between 9 and 16 (9 AM to 4 PM)
                    let startTime = String(format: "%02d:00", baseHour)
                    let endTime = String(format: "%02d:00", baseHour + 1)
                    
                    // Update the appointment with generated times
                    let updateResult = try await supabase.update(
                        table: "appointments",
                        id: id,
                        data: [
                            "slot_time": startTime,
                            "slot_end_time": endTime
                        ]
                    )
                    
                    print("✅ TIMEFIXER: Updated appointment \(id) with times \(startTime)-\(endTime)")
                    fixedCount += 1
                } catch {
                    print("❌ TIMEFIXER: Error fixing time slots: \(error.localizedDescription)")
                }
            }
        }
        
        print("🎉 TIMEFIXER: Fixed time slots for \(fixedCount) appointments")
        
        // Refresh the appointments list if we fixed any
        if fixedCount > 0 {
            try await hospitalVM.fetchAppointments(for: patientId)
        }
    }

    // Helper debugging function to check doctor counts
    private func debugHospitalDoctorCounts() async {
        print("🔍 DEBUG: Checking hospital doctor counts directly...")
        
        let supabase = SupabaseController.shared
        
        // Check each hospital in the view model
        for hospital in hospitalVM.hospitals {
            do {
                let sqlQuery = """
                SELECT COUNT(*) as doctor_count 
                FROM doctors 
                WHERE hospital_id = '\(hospital.id)'
                """
                
                let results = try await supabase.executeSQL(sql: sqlQuery)
                
                if let firstResult = results.first, let count = firstResult["doctor_count"] as? Int {
                    print("🏥 Hospital: \(hospital.hospitalName) - SQL count: \(count), Model count: \(hospital.numberOfDoctors)")
                    
                    // If counts don't match, print a warning
                    if count != hospital.numberOfDoctors {
                        print("⚠️ Mismatch in doctor counts for \(hospital.hospitalName)!")
                    }
                } else {
                    print("❌ Could not get doctor count from SQL for \(hospital.hospitalName)")
                }
            } catch {
                print("❌ Error checking doctor count for \(hospital.hospitalName): \(error.localizedDescription)")
            }
        }
    }
}

struct AppointmentHistoryCard: View {
    let appointment: Appointment
    var isCancelled: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                    Text(appointment.doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(isCancelled ? "Cancelled" : "Completed")
                        .font(.caption)
                        .foregroundColor(isCancelled ? .red : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isCancelled ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                Text(appointment.date.formatted(date: .long, time: .omitted))
                Spacer()
                Image(systemName: "clock")
                let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.time)!
                Text("\(appointment.time.formatted(date: .omitted, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}

// MARK: - HospitalSearchBar Component
struct HospitalSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search hospitals...", text: $searchText)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 3)
    }
}
