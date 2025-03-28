import SwiftUI

struct HomeView: View {
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @State private var showProfile = false
    @AppStorage("current_user_id") private var userId: String?
    @State private var showDiagnosticResult = false
    @State private var diagnosticMessage = ""
    @State private var isCreatingTestAppointment = false
    @State private var testAppointmentResult = ""
    @State private var showTestAppointmentResult = false
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date? = nil
    
    // Minimum time between refreshes (3 seconds)
    private let refreshCooldown: TimeInterval = 3.0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
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
                        }
                        .padding()
                        .background(Color.white)
                        
                        // Diagnostic button
                        HStack {
                            Button(action: {
                                Task {
                                    await runDiagnostic()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "stethoscope")
                                    Text("Run Diagnostic")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.teal)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                Task {
                                    await createTestAppointment()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Create Test Appointment")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .disabled(isCreatingTestAppointment)
                        }
                        
                        // Search Section
                        VStack(spacing: 10) {
                            TextField("Search hospitals...", text: $hospitalVM.searchText)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 5)
                            
                            if !hospitalVM.availableCities.isEmpty {
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
                                    HStack {
                                        Image(systemName: "location.circle.fill")
                                        Text(hospitalVM.selectedCity ?? "Select City")
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Upcoming Appointments Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Upcoming Appointments")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            if isRefreshing && appointmentManager.appointments.isEmpty {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .padding()
                                    Text("Loading appointments...")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                                .padding(.horizontal)
                            } else if appointmentManager.appointments.isEmpty {
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
                                    NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                                        AppointmentCard(appointment: appointment)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                                
                                // View All Appointments Button
                                if appointmentManager.appointments.count > 0 {
                                    NavigationLink(destination: AllAppointmentsView(appointments: appointmentManager.appointments)) {
                                        Text("View All Appointments")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.teal)
                                            .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Hospitals List
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Hospitals")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if hospitalVM.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if let error = hospitalVM.error {
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                ForEach(hospitalVM.filteredHospitals) { hospital in
                                    NavigationLink(destination: DoctorListView(hospital: hospital)) {
                                        HospitalCard(hospital: hospital)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await hospitalVM.fetchHospitals()
                await hospitalVM.fetchAvailableCities()
                
                if let userId = userId {
                    print("🔍 HomeView task with user ID: \(userId)")
                    isRefreshing = true
                    await refreshWithThrottle(userId: userId)
                } else {
                    print("⚠️ No user ID found in HomeView task")
                }
                
                // Run a diagnostic on startup
                await runDiagnostic()
            }
            .onAppear {
                // Refresh appointments on each appearance
                if let userId = userId {
                    print("🔄 HomeView appeared with user ID: \(userId)")
                    Task {
                        await refreshWithThrottle(userId: userId)
                    }
                } else {
                    print("⚠️ No user ID found in HomeView onAppear")
                }
            }
            .alert("Appointment System Diagnostic", isPresented: $showDiagnosticResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(diagnosticMessage)
            }
            .alert("Test Appointment", isPresented: $showTestAppointmentResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testAppointmentResult)
            }
            .overlay {
                if isCreatingTestAppointment {
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Creating test appointment...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
        }
        .pullToRefresh(isRefreshing: $isRefreshing) {
            if let userId = userId {
                print("🔄 Pull-to-refresh triggered with user ID: \(userId)")
                await refreshWithThrottle(userId: userId)
            } else {
                print("⚠️ Cannot refresh - no user ID found")
            }
        }
    }
    
    private func refreshWithThrottle(userId: String) async {
        // Don't refresh if we're already refreshing
        guard !isRefreshing else {
            print("⚠️ Already refreshing, skipping this request")
            return
        }
        
        // Check if we need to wait for the cooldown period
        if let lastRefresh = lastRefreshTime, 
           Date().timeIntervalSince(lastRefresh) < refreshCooldown {
            print("⏱️ Refresh cooldown in effect. Please wait.")
            return
        }
        
        // Set the refreshing state and update the timestamp
        await MainActor.run {
            isRefreshing = true
            lastRefreshTime = Date()
        }
        
        print("🔄 Refreshing appointments in HomeView for user: \(userId) (with throttle)")
        
        // Call the refresh and add a minimum delay to help with stability
        appointmentManager.refreshAppointments()
        
        // Add a minimum delay of 1 second to keep loading indicator visible
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Set refreshing to false when done
        await MainActor.run {
            isRefreshing = false
        }
    }
    
    private func runDiagnostic() async {
        print("🩺 Running appointment system diagnostic...")
        
        // Check current user ID
        if let userId = userId {
            print("👤 Current user ID: \(userId)")
        } else {
            print("⚠️ No user ID found")
        }
        
        // Check appointments directly
        do {
            // Access the SupabaseController directly
            let supabase = SupabaseController.shared
            
            // Check if appointments table has any data
            let allAppointments = try await supabase.select(from: "appointments")
            print("📊 DIAGNOSTIC: Total appointments in database: \(allAppointments.count)")
            
            // If there are appointments in the database but none for this user
            if !allAppointments.isEmpty {
                let patientIds = allAppointments.compactMap { $0["patient_id"] as? String }
                print("👤 DIAGNOSTIC: Patient IDs in database: \(patientIds)")
                
                if let userId = userId {
                    // Check if any patient ID contains the current user ID as a substring
                    let similarIds = patientIds.filter { $0.contains(userId) || userId.contains($0) }
                    if !similarIds.isEmpty {
                        print("⚠️ DIAGNOSTIC: Found similar patient IDs: \(similarIds)")
                    }
                }
                
                var message = "✅ Appointment system is working properly. "
                message += "Found \(allAppointments.count) total appointments in database. "
                
                if appointmentManager.appointments.isEmpty {
                    if let userId = userId {
                        message += "No appointments found for your user ID: \(userId). "
                        message += "Try creating a test appointment."
                    } else {
                        message += "No user ID found - please log in again."
                    }
                } else {
                    message += "\(appointmentManager.appointments.count) appointment(s) found for your user."
                }
                
                diagnosticMessage = message
            } else {
                diagnosticMessage = "No appointments found in the database. Try creating a test appointment."
            }
        } catch {
            print("❌ DIAGNOSTIC: Error accessing appointments: \(error)")
            diagnosticMessage = "⚠️ Error checking appointment system: \(error.localizedDescription)"
        }
        
        showDiagnosticResult = true
    }
    
    private func createTestAppointment() async {
        guard let userId = userId else {
            testAppointmentResult = "No user ID found"
            showTestAppointmentResult = true
            return
        }
        
        isCreatingTestAppointment = true
        
        do {
            // First get the patient ID associated with this user ID
            print("🔍 Getting patient ID for user: \(userId)")
            let supabase = SupabaseController.shared
            
            // Query patients table to get patient ID for current user
            let patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            guard let patientData = patientResults.first, let patientId = patientData["id"] as? String else {
                print("⚠️ No patient record found for user ID: \(userId)")
                isCreatingTestAppointment = false
                testAppointmentResult = "No patient record found for your user ID. Please complete your patient profile first."
                showTestAppointmentResult = true
                return
            }
            
            print("✅ Found patient ID: \(patientId) for user ID: \(userId)")
            
            // Get first available hospital
            if hospitalVM.hospitals.isEmpty {
                await hospitalVM.fetchHospitals()
            }
            
            guard let hospital = hospitalVM.hospitals.first else {
                isCreatingTestAppointment = false
                testAppointmentResult = "No hospitals available"
                showTestAppointmentResult = true
                return
            }
            
            print("📋 Using hospital: \(hospital.hospitalName) (ID: \(hospital.id))")
            
            // Get first available doctor for the hospital
            hospitalVM.selectedHospital = hospital
            await hospitalVM.fetchDoctors()
            
            guard let doctor = hospitalVM.doctors.first else {
                isCreatingTestAppointment = false
                testAppointmentResult = "No doctors available for \(hospital.hospitalName)"
                showTestAppointmentResult = true
                return
            }
            
            print("👨‍⚕️ Using doctor: \(doctor.name) (ID: \(doctor.id))")
            
            // Create test appointment manually
            let appointmentId = "TEST\(Int.random(in: 100...999))"
            let appointmentDate = Date().addingTimeInterval(86400) // Tomorrow
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Directly create appointment in database using the PATIENT ID (not user ID)
            let appointmentData = AppointmentData(
                id: appointmentId,
                patient_id: patientId, // Use patient ID here instead of user ID
                doctor_id: doctor.id,
                hospital_id: hospital.id,
                availability_slot_id: 1, // Default slot
                appointment_date: dateFormatter.string(from: appointmentDate),
                booking_time: nil,
                status: "upcoming",
                created_at: nil,
                updated_at: nil,
                reason: "Test appointment"
            )
            
            print("🔄 Creating test appointment with ID: \(appointmentId) for patient ID: \(patientId)")
            try await supabase.insert(into: "appointments", data: appointmentData)
            
            // Create local appointment object
            let appointment = Appointment(
                id: appointmentId,
                doctor: doctor,
                date: appointmentDate,
                time: appointmentDate,
                status: .upcoming
            )
            
            // Add to appointment manager
            AppointmentManager.shared.addAppointment(appointment)
            
            // Refresh appointments
            await refreshWithThrottle(userId: userId)
            
            isCreatingTestAppointment = false
            testAppointmentResult = "✅ Test appointment created successfully with ID: \(appointmentId) for patient ID: \(patientId)\nPlease pull to refresh or use the refresh button"
            showTestAppointmentResult = true
            
        } catch {
            print("❌ Error creating test appointment: \(error)")
            isCreatingTestAppointment = false
            testAppointmentResult = "Failed to create test appointment: \(error.localizedDescription)"
            showTestAppointmentResult = true
        }
    }
}

// Add this extension at the bottom of the file to add pull-to-refresh support
extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, onRefresh: @escaping () async -> Void) -> some View {
        self.modifier(PullToRefreshModifier(isRefreshing: isRefreshing, onRefresh: onRefresh))
    }
}

struct PullToRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isRefreshing {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .padding(.top, 30)
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}