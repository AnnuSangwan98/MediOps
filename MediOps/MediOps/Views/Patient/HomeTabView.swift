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
    @ObservedObject private var themeManager = ThemeManager.shared
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
    @State private var tabViewRefreshID = UUID() // For forcing UI refresh

    var body: some View {
        ZStack(alignment: .bottom) {
            // Apply background gradient to the main container
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
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
            .accentColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            .onAppear {
                // Configure navigation bar appearance
                configureNavigationBar()
                
                // Apply tab bar theme
                updateTabBarAppearance()
                
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
                
                // Set up theme change observer
                setupThemeChangeListener()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .id(tabViewRefreshID) // Force refresh when ID changes
    }
    
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Use the themed background instead of fixed gradient
                if ThemeManager.shared.isPatient {
                    ThemeManager.shared.currentTheme.background
                        .ignoresSafeArea()
                } else {
                    // Fallback to original gradient for non-patients
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Fixed Header section
                    headerSection
                        .padding(.top, 8)
                    
                    // Divider
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    // Main content with simplified layout
                    ScrollView {
                        VStack(spacing: 20) {
                            if !hospitalVM.searchText.isEmpty {
                                // Simple search bar
                                searchAndFilterSection
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                searchResultsSection
                                    .padding(.top, 5)
                            } else {
                                searchAndFilterSection
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                upcomingAppointmentsSection
                                    .padding(.top, 5)
                                
                                // Show all hospitals with simplified styling
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Hospitals")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                    
                                    if hospitalVM.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.2)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else if let error = hospitalVM.error {
                                        Text("Error loading hospitals: \(error.localizedDescription)")
                                            .foregroundColor(.red)
                                            .font(.callout)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                            .padding(.horizontal)
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
                                        Text("No hospitals found")
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 30)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        await refreshHospitals()
                    }
                }
            }
            .foregroundColor(ThemeManager.shared.isPatient ? ThemeManager.shared.currentTheme.primaryText : Color.primary)
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .bottom)
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
            ZStack {
                // Consistent background gradient
                if themeManager.isPatient {
                    themeManager.currentTheme.background
                        .ignoresSafeArea()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                }
                
                List {
                    // Filter appointments by status
                    let completedAppointments = appointmentManager.appointments.filter { $0.status == .completed }
                    let cancelledAppointments = appointmentManager.appointments.filter { $0.status == .cancelled }
                    let missedAppointments = appointmentManager.appointments.filter { $0.status == .missed }
                    
                    if completedAppointments.isEmpty && cancelledAppointments.isEmpty && missedAppointments.isEmpty {
                        Text("No appointment history")
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        if !completedAppointments.isEmpty {
                            Section(header: Text("Completed Appointments")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                                ForEach(completedAppointments) { appointment in
                                    NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                        AppointmentHistoryCard(appointment: appointment)
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(themeManager.isPatient ? 
                                                      themeManager.currentTheme.background : 
                                                      Color.green.opacity(0.1))
                                }
                            }
                        }
                        
                        if !missedAppointments.isEmpty {
                            Section(header: Text("Missed Appointments")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                                ForEach(missedAppointments) { appointment in
                                    AppointmentHistoryCard(appointment: appointment, isMissed: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(themeManager.isPatient ? 
                                                         themeManager.currentTheme.background : 
                                                         Color.orange.opacity(0.1))
                                }
                            }
                        }
                        
                        if !cancelledAppointments.isEmpty {
                            Section(header: Text("Cancelled Appointments")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                                ForEach(cancelledAppointments) { appointment in
                                    AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(themeManager.isPatient ? 
                                                         themeManager.currentTheme.background : 
                                                         Color.red.opacity(0.1))
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden) // Hide default list background
                .refreshable {
                    print("🔄 Manually refreshing appointments history")
                    appointmentManager.refreshAppointments()
                }
            }
            .navigationTitle("Appointments History")
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                print("📱 History tab appeared - refreshing appointments")
                appointmentManager.refreshAppointments()
            }
        }
    }
    
    private var labReportsTab: some View {
        NavigationStack {
            ZStack {
                // Apply themed background
                if themeManager.isPatient {
                    themeManager.currentTheme.background
                        .ignoresSafeArea()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                }
                
                labReportsSection
                    .scrollContentBackground(.hidden) // Hide default list background if this contains a List
            }
            .navigationTitle("Lab Reports")
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var bloodDonateTab: some View {
        NavigationStack {
            ZStack {
                // Apply themed background
                if themeManager.isPatient {
                    themeManager.currentTheme.background
                        .ignoresSafeArea()
                } else {
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                }
                
                // Content will go here when implemented
                VStack {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        .padding()
                    
                    Text("Blood Donation Feature")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                    
                    Text("Coming Soon")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Blood Donation")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // Simplified header section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome")
                    .font(.headline)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                
                if let patientName = profileController.patient?.name {
                    Text(patientName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                } else {
                    Text("Patient")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                }
            }
            Spacer()
            
            // Add Accessibility Settings Button
            Button(action: {
                // Show accessibility settings
                let viewToPresent = AccessibilitySettingsView()
                    .environmentObject(AppNavigationState())
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    let hostingController = UIHostingController(rootView: viewToPresent)
                    rootVC.present(hostingController, animated: true)
                }
            }) {
                Image(systemName: "eye")
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                    .padding(8)
                    .background(Circle().fill(themeManager.isPatient ? themeManager.currentTheme.background : Color.white))
                    .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.3) : .gray.opacity(0.3), radius: 2)
            }
            .padding(.horizontal, 5)
            
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
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                    .background(Circle().fill(themeManager.isPatient ? themeManager.currentTheme.background : Color.white).frame(width: 48, height: 48))
                    .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.3) : .gray.opacity(0.3), radius: 3)
            }
            .sheet(isPresented: $showProfile) {
                PatientProfileView(profileController: profileController)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // Simplified search and filter section
    private var searchAndFilterSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.teal)
                TextField("Search hospitals...", text: $hospitalVM.searchText)
                    .foregroundColor(.primary)
                
                if !hospitalVM.searchText.isEmpty {
                    Button(action: {
                        hospitalVM.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.teal)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            
            // Simple city filter button
            Menu {
                ForEach(hospitalVM.availableCities, id: \.self) { city in
                    Button(action: {
                        hospitalVM.selectedCity = hospitalVM.selectedCity == city ? nil : city
                    }) {
                        HStack {
                            Text(city)
                            if hospitalVM.selectedCity == city {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                }
                Button("Clear Filter", action: { hospitalVM.selectedCity = nil })
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.teal)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }

    // Simplified upcoming appointments section
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Upcoming Appointments")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                
            }
            .padding(.horizontal)

            if appointmentManager.appointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                let upcomingAppointments = appointmentManager.appointments.filter { $0.status == .upcoming }
                
                if upcomingAppointments.isEmpty {
                    Text("No upcoming appointments")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(upcomingAppointments) { appointment in
                                AppointmentCard(appointment: appointment)
                                    .frame(width: 380)
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    // Simplified search results section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Search Results")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                .padding(.horizontal)

            if hospitalVM.filteredHospitals.isEmpty {
                Text("No hospitals found")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
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
    }

    private var labReportsSection: some View {
        List {
            if labReportManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.clear)
            } else if let error = labReportManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.clear)
            } else if labReportManager.labReports.isEmpty {
                Text("No lab reports available")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.clear)
            } else {
                ForEach(labReportManager.labReports) { report in
                    PatientLabReportCard(report: report)
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.clear)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden) // Hide default list background
        .refreshable {
            if let userId = userId {
                // First get the patient's PAT ID from patients table
                Task {
                    do {
                        // Use either method to fetch patient ID
                        struct PatientIds: Codable {
                            var patient_id: String
                        }

                        let patient: [PatientIds] = try await SupabaseController.shared.client
                            .from("patients")
                            .select("patient_id")
                            .eq("user_id", value: userId)
                            .execute()
                            .value

                        if !patient.isEmpty {
                            labReportManager.fetchLabReports(for: patient[0].patient_id)
                        } else {
                            print("❌ No patient found with user ID: \(userId)")
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

    // Add this method to handle navigation Bar appearance consistently
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.teal.opacity(0.1))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.teal)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Update tab bar appearance
            self.updateTabBarAppearance()
            
            // Generate new ID to force view refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.tabViewRefreshID = UUID()
            }
        }
    }
    
    // Update tab bar appearance based on current theme
    private func updateTabBarAppearance() {
        if themeManager.isPatient {
            // Use themed colors for tab bar
            UITabBar.appearance().backgroundColor = UIColor(themeManager.currentTheme.background)
            UITabBar.appearance().unselectedItemTintColor = UIColor(themeManager.currentTheme.tertiaryAccent)
            
            // Use a custom tint color that works well with all themes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                tabBarController.tabBar.tintColor = UIColor(themeManager.currentTheme.accentColor)
            }
        } else {
            // Default colors for non-patients
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
            UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        }
        
        // Set these properties for both cases
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage() // Remove shadow line for cleaner look
    }
}

struct AppointmentHistoryCard: View {
    let appointment: Appointment
    var isCancelled: Bool = false
    var isMissed: Bool = false
    @State private var isLoading = false
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var refreshID = UUID() // Force view refresh when theme changes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    Text(appointment.doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                }
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(isCancelled ? "Cancelled" : isMissed ? "Missed" : "Completed")
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                Text(appointment.date.formatted(date: .long, time: .omitted))
                Spacer()
                Image(systemName: "clock")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.time)!
                Text("\(appointment.time.formatted(date: .omitted, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.subheadline)
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
        }
        .padding()
        .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
        .cornerRadius(12)
        .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .teal.opacity(0.1), radius: 5)
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
            
            // Listen for theme changes
            setupThemeChangeListener()
        }
        .id(refreshID) // Force view refresh when refreshID changes
    }
    
    private var statusColor: Color {
        if themeManager.isPatient {
            if isCancelled {
                return .red
            } else if isMissed {
                return themeManager.currentTheme.secondaryAccent
            } else {
                return .green
            }
        } else {
            return isCancelled ? .red : isMissed ? .orange : .green
        }
    }
    
    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Generate new ID to force view refresh
            refreshID = UUID()
        }
    }
}

// MARK: - HospitalSearchBar Component
struct HospitalSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.teal)
            TextField("Search hospitals...", text: $searchText)
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.teal)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .teal.opacity(0.2), radius: 3)
        )
    }
}

// The DashboardCard struct has been moved to a shared file
// at MediOps/MediOps/CustomOptions/DashboardCard.swift
