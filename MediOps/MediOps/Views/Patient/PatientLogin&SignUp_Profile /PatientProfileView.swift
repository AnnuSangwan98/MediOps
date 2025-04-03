//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import SwiftUI
import UIKit

struct PatientProfileView: View {
    @ObservedObject var profileController: PatientProfileController
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var showFamilyMemberSheet = false
    @State private var isLoading = false
    @State private var showLogoutAlert = false
    @State private var hasCompletedInitialLoad = false
    @State private var showLanguageSelection = false
    @ObservedObject private var translationManager = TranslationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var profileContent: some View {
        VStack(spacing: 20) {
            if let patient = profileController.patient {
                profileHeader(patient)
                bloodGroupCard(patient)
                informationCards(patient)
                logoutButton
            } else if let error = profileController.error {
                errorView(error)
            } else if isLoading {
                loadingView
            } else {
                ProgressView()
                    .padding(.vertical, 100)
            }
        }
    }
    
    private func profileHeader(_ patient: Patient) -> some View {
        VStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(themeManager.colors.primary)
                .padding(.top, 15)
            
            Text(patient.name)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.colors.text)
                .padding(.top, 5)
            
            HStack(spacing: 70) {
                VStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(themeManager.colors.primary)
                    Text(patient.gender)
                        .padding(.horizontal)
                        .foregroundColor(themeManager.colors.text)
                }
                VStack {
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.colors.primary)
                    Text("\(patient.age)")
                        .foregroundColor(themeManager.colors.text)
                }
            }
            .font(.subheadline)
            .padding(.bottom, 20)
        }
    }
    
    private func bloodGroupCard(_ patient: Patient) -> some View {
        CardView {
            VStack(alignment: .leading) {
                Text("blood_group".localized)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.text)
                    .padding(.bottom, 2)
                
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(themeManager.colors.error)
                        .font(.title2)
                    
                    if patient.bloodGroup.isEmpty || patient.bloodGroup == "Not specified" {
                        Text("unknown".localized)
                            .foregroundColor(themeManager.colors.warning)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .onTapGesture {
                                Task {
                                    await profileController.inspectPatientsTableSchema()
                                    profileController.inspectCurrentPatientObject()
                                }
                            }
                        
                        Button {
                            Task {
                                await profileController.checkBloodGroupField(patientId: patient.id)
                            }
                        } label: {
                            Text("Fix")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(themeManager.colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    } else {
                        Text(patient.bloodGroup)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                    }
                }
            }
            .padding(.vertical, 5)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    private func informationCards(_ patient: Patient) -> some View {
        VStack(spacing: 16) {
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("personal_information".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                        .padding(.bottom, 5)
                    InfoRow(title: "address".localized, value: patient.address ?? "not_provided".localized)
                    InfoRow(title: "phone_number".localized, value: patient.phoneNumber)
                }
            }
            
            CardView {
                Button(action: {
                    showLanguageSelection = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("language".localized)
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                            
                            Text(translationManager.currentLanguage.displayName)
                                .foregroundColor(themeManager.colors.subtext)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(themeManager.colors.subtext)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    private var logoutButton: some View {
        Button(action: {
            showLogoutAlert = true
        }) {
            Text("logout".localized)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.colors.error)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(themeManager.colors.warning)
            
            Text("Could not load profile")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(themeManager.colors.text)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.colors.subtext)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    isLoading = true
                    if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                               UserDefaults.standard.string(forKey: "current_user_id") {
                        await profileController.loadProfile(userId: userId)
                    } else {
                        await profileController.createAndInsertTestPatientInSupabase()
                    }
                    isLoading = false
                }
            }
            .padding()
            .background(themeManager.colors.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var loadingView: some View {
        ProgressView("Loading profile data...")
            .padding(.vertical, 100)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                profileContent
            }
            .navigationTitle("patient_profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(themeManager.colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("edit".localized) {
                        isEditing = true
                    }
                    .foregroundColor(themeManager.colors.primary)
                    .disabled(profileController.patient == nil)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(profileController: profileController, isPresented: $isEditing)
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .alert("logout".localized, isPresented: $showLogoutAlert) {
            Button("cancel".localized, role: .cancel) { }
            Button("yes_logout".localized, role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("are_you_sure_logout".localized)
        }
        .onAppear {
            loadProfileData()
        }
    }
    
    private func handleLogout() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "current_user_id")
        defaults.synchronize()
        
        dismiss()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let newNavigationState = AppNavigationState()
        newNavigationState.signOut()
        
        let contentView = NavigationStack {
            RoleSelectionView()
        }
        .environmentObject(newNavigationState)
        
        window.rootViewController = UIHostingController(rootView: contentView)
        window.makeKeyAndVisible()
    }
    
    private func loadProfileData() {
        print("🔍 DEBUG: PatientProfileView appeared, checking data state")
        print("🔍 DEBUG: Patient data: \(profileController.patient != nil ? "Available" : "Not available")")
        print("🔍 DEBUG: Error: \(profileController.error?.localizedDescription ?? "None")")
        
        if profileController.patient == nil && !profileController.isLoading {
            Task {
                print("🔄 DEBUG: Starting patient data load")
                await MainActor.run { isLoading = true }
                
                if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                           UserDefaults.standard.string(forKey: "current_user_id") {
                    await handleProfileLoad(userId: userId)
                } else {
                    print("⚠️ DEBUG: No userId found in UserDefaults")
                }
                
                await MainActor.run {
                    isLoading = false
                    hasCompletedInitialLoad = true
                }
            }
        } else {
            print("ℹ️ DEBUG: Patient data already loaded or loading in progress")
            if !hasCompletedInitialLoad {
                hasCompletedInitialLoad = true
            }
        }
    }
    
    private func handleProfileLoad(userId: String) async {
        print("🔄 DEBUG: Loading profile for userId: \(userId)")
        await profileController.loadProfile(userId: userId)
        
        if let patient = profileController.patient {
            print("✅ DEBUG: Successfully loaded patient: \(patient.name)")
            
            if patient.bloodGroup.isEmpty || patient.bloodGroup == "Not specified" {
                print("⚠️ DEBUG: Blood group missing, checking...")
                await profileController.checkBloodGroupField(patientId: patient.id)
                await profileController.loadProfile(userId: userId)
            }
        } else {
            print("⚠️ DEBUG: Failed to load patient data")
        }
    }
    
    // CardView reusable style
    struct CardView<Content: View>: View {
        @ObservedObject private var themeManager = ThemeManager.shared
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            VStack {
                content
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(color: themeManager.colors.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Reusable row
    struct InfoRow: View {
        @ObservedObject private var themeManager = ThemeManager.shared
        var title: String
        var value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.text)
                Spacer()
                Text(value)
                    .foregroundColor(themeManager.colors.subtext)
            }
        }
    }
    
    struct EditProfileView: View {
        @ObservedObject var profileController: PatientProfileController
        @Binding var isPresented: Bool
        
        @State private var name: String = ""
        @State private var age: Int = 0
        @State private var gender: String = ""
        @State private var bloodGroup: String = ""
        @State private var email: String = ""
        @State private var phone: String = ""
        @State private var address: String = ""
        @State private var emergencyContactName: String = ""
        @State private var emergencyContactNumber: String = ""
        @State private var emergencyRelationship: String = ""
        @State private var isLoading = false
        @State private var errorMessage = ""
        @State private var showErrorAlert = false
        
        // Add this computed property for phone validation
        private var phoneNumberIsValid: Bool {
            let digitsOnly = phone.filter { $0.isNumber }
            return digitsOnly.count == 10
        }
        
        // Add this computed property for emergency contact validation
        private var emergencyContactNumberIsValid: Bool {
            let digitsOnly = emergencyContactNumber.filter { $0.isNumber }
            return digitsOnly.count == 10
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section(header: Text("Personal Information")) {
                            TextField("Name", text: $name)
                        
                        Stepper("Age: \(age)", value: $age, in: 1...120)
                        
                        Picker("Gender", selection: $gender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        
                        Picker("Blood Group", selection: $bloodGroup) {
                            ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) { group in
                                Text(group).tag(group)
                            }
                        }
                        
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                    }
                    
                    Section(header: Text("Contact Information")) {
                        TextField("Phone Number (10 digits)", text: $phone)
                            .keyboardType(.phonePad)
                            .onChange(of: phone) { newValue in
                                // Restrict to digits only and maximum 10 characters
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 10 {
                                    phone = String(filtered.prefix(10))
                                } else {
                                    phone = filtered
                                }
                            }
                        
                        if !phone.isEmpty && !phoneNumberIsValid {
                            Text("Phone number must be 10 digits")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        TextField("Address", text: $address)
                    }
                    
                    Section(header: Text("Emergency Contact")) {
                            TextField("Name", text: $emergencyContactName)
                        
                        TextField("Phone Number (10 digits)", text: $emergencyContactNumber)
                            .keyboardType(.phonePad)
                            .onChange(of: emergencyContactNumber) { newValue in
                                // Restrict to digits only and maximum 10 characters
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 10 {
                                    emergencyContactNumber = String(filtered.prefix(10))
                                } else {
                                    emergencyContactNumber = filtered
                                }
                            }
                            
                        if !emergencyContactNumber.isEmpty && !emergencyContactNumberIsValid {
                            Text("Emergency contact number must be 10 digits")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                            TextField("Relationship", text: $emergencyRelationship)
                    }
                    
                    if !errorMessage.isEmpty {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    if let patient = profileController.patient {
                        name = patient.name
                        age = patient.age
                        gender = patient.gender
                        bloodGroup = patient.bloodGroup
                        email = patient.email ?? ""
                        // Format phone number to ensure only digits
                        phone = patient.phoneNumber.filter { $0.isNumber }
                        address = patient.address ?? ""
                        emergencyContactName = patient.emergencyContactName ?? ""
                        // Format emergency contact number to ensure only digits
                        emergencyContactNumber = patient.emergencyContactNumber.filter { $0.isNumber }
                        emergencyRelationship = patient.emergencyRelationship
                    }
                }
                .overlay(
                    Group {
                        if isLoading {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .overlay(
                                    VStack {
                                        ProgressView("Saving profile...")
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                        
                                        Text("Please wait...")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                            .padding(.top, 8)
                                    }
                                )
                        }
                    }
                )
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK")) {
                            errorMessage = ""
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            // Get the current patient and try to ensure it's valid
                            let currentPatient = profileController.patient
                            
                            // Debug the current patient state
                            print("🔍 EDIT PROFILE: Current patient before update: \(String(describing: currentPatient))")
                            
                            // Only show error if there's no patient AND we can't create one
                            if currentPatient == nil {
                                // Try to refresh the patient data
                                print("⚠️ EDIT PROFILE: No patient data available, attempting to retrieve...")
                                
                                Task {
                                    isLoading = true
                                    
                                    // Try to get the current user ID
                                    if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                                               UserDefaults.standard.string(forKey: "current_user_id") {
                                        // Try to load the patient profile
                                        print("🔄 EDIT PROFILE: Attempting to load profile for user ID: \(userId)")
                                        await profileController.loadProfile(userId: userId)
                                        
                                        await MainActor.run {
                                            isLoading = false
                                            
                                            // Check if we now have patient data
                                            if profileController.patient != nil {
                                                print("✅ EDIT PROFILE: Successfully retrieved patient data")
                                                // Try again with the Save button action
                                                continueWithSave()
                                            } else {
                                                // Still no patient data, create a test patient
                                                print("⚠️ EDIT PROFILE: Failed to retrieve patient data, creating test patient...")
                                                Task {
                                                    isLoading = true
                                                    let success = await profileController.createAndInsertTestPatientInSupabase()
                                                    
                                                    await MainActor.run {
                                                        isLoading = false
                                                        if success {
                                                            print("✅ EDIT PROFILE: Successfully created test patient")
                                                            // Try again with the Save button action
                                                            continueWithSave()
                                                        } else {
                                                            errorMessage = "Could not create patient profile. Please try again."
                                                            showErrorAlert = true
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        await MainActor.run {
                                            isLoading = false
                                            errorMessage = "No user ID found. Please log in again."
                                            showErrorAlert = true
                                        }
                                    }
                                }
                                return
                            }
                            
                            // If we have a patient, continue with validation and saving
                            continueWithSave()
                        }
                    }
                }
            }
        }
        
        // Helper function to continue with validation and saving
        func continueWithSave() {
            // Basic validation
            if name.isEmpty {
                errorMessage = "Name cannot be empty"
                return
            }
            
            if phone.isEmpty {
                errorMessage = "Phone number cannot be empty"
                return
            }
            
            if !phoneNumberIsValid {
                errorMessage = "Phone number must be exactly 10 digits"
                return
            }
            
            if emergencyContactNumber.isEmpty {
                errorMessage = "Emergency contact number cannot be empty"
                return
            }
            
            if !emergencyContactNumberIsValid {
                errorMessage = "Emergency contact number must be exactly 10 digits"
                return
            }
            
            if emergencyContactName.isEmpty {
                errorMessage = "Emergency contact name cannot be empty"
                return
            }
            
            if emergencyRelationship.isEmpty {
                errorMessage = "Emergency contact relationship cannot be empty"
                return
            }
            
            isLoading = true
            errorMessage = "" // Clear any previous error
            
            // Ensure we have a patient
            guard let patient = profileController.patient else {
                errorMessage = "Patient data is still not available"
                showErrorAlert = true
                isLoading = false
                return
            }
            
            // Create a local backup of the patient data before attempting to update
            let originalPatient = patient
            
            // Create an updated patient object with the form data
            let updatedPatient = Patient(
                id: patient.id,
                userId: patient.userId,
                name: name,
                age: age,
                gender: gender,
                createdAt: patient.createdAt,
                updatedAt: Date(),
                email: email,
                emailVerified: patient.emailVerified,
                bloodGroup: bloodGroup,
                address: address,
                phoneNumber: phone,
                emergencyContactName: emergencyContactName,
                emergencyContactNumber: emergencyContactNumber,
                emergencyRelationship: emergencyRelationship
            )
            
            Task {
                print("🔄 EDIT PROFILE: Starting profile update with data:")
                print("  - Patient ID: \(patient.id)")
                print("  - User ID: \(patient.userId)")
                print("  - Name: \(name)")
                print("  - Age: \(age)")
                print("  - Gender: \(gender)")
                print("  - Blood Group: \(bloodGroup)")
                print("  - Email: \(email)")
                print("  - Phone: \(phone)")
                
                // First update the local model to provide an immediate response
                await MainActor.run {
                    profileController.patient = updatedPatient
                }
                
                var serverUpdateSuccess = false
                
                // Try to update on the server
                do {
                    serverUpdateSuccess = await profileController.updateProfileWithRetry(
                        patientId: patient.id,
                        userId: patient.userId,
                        name: name,
                        age: age,
                        gender: gender,
                        bloodGroup: bloodGroup,
                        email: email,
                        phoneNumber: phone,
                        address: address,
                        emergencyContactName: emergencyContactName,
                        emergencyContactNumber: emergencyContactNumber,
                        emergencyRelationship: emergencyRelationship
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        
                        if serverUpdateSuccess {
                            print("✅ EDIT PROFILE: Profile updated successfully on server")
                            isPresented = false
                        } else {
                            print("⚠️ EDIT PROFILE: Server update failed, but using local data")
                            // Show a warning but dismiss anyway since we've updated locally
                            errorMessage = "Server update may have failed, but your changes are saved locally."
                            
                            // Delay the dismissal to allow the user to see the message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                self.isPresented = false
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        print("❌ EDIT PROFILE ERROR: \(error.localizedDescription)")
                        // Show warning but keep the local changes
                        errorMessage = "Server error occurred, but your changes are saved locally."
                        
                        // Delay the dismissal to allow the user to see the message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.isPresented = false
                        }
                    }
                }
            }
        }
    }
}




