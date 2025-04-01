//import SwiftUI
//
//struct ProfileView: View {
//    @AppStorage("userId") private var userId: String?
//    @AppStorage("current_user_id") private var currentUserId: String?
//    @AppStorage("current_patient_id") private var patientId: String?
//    
//    @StateObject private var profileController = PatientProfileController()
//    @State private var showingLogoutAlert = false
//    @State private var showingEditProfile = false
//    @State private var manualRefreshCounter = 0 // For force-refreshing
//    @State private var isInitialLoadComplete = false
//    @State private var isManuallyRefreshing = false
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 20) {
//                    if profileController.isLoading && !isInitialLoadComplete {
//                        VStack {
//                            ProgressView("Loading profile...")
//                                .padding()
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .padding(.top, 100)
//                    } else if let error = profileController.error {
//                        VStack(spacing: 16) {
//                            Image(systemName: "exclamationmark.triangle")
//                                .font(.system(size: 50))
//                                .foregroundColor(.orange)
//                            
//                            Text("Error loading profile")
//                                .font(.headline)
//                            
//                            Text(error.localizedDescription)
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                                .multilineTextAlignment(.center)
//                            
//                            // Show debug info
//                            Text("Debug Info:")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                            
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("User ID: \(userId ?? "nil")")
//                                Text("Current User ID: \(currentUserId ?? "nil")")
//                                Text("Patient ID: \(patientId ?? "nil")")
//                            }
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                            .padding(.horizontal)
//                            
//                            Button("Try Again") {
//                                Task {
//                                    isManuallyRefreshing = true
//                                    // Try all available IDs
//                                    if let id = userId {
//                                        print("ProfileView: Retrying with userId: \(id)")
//                                        await profileController.loadProfile(userId: id)
//                                    } else if let id = currentUserId {
//                                        print("ProfileView: Retrying with currentUserId: \(id)")
//                                        userId = id // Sync the IDs
//                                        await profileController.loadProfile(userId: id)
//                                    } else {
//                                        print("ProfileView: No user ID available for retry")
//                                    }
//                                    isManuallyRefreshing = false
//                                }
//                            }
//                            .padding()
//                            .background(Color.teal)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                            
//                            // Set user ID manually (for debugging)
//                            Button("Fix User ID") {
//                                let userIdToSet = currentUserId ?? "USER001" // Use a fallback ID if needed
//                                print("Setting userId to: \(userIdToSet)")
//                                userId = userIdToSet
//                                UserDefaults.standard.synchronize()
//                                manualRefreshCounter += 1
//                            }
//                            .padding()
//                            .background(Color.orange)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                            
//                            // Create test profile for debugging
//                            Button("Create Test Profile") {
//                                Task {
//                                    isManuallyRefreshing = true
//                                    let success = await profileController.createAndInsertTestPatientInSupabase()
//                                    if success {
//                                        print("✅ Test patient successfully inserted and loaded")
//                                        isInitialLoadComplete = true
//                                    } else {
//                                        print("❌ Failed to insert test patient")
//                                    }
//                                    isManuallyRefreshing = false
//                                }
//                            }
//                            .padding()
//                            .background(Color.purple)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                            
//                            // Test database connection
//                            Button("Test Connection") {
//                                Task {
//                                    await checkSupabaseConnection()
//                                }
//                            }
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                        }
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .padding(.top, 100)
//                    } else {
//                        // Profile Header
//                        VStack {
//                            Image(systemName: "person.circle.fill")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.teal)
//                            
//                            if let patient = profileController.patient {
//                                Text(patient.name)
//                                    .font(.title2)
//                                    .fontWeight(.semibold)
//                                
//                                Text(patient.phoneNumber)
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                    
//                                if isManuallyRefreshing {
//                                    ProgressView()
//                                        .padding(.top, 8)
//                                }
//                            } else {
//                                Text("No profile available")
//                                    .font(.title2)
//                                    .foregroundColor(.gray)
//                                    
//                                Button("Create Test Profile") {
//                                    Task {
//                                        isManuallyRefreshing = true
//                                        let success = await profileController.createAndInsertTestPatientInSupabase()
//                                        isManuallyRefreshing = false
//                                        if success {
//                                            print("✅ Auto-created test patient profile")
//                                            isInitialLoadComplete = true
//                                        }
//                                    }
//                                }
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                                .padding(.top, 8)
//                            }
//                        }
//                        .padding()
//                        
//                        // Profile Options
//                        VStack(spacing: 15) {
//                            ProfileOptionButton(
//                                icon: "person.text.rectangle",
//                                title: "Edit Profile",
//                                action: { showingEditProfile = true }
//                            )
//                            
//                            ProfileOptionButton(
//                                icon: "bell",
//                                title: "Notifications",
//                                action: {}
//                            )
//                            
//                            ProfileOptionButton(
//                                icon: "doc.text",
//                                title: "Medical Records",
//                                action: {}
//                            )
//                            
//                            ProfileOptionButton(
//                                icon: "heart",
//                                title: "Health Data",
//                                action: {}
//                            )
//                            
//                            ProfileOptionButton(
//                                icon: "gear",
//                                title: "Settings",
//                                action: {}
//                            )
//                            
//                            ProfileOptionButton(
//                                icon: "questionmark.circle",
//                                title: "Help & Support",
//                                action: {}
//                            )
//                            
//                            Button(action: { showingLogoutAlert = true }) {
//                                HStack {
//                                    Image(systemName: "rectangle.portrait.and.arrow.right")
//                                        .foregroundColor(.red)
//                                    Text("Logout")
//                                        .foregroundColor(.red)
//                                    Spacer()
//                                    Image(systemName: "chevron.right")
//                                        .foregroundColor(.gray)
//                                }
//                                .padding()
//                                .background(Color.white)
//                                .cornerRadius(10)
//                                .shadow(color: .gray.opacity(0.1), radius: 5)
//                            }
//                        }
//                        .padding()
//                    }
//                }
//            }
//            .refreshable {
//                print("ProfileView: Manual refresh requested")
//                isManuallyRefreshing = true
//                if let id = userId ?? currentUserId {
//                    print("ProfileView: Refreshing with user ID: \(id)")
//                    await profileController.loadProfile(userId: id)
//                } else {
//                    print("ProfileView: No user ID available for refresh, creating test profile")
//                    await profileController.createAndInsertTestPatientInSupabase()
//                }
//                isManuallyRefreshing = false
//            }
//            .background(Color(.systemGray6))
//            .navigationTitle("Profile")
//            .alert("Logout", isPresented: $showingLogoutAlert) {
//                Button("Cancel", role: .cancel) { }
//                Button("Logout", role: .destructive) {
//                    logout()
//                }
//            } message: {
//                Text("Are you sure you want to logout?")
//            }
//            .sheet(isPresented: $showingEditProfile) {
//                if let patient = profileController.patient {
//                    EditProfileView(profileController: profileController)
//                } else {
//                    Text("No patient profile available to edit")
//                        .padding()
//                }
//            }
//        }
//        .id(manualRefreshCounter) // Force view refresh when counter changes
//        .onAppear {
//            print("ProfileView onAppear, checking for userId")
//            attemptProfileLoad()
//        }
//        .task {
//            print("ProfileView task, checking for userId")
//            await attemptProfileLoadAsync()
//        }
//    }
//    
//    private func attemptProfileLoad() {
//        // Ensure user IDs are synchronized
//        if let currentId = currentUserId, userId == nil {
//            print("📱 Synchronizing userId with currentUserId: \(currentId)")
//            userId = currentId
//            UserDefaults.standard.synchronize()
//        } else if let id = userId, currentUserId == nil {
//            print("📱 Synchronizing currentUserId with userId: \(id)")
//            currentUserId = id
//            UserDefaults.standard.synchronize()
//        }
//        
//        // If still no userId available, create a test ID
//        if userId == nil && currentUserId == nil {
//            let testId = "USER_\(Int(Date().timeIntervalSince1970))"
//            print("📱 No userId found, creating test ID: \(testId)")
//            userId = testId
//            currentUserId = testId
//            UserDefaults.standard.synchronize()
//        }
//    }
//    
//    private func attemptProfileLoadAsync() async {
//        // First run non-async setup
//        attemptProfileLoad()
//        
//        // Now try to load the profile
//        if let id = userId ?? currentUserId {
//            print("Found userId: \(id), loading profile")
//            await profileController.loadProfile(userId: id)
//            
//            if let patient = profileController.patient {
//                print("Successfully loaded patient: \(patient.name)")
//                isInitialLoadComplete = true
//            } else if let error = profileController.error {
//                print("Error loading patient: \(error.localizedDescription)")
//                // Let's create a test patient if loading failed
//                if !isInitialLoadComplete {
//                    print("Creating test patient after load failure")
//                    let success = await profileController.createAndInsertTestPatientInSupabase()
//                    if success {
//                        print("Successfully created and loaded test patient")
//                        isInitialLoadComplete = true
//                    }
//                }
//            } else if profileController.isLoading {
//                print("Profile is still loading...")
//            } else {
//                print("No patient data available after loading profile")
//                // Create a test patient if we don't have one
//                if !isInitialLoadComplete {
//                    print("Creating test patient since none was found")
//                    let success = await profileController.createAndInsertTestPatientInSupabase()
//                    if success {
//                        print("Successfully created and loaded test patient")
//                        isInitialLoadComplete = true
//                    }
//                }
//            }
//        } else {
//            print("No userId found in UserDefaults")
//        }
//    }
//    
//    private func logout() {
//        UserDefaults.standard.removeObject(forKey: "userId")
//        UserDefaults.standard.removeObject(forKey: "userRole")
//        
//        // Navigate to login screen
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = windowScene.windows.first {
//            let loginView = LoginView(
//                title: "Login",
//                initialCredentials: PatientCredentials(email: "", password: ""),
//                onLogin: { credentials in
//                    // Handle login if needed
//                }
//            )
//            window.rootViewController = UIHostingController(rootView: loginView)
//            window.makeKeyAndVisible()
//        }
//    }
//    
//    private func checkSupabaseConnection() async {
//        print("🔌 Testing Supabase connection...")
//        
//        do {
//            // Try to fetch a simple "users" table count
//            let results = try await SupabaseController.shared.select(
//                from: "users",
//                columns: "count(*)"
//            )
//            
//            if let firstResult = results.first, let count = firstResult["count"] as? Int {
//                print("✅ Supabase connection SUCCESS! Total users: \(count)")
//            } else {
//                print("⚠️ Supabase connection worked but couldn't parse count result")
//            }
//            
//            // Try to fetch patients table structure - limit to 5 records by modifying the query
//            let patientResults = try await SupabaseController.shared.select(
//                from: "patients",
//                columns: "id,user_id,name"
//            )
//            
//            // Only show up to 5 results in the log
//            let limitedResults = Array(patientResults.prefix(5))
//            print("✅ Patients table query successful (returned \(patientResults.count) total records, showing first \(limitedResults.count))")
//            if !limitedResults.isEmpty {
//                print("📊 Sample patient data: \(limitedResults[0])")
//            }
//            
//        } catch {
//            print("❌ Supabase connection FAILED: \(error.localizedDescription)")
//        }
//    }
//}
//
//struct ProfileOptionButton: View {
//    let icon: String
//    let title: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Image(systemName: icon)
//                    .foregroundColor(.teal)
//                Text(title)
//                    .foregroundColor(.black)
//                Spacer()
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//            }
//            .padding()
//            .background(Color.white)
//            .cornerRadius(10)
//            .shadow(color: .gray.opacity(0.1), radius: 5)
//        }
//    }
//}
//
//struct EditProfileView: View {
//    @ObservedObject var profileController: PatientProfileController
//    @Environment(\.dismiss) private var dismiss
//    @State private var name: String = ""
//    @State private var age: Int = 0
//    @State private var gender: String = ""
//    @State private var bloodGroup: String = ""
//    @State private var email: String = ""
//    @State private var phone: String = ""
//    @State private var address: String = ""
//    @State private var emergencyContactName: String = ""
//    @State private var emergencyContactNumber: String = ""
//    @State private var emergencyRelationship: String = ""
//    @State private var isSaving: Bool = false
//    @State private var errorMessage: String = ""
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section(header: Text("Personal Information")) {
//                    TextField("Name", text: $name)
//                    
//                    Stepper("Age: \(age)", value: $age, in: 1...120)
//                    
//                    Picker("Gender", selection: $gender) {
//                        Text("Male").tag("Male")
//                        Text("Female").tag("Female")
//                        Text("Other").tag("Other")
//                    }
//                    
//                    Picker("Blood Group", selection: $bloodGroup) {
//                        ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) { group in
//                            Text(group).tag(group)
//                        }
//                    }
//                    
//                    TextField("Email", text: $email)
//                        .keyboardType(.emailAddress)
//                        .autocapitalization(.none)
//                }
//                
//                Section(header: Text("Contact Information")) {
//                    TextField("Phone", text: $phone)
//                        .textContentType(.telephoneNumber)
//                        .keyboardType(.phonePad)
//                    
//                    TextField("Address", text: $address)
//                }
//                
//                Section(header: Text("Emergency Contact")) {
//                    TextField("Name", text: $emergencyContactName)
//                    
//                    TextField("Phone Number", text: $emergencyContactNumber)
//                        .keyboardType(.phonePad)
//                    
//                    TextField("Relationship", text: $emergencyRelationship)
//                }
//            }
//            .navigationTitle("Edit Profile")
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarItems(
//                leading: Button("Cancel") { dismiss() },
//                trailing: Button("Save") {
//                    isSaving = true
//                    print("Saving profile data...")
//                    
//                    Task {
//                        do {
//                            print("🔄 EDIT PROFILE: Starting profile update with data:")
//                            print("  - Name: \(name)")
//                            print("  - Age: \(age)")
//                            print("  - Gender: \(gender)")
//                            print("  - Blood Group: \(bloodGroup)")
//                            print("  - Email: \(email)")
//                            print("  - Phone: \(phone)")
//                            
//                            let success = await profileController.updateProfile(
//                                name: name,
//                                age: age,
//                                gender: gender,
//                                bloodGroup: bloodGroup,
//                                email: email,
//                                phoneNumber: phone,
//                                address: address,
//                                emergencyContactName: emergencyContactName,
//                                emergencyContactNumber: emergencyContactNumber,
//                                emergencyRelationship: emergencyRelationship
//                            )
//                            
//                            if success {
//                                print("✅ EDIT PROFILE: Profile updated successfully")
//                                
//                                // If user ID is available, reload profile data
//                                if let userId = UserDefaults.standard.string(forKey: "userId") {
//                                    print("🔄 EDIT PROFILE: Reloading profile with user ID: \(userId)")
//                                    await profileController.loadProfile(userId: userId)
//                                }
//                                
//                                await MainActor.run {
//                                    isSaving = false
//                                    dismiss()
//                                }
//                            } else {
//                                print("❌ EDIT PROFILE ERROR: Failed to update profile")
//                                await MainActor.run {
//                                    errorMessage = "Failed to update profile. Please try again."
//                                    isSaving = false
//                                }
//                            }
//                        } catch {
//                            print("❌ EDIT PROFILE ERROR: \(error)")
//                            await MainActor.run {
//                                errorMessage = "Error: \(error.localizedDescription)"
//                                isSaving = false
//                            }
//                        }
//                    }
//                }
//                .disabled(isSaving)
//            )
//            .overlay(
//                Group {
//                    if isSaving {
//                        Color.black.opacity(0.4)
//                            .ignoresSafeArea()
//                            .overlay(
//                                ProgressView("Saving...")
//                                    .padding()
//                                    .background(Color.white)
//                                    .cornerRadius(10)
//                                    .shadow(radius: 5)
//                            )
//                    }
//                }
//            )
//            .alert("Error", isPresented: Binding<Bool>(
//                get: { !errorMessage.isEmpty },
//                set: { if !$0 { errorMessage = "" } }
//            )) {
//                Button("OK") { errorMessage = "" }
//            } message: {
//                Text(errorMessage)
//            }
//            .onAppear {
//                print("EditProfileView appeared, initializing with patient data")
//                if let patient = profileController.patient {
//                    print("Found patient: \(patient.name)")
//                    name = patient.name
//                    age = patient.age
//                    gender = patient.gender
//                    bloodGroup = patient.bloodGroup
//                    email = patient.email ?? ""
//                    phone = patient.phoneNumber
//                    address = patient.address ?? ""
//                    emergencyContactName = patient.emergencyContactName ?? ""
//                    emergencyContactNumber = patient.emergencyContactNumber
//                    emergencyRelationship = patient.emergencyRelationship
//                } else {
//                    print("No patient data available to initialize EditProfileView")
//                }
//            }
//        }
//    }
//} 
