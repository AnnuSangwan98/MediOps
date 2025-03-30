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
            ScrollView (.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    if profileController.isLoading || isLoading {
                        ProgressView("Loading profile...")
                            .padding(.vertical, 100)
                    } else if let patient = profileController.patient {
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
                                Text(patient.bloodGroup)
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
                                    InfoRow(title: "Blood Group", value: patient.bloodGroup)
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
                                Task {
                                    isLoading = true
                                    if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                                               UserDefaults.standard.string(forKey: "current_user_id") {
                                        await profileController.loadProfile(userId: userId)
                                    } else {
                                        // Create a test patient if no user ID is available
                                        await profileController.createAndInsertTestPatientInSupabase()
                                    }
                                    isLoading = false
                                }
                            }
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        // No data view (no patient and no error)
                        VStack(spacing: 20) {
                            Text("No patient information available")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding()
                            
                            Button("Create Test Profile") {
                                Task {
                                    isLoading = true
                                    await profileController.createAndInsertTestPatientInSupabase()
                                    isLoading = false
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 50)
                    }
                }
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Edit") {
                    isEditing = true
                }
                .disabled(profileController.patient == nil)
            )
            
            if let patient = profileController.patient {
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
                .sheet(isPresented: $showFamilyMemberSheet) {
                    FamilyMemberListView(profileController: profileController)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(profileController: profileController, isPresented: $isEditing)
        }
        .onAppear {
            // Check if we need to load the profile
            if profileController.patient == nil && !profileController.isLoading && profileController.error == nil {
                Task {
                    isLoading = true
                    if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                               UserDefaults.standard.string(forKey: "current_user_id") {
                        await profileController.loadProfile(userId: userId)
                    } else {
                        // Create a test patient if no user ID is available
                        await profileController.createAndInsertTestPatientInSupabase()
                    }
                    isLoading = false
                }
            }
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
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                        
                        TextField("Address", text: $address)
                    }
                    
                    Section(header: Text("Emergency Contact")) {
                        TextField("Name", text: $emergencyContactName)
                        
                        TextField("Phone Number", text: $emergencyContactNumber)
                            .keyboardType(.phonePad)
                        
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
                        phone = patient.phoneNumber
                        address = patient.address ?? ""
                        emergencyContactName = patient.emergencyContactName ?? ""
                        emergencyContactNumber = patient.emergencyContactNumber
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
                            guard let patient = profileController.patient else {
                                errorMessage = "No patient data available to update"
                                showErrorAlert = true
                                return
                            }
                            
                            // Basic validation
                            if name.isEmpty {
                                errorMessage = "Name cannot be empty"
                                return
                            }
                            
                            if phone.isEmpty {
                                errorMessage = "Phone number cannot be empty"
                                return
                            }
                            
                            if emergencyContactNumber.isEmpty {
                                errorMessage = "Emergency contact number cannot be empty"
                                return
                            }
                            
                            isLoading = true
                            errorMessage = "" // Clear any previous error
                            
                            Task {
                                print("🔄 EDIT PROFILE: Starting profile update with data:")
                                print("  - Name: \(name)")
                                print("  - Age: \(age)")
                                print("  - Gender: \(gender)")
                                print("  - Blood Group: \(bloodGroup)")
                                print("  - Email: \(email)")
                                print("  - Phone: \(phone)")
                                
                                let success = await profileController.updateProfile(
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
                                    
                                    if success {
                                        print("✅ EDIT PROFILE: Profile updated successfully")
                                        isPresented = false
                                    } else {
                                        print("❌ EDIT PROFILE ERROR: Failed to update profile")
                                        errorMessage = "Failed to update profile. Please try again."
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



