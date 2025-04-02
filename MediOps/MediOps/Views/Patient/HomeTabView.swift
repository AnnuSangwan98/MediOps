//
//  HomeTabView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct HomeTabView: View {
    @ObservedObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @State private var showProfile = false
    @State private var selectedTab = 0
    @AppStorage("current_user_id") private var currentUserId: String?
    @AppStorage("userId") private var userId: String?
    @StateObject private var profileController = PatientProfileController()
    @State private var showBloodDonationRegistration = false
    @State private var isRegisteredDonor = false
    @State private var showBloodRequest = false
    @State private var hasActiveBloodRequest = false
    @State private var showCancelRegistrationAlert = false
    @State private var showCancelRequestAlert = false
    @StateObject private var bloodController = BloodDonationController.shared

    var body: some View {
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
            
            bloodDonateTab
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "drop.fill" : "drop")
                    Text("Blood Donate")
                }
                .tag(2)
                
//            ProfileView()
//                .tabItem {
//                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
//                    Text("Profile")
//                }
//                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
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
    
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .ignoresSafeArea()

                ScrollView {
                    RefreshControl(coordinateSpace: .named("pullToRefresh")) {
                        Task {
                            await refreshHospitals()
                        }
                    }
                    
                    VStack(spacing: 20) {
                        headerSection
                        searchAndFilterSection
                        
                        if !hospitalVM.searchText.isEmpty {
                            searchResultsSection
                        } else {
                            upcomingAppointmentsSection
                            
                            // Show all hospitals when not searching
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("All Hospitals")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        Task {
                                            await refreshHospitals()
                                        }
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.teal)
                                    }
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
                        }
                    }
                }
                .coordinateSpace(name: "pullToRefresh")
            }
            .navigationBarHidden(true)
            .task {
                await refreshHospitals()
                
                if let userId = userId {
                    print("🔍 Home Tab task using user ID: \(userId)")
                    try? await hospitalVM.fetchAppointments(for: userId)
                } else {
                    print("⚠️ No user ID found in HomeTab task")
                }
            }
            .onAppear {
                if let userId = userId {
                    print("🔄 Home Tab appeared with user ID: \(userId)")
                    // Add a direct call to refresh appointments
                    appointmentManager.refreshAppointments()
                } else {
                    print("⚠️ No user ID found in HomeTab onAppear")
                }
            }
        }
    }
    
    // Helper function to refresh hospitals and cities
    private func refreshHospitals() async {
        print("🔄 Refreshing hospitals and cities...")
        
        // Check Supabase connectivity first
        let supabase = SupabaseController.shared
        let isConnected = await supabase.checkConnectivity()
        
        if isConnected {
            print("✅ Supabase connectivity confirmed - proceeding with data fetch")
            
            // Fetch hospitals and cities
            await hospitalVM.fetchHospitals()
            await hospitalVM.fetchAvailableCities()
            
            if hospitalVM.hospitals.isEmpty {
                print("⚠️ No hospitals found after refresh")
            } else {
                print("✅ Successfully loaded \(hospitalVM.hospitals.count) hospitals")
            }
        } else {
            print("❌ Supabase connectivity failed - setting error")
            await MainActor.run {
                hospitalVM.error = NSError(
                    domain: "HospitalViewModel",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check your internet connection and try again."]
                )
            }
        }
        
        print("✅ Refresh complete!")
    }
    
    private var historyTab: some View {
        NavigationStack {
            List {
                if appointmentManager.appointments.filter({ $0.status == .completed || $0.status == .cancelled }).isEmpty {
                    Text("No appointment history")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Section(header: Text("Completed Appointments")) {
                        ForEach(appointmentManager.appointments.filter { $0.status == .completed }, id: \.id) { appointment in
                            NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                AppointmentHistoryCard(appointment: appointment)
                                    .listRowBackground(Color.green.opacity(0.1))
                            }
                        }
                    }
                    
                    Section(header: Text("Cancelled Appointments")) {
                        ForEach(appointmentManager.appointments.filter { $0.status == .cancelled }, id: \.id) { appointment in
                            AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                .listRowBackground(Color.red.opacity(0.1))
                        }
                    }
                }
            }
            .navigationTitle("Appointment History")
            .refreshable {
                print("🔃 Manually refreshing appointment history")
                appointmentManager.refreshAppointments()
            }
        }
    }
    
    private var bloodDonateTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isRegisteredDonor {
                        // Registered Donor Card
                        RegisteredDonorCard(onCancelRegistration: { showCancelRegistrationAlert = true })
                    }
                    
                    // Active Blood Request Card (if exists)
                    if hasActiveBloodRequest {
                        ActiveBloodRequestCard(
                            bloodRequests: bloodController.bloodRequests,
                            onCancelRequest: { showCancelRequestAlert = true }
                        )
                    }
                    
                    // Blood Request History
                    if !bloodController.bloodRequests.isEmpty {
                        BloodRequestHistoryView(bloodRequests: bloodController.bloodRequests)
                    }
                    
                    // Main Actions
                    VStack(spacing: 15) {
                        if !isRegisteredDonor {
                            Text("Blood Donation")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Be a lifesaver by donating blood")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showBloodDonationRegistration = true
                            }) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("Register as Blood Donor")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !hasActiveBloodRequest {
                            Button(action: {
                                showBloodRequest = true
                            }) {
                                HStack {
                                    Image(systemName: "drop.fill")
                                    Text("Request Blood")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Blood Donation")
            .alert("Cancel Blood Donor Registration", isPresented: $showCancelRegistrationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    if let patient = profileController.patient {
                        Task {
                            do {
                                _ = try await PatientController.shared.updateBloodDonorStatus(id: patient.id, isDonor: false)
                                isRegisteredDonor = false
                            } catch {
                                print("Error cancelling registration: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to cancel your blood donor registration? This will remove you from the donor list.")
            }
            .alert("Cancel Blood Request", isPresented: $showCancelRequestAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    if let activeRequest = bloodController.bloodRequests.first(where: { $0.activityStatus }) {
                        Task {
                            if let patientId = UserDefaults.standard.string(forKey: "current_patient_id") {
                                let success = await bloodController.cancelBloodRequest(requestId: activeRequest.id)
                                if success {
                                    hasActiveBloodRequest = false
                                    await bloodController.fetchBloodRequests(patientId: patientId)
                                }
                            }
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to cancel your blood request? This action cannot be undone.")
            }
            .sheet(isPresented: $showBloodDonationRegistration) {
                if let patient = profileController.patient {
                    BloodDonationRegistrationView(isRegistered: $isRegisteredDonor, patientId: patient.id)
                } else {
                    // Show error view if patient data is not available
                    VStack {
                        Text("Error")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("Unable to load patient data. Please try again later.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        Button("Dismiss") {
                            showBloodDonationRegistration = false
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showBloodRequest) {
                BloodRequestView(hasActiveRequest: $hasActiveBloodRequest)
            }
            .onAppear {
                if let patientId = UserDefaults.standard.string(forKey: "current_patient_id") {
                    Task {
                        hasActiveBloodRequest = await bloodController.hasActiveRequest(patientId: patientId)
                        await bloodController.fetchBloodRequests(patientId: patientId)
                    }
                }
            }
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
                Text("Welcome Back!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Your Health Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            Button(action: {
                showProfile.toggle()
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.teal)
            }
            .sheet(isPresented: $showProfile) {
                PatientProfileView(profileController: PatientProfileController())
            }
        }
        .padding()
        .background(Color.white)
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

    // Pull-to-refresh control
    struct RefreshControl: View {
        var coordinateSpace: CoordinateSpace
        var onRefresh: () -> Void
        
        @State private var isRefreshing = false
        
        var body: some View {
            GeometryReader { geometry in
                let offset = geometry.frame(in: coordinateSpace).minY
                VStack {
                    refreshStatusView(offset: offset)
                }
                .onChange(of: offset) { newOffset in
                    checkForRefreshTrigger(offset: newOffset)
                }
            }
            .frame(height: 50)
        }
        
        @ViewBuilder
        private func refreshStatusView(offset: CGFloat) -> some View {
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                } else if offset > 20 {
                    Text("Release to refresh")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if offset > 5 {
                    Text("Pull to refresh")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .frame(height: max(0, offset))
            .offset(y: -10)
        }
        
        private func checkForRefreshTrigger(offset: CGFloat) {
            if offset > 50 && !isRefreshing {
                isRefreshing = true
                onRefresh()
                
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRefreshing = false
                }
            } else if offset < 1 {
                isRefreshing = false
            }
        }
    }
}

struct AppointmentHistoryCard: View {
    let appointment: Appointment
    var isCancelled: Bool = false
    
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
                
                Text(isCancelled ? "Cancelled" : "Completed")
                    .font(.caption)
                    .foregroundColor(isCancelled ? .red : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCancelled ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                    .cornerRadius(8)
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

struct BloodRequestHistoryView: View {
    let bloodRequests: [BloodDonationRequest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Request History")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(bloodRequests.filter { !$0.activityStatus }) { request in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Blood Group: \(request.bloodGroup)")
                            .font(.headline)
                        Spacer()
                        Text(request.createdAt.formatted(date: .long, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Status: Completed")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct ActiveBloodRequestCard: View {
    let bloodRequests: [BloodDonationRequest]
    let onCancelRequest: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("Active Blood Request")
                    .font(.headline)
            }
            
            if let activeRequest = bloodRequests.first(where: { $0.activityStatus }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blood Group: \(activeRequest.bloodGroup)")
                    Text("Requested on: \(activeRequest.createdAt.formatted(date: .long, time: .shortened))")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            
            Button(action: onCancelRequest) {
                Text("Cancel Request")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct RegisteredDonorCard: View {
    let onCancelRegistration: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Registered Blood Donor")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Thank you for your commitment to saving lives!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: onCancelRegistration) {
                Text("Cancel Registration")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding()
    }
}
