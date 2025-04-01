//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import SwiftUI

struct PatientProfileView: View {
    @ObservedObject var profileController: PatientProfileController
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var showFamilyMemberSheet = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if profileController.isLoading || isLoading {
                    ProgressView("Loading profile...")
                        .padding(.vertical, 100)
                } else if let patient = profileController.patient {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Profile header with patient image
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.teal)
                                .padding(.top, 15)
                            
                            Text(patient.name)
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.top, 5)
                            
                            HStack(spacing: 70) {
                                VStack {
                                    Image(systemName: "person.fill")
                                    Text(patient.gender)
                                        .padding(.horizontal)
                                }
                                VStack {
                                    Image(systemName: "drop.fill")
                                    if patient.bloodGroup.isEmpty || patient.bloodGroup == "Not specified" {
                                        Text("Unknown")
                                            .foregroundColor(.orange)
                                            .onTapGesture {
                                                Task {
                                                    await profileController.inspectPatientsTableSchema()
                                                    profileController.inspectCurrentPatientObject()
                                                }
                                            }
                                    } else {
                                        Text(patient.bloodGroup)
                                    }
                                }
                                VStack {
                                    Image(systemName: "calendar")
                                    Text("\(patient.age)")
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                            
                            VStack(spacing: 16) {
                                CardView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Personal Information")
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        InfoRow(title: "Address", value: patient.address ?? "Not provided")
                                        InfoRow(title: "Phone Number", value: patient.phoneNumber)
                                        
                                        HStack {
                                            Text("Blood Group")
                                                .fontWeight(.medium)
                                            Spacer()
                                            if patient.bloodGroup.isEmpty || patient.bloodGroup == "Not specified" {
                                                HStack {
                                                    Text("Not specified")
                                                        .foregroundColor(.orange)
                                                    
                                                    Menu {
                                                        ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) { group in
                                                            Button(group) {
                                                                Task {
                                                                    let success = await profileController.fixBloodGroup(
                                                                        patientId: patient.id,
                                                                        bloodGroup: group
                                                                    )
                                                                    
                                                                    if success {
                                                                        await profileController.loadProfile(userId: patient.userId)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } label: {
                                                        Text("Fix")
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 3)
                                                            .background(Color.blue)
                                                            .foregroundColor(.white)
                                                            .cornerRadius(4)
                                                    }
                                                }
                                            } else {
                                                Text(patient.bloodGroup)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                                
                                CardView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Emergency Contact")
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        InfoRow(title: "Name", value: patient.emergencyContactName ?? "Not provided")
                                        InfoRow(title: "Contact No.", value: patient.emergencyContactNumber)
                                        InfoRow(title: "Relationship", value: patient.emergencyRelationship)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                } else if let error = profileController.error {
                    // Error view
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Could not load profile")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            loadProfile()
                        }
                        .padding()
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                }
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(action: {
                    isEditing = true
                }) {
                    Text("Edit")
                }
                .disabled(profileController.patient == nil)
            )
            
            if let patient = profileController.patient {
                if !isEditing { // Only show family member button when not editing
                    Button(action: {
                        showFamilyMemberSheet = true
                    }) {
                        Text(profileController.familyMembers.isEmpty ? "Add Family Member" : "View Family Members")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 20)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isEditing) { // Changed from sheet to fullScreenCover
            NavigationStack {
                EditProfileView(profileController: profileController, isPresented: $isEditing)
            }
        }
        .sheet(isPresented: $showFamilyMemberSheet) {
            FamilyMemberListView(profileController: profileController)
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private func loadProfile() {
        guard !isLoading else { return }
        
        Task {
            isLoading = true
            if let userId = UserDefaults.standard.string(forKey: "userId") ??
                       UserDefaults.standard.string(forKey: "current_user_id") {
                await profileController.loadProfile(userId: userId)
            }
            isLoading = false
        }
    }
    
    // CardView reusable style
    struct CardView<Content: View>: View {
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
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Reusable row
    struct InfoRow: View {
        var title: String
        var value: String
        var body: some View {
            HStack {
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Text(value)
                    .foregroundColor(.gray)
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
        
        @State private var nameError = ""
        @State private var emailError = ""
        @State private var phoneError = ""
        @State private var emergencyContactNameError = ""
        @State private var emergencyContactNumberError = ""
        @State private var emergencyRelationshipError = ""
        
        func validateName(_ name: String) -> Bool {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                nameError = "Name cannot be empty"
                return false
            }
            if name.count < 2 {
                nameError = "Name must be at least 2 characters"
                return false
            }
            nameError = ""
            return true
        }
        
        func validateEmail(_ email: String) -> Bool {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                emailError = "Please enter a valid email address"
                return false
            }
            emailError = ""
            return true
        }
        
        func validatePhone(_ phone: String) -> Bool {
            let phoneRegex = "^[0-9]{10}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            if !phonePredicate.evaluate(with: phone) {
                phoneError = "Please enter a valid 10-digit phone number"
                return false
            }
            phoneError = ""
            return true
        }
        
        func validateEmergencyContact() -> Bool {
            var isValid = true
            
            if emergencyContactName.trimmingCharacters(in: .whitespaces).isEmpty {
                emergencyContactNameError = "Emergency contact name cannot be empty"
                isValid = false
            } else {
                emergencyContactNameError = ""
            }
            
            let phoneRegex = "^[0-9]{10}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            if !phonePredicate.evaluate(with: emergencyContactNumber) {
                emergencyContactNumberError = "Please enter a valid 10-digit phone number"
                isValid = false
            } else {
                emergencyContactNumberError = ""
            }
            
            if emergencyRelationship.trimmingCharacters(in: .whitespaces).isEmpty {
                emergencyRelationshipError = "Relationship cannot be empty"
                isValid = false
            } else {
                emergencyRelationshipError = ""
            }
            
            return isValid
        }
        
        func validateAllFields() -> Bool {
            let isNameValid = validateName(name)
            let isEmailValid = validateEmail(email)
            let isPhoneValid = validatePhone(phone)
            let isEmergencyValid = validateEmergencyContact()
            
            return isNameValid && isEmailValid && isPhoneValid && isEmergencyValid
        }
        
        private func updateProfile() async {
            guard let patient = profileController.patient else {
                errorMessage = "No patient data available to update"
                showErrorAlert = true
                return
            }
            
            do {
                let success = try await PatientController.shared.updatePatient(
                    id: patient.id,
                    name: name,
                    age: age,
                    gender: gender,
                    bloodGroup: bloodGroup,
                    email: email,
                    address: address,
                    phoneNumber: phone,
                    emergencyContactName: emergencyContactName,
                    emergencyContactNumber: emergencyContactNumber,
                    emergencyRelationship: emergencyRelationship
                )
                
                await MainActor.run {
                    isLoading = false
                    if success != nil {
                        // Reload profile after successful update
                        Task {
                            await profileController.loadProfile(userId: patient.userId)
                        }
                        isPresented = false
                    } else {
                        errorMessage = "Failed to update profile. Please try again."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error updating profile: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
        
        private func handleSave() {
            if validateAllFields() {
                isLoading = true
                errorMessage = ""
                Task {
                    await updateProfile()
                }
            } else {
                errorMessage = "Please fix the errors in the form"
                showErrorAlert = true
            }
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section(header: Text("Personal Information")) {
                        VStack(alignment: .leading) {
                            TextField("Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: name) { _, _ in
                                    _ = validateName(name)
                                }
                            if !nameError.isEmpty {
                                Text(nameError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
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
                        
                        VStack(alignment: .leading) {
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .onChange(of: email) { _, _ in
                                    _ = validateEmail(email)
                                }
                            if !emailError.isEmpty {
                                Text(emailError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Section(header: Text("Contact Information")) {
                        VStack(alignment: .leading) {
                            TextField("Phone Number", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: phone) { _, _ in
                                    _ = validatePhone(phone)
                                }
                            if !phoneError.isEmpty {
                                Text(phoneError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        TextField("Address", text: $address)
                    }
                    
                    Section(header: Text("Emergency Contact")) {
                        VStack(alignment: .leading) {
                            TextField("Name", text: $emergencyContactName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: emergencyContactName) { _, _ in
                                    _ = validateEmergencyContact()
                                }
                            if !emergencyContactNameError.isEmpty {
                                Text(emergencyContactNameError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            TextField("Phone Number", text: $emergencyContactNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: emergencyContactNumber) { _, _ in
                                    _ = validateEmergencyContact()
                                }
                            if !emergencyContactNumberError.isEmpty {
                                Text(emergencyContactNumberError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            TextField("Relationship", text: $emergencyRelationship)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: emergencyRelationship) { _, _ in
                                    _ = validateEmergencyContact()
                                }
                            if !emergencyRelationshipError.isEmpty {
                                Text(emergencyRelationshipError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            handleSave()
                        }
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
            }
            .onAppear {
                if let patient = profileController.patient {
                    name = patient.name
                    age = patient.age
                    gender = patient.gender
                    bloodGroup = patient.bloodGroup
                    email = patient.email ?? ""
                    phone = patient.phoneNumber
                    address = patient.address ?? ""
                    emergencyContactName = patient.emergencyContactName ?? ""
                    emergencyContactNumber = patient.emergencyContactNumber
                    emergencyRelationship = patient.emergencyRelationship
                }
            }
        }
    }
}
