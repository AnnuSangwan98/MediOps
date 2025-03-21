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

    
    var body: some View {
        NavigationStack {
            ScrollView (.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.teal)
                        .padding(.top, 15)
                    
                    Text(profileController.patient.name)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    
                    HStack(spacing: 70) {
                        
                        VStack {
                            Image(systemName: "person.fill")
                            Text(profileController.patient.gender)
                                .padding(.horizontal)
                        }
                        VStack {
                            Image(systemName: "drop.fill")
                            Text(profileController.patient.bloodGroup)
                        }
                        
                        VStack {
                          
                                Image(systemName: "calendar")
                                Text(profileController.patient.age)
                            
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
                                InfoRow(title: "Address", value: profileController.patient.address)
                                InfoRow(title: "Phone Number", value: profileController.patient.phoneNumber)
                                InfoRow(title: "Blood Group", value: profileController.patient.bloodGroup)
                            }
                        }
                        
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Emergency Contact")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                InfoRow(title: "Name", value: profileController.patient.emergencyContactName)
                                InfoRow(title: "Contact No.", value: profileController.patient.emergencyContactNumber)
                                InfoRow(title: "Relationship", value: profileController.patient.emergencyRelationship)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Patient Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }

                Button(action: {
                    showFamilyMemberSheet = true
                }) {
                    Text(profileController.patient.familyMembers.isEmpty ? "Add Family Member" : "View Family Members")
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
            .sheet(isPresented: $isEditing) {
                EditProfileView(profileController: profileController, isPresented: $isEditing)
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
    @State private var address: String = ""
    @State private var phoneNumber: String = ""
    @State private var emergencyContactName: String = ""
    @State private var emergencyContactNumber: String = ""
    @State private var emergencyRelationship: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    TextField("Name *", text: $name)
                        .onChange(of: name) { _, newValue in
                            let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                            if filtered != newValue {
                                name = filtered
                            }
                        }
                    
                    // Read-only fields
                    InfoRow(title: "Age", value: profileController.patient.age)
                    InfoRow(title: "Gender", value: profileController.patient.gender)
                    InfoRow(title: "Blood Group", value: profileController.patient.bloodGroup)
                }
                
                Section(header: Text("Contact Details")) {
                    TextField("Address *", text: $address)
                    
                    TextField("Phone Number *", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: phoneNumber) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                phoneNumber = filtered
                            }
                            if filtered.count > 10 {
                                phoneNumber = String(filtered.prefix(10))
                            }
                        }
                }
                
                Section(header: Text("Emergency Contact")) {
                    TextField("Contact Name *", text: $emergencyContactName)
                    TextField("Contact Number *", text: $emergencyContactNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: emergencyContactNumber) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                emergencyContactNumber = filtered
                            }
                            if filtered.count > 10 {
                                emergencyContactNumber = String(filtered.prefix(10))
                            }
                        }
                    TextField("Relationship *", text: $emergencyRelationship)
                }
                
                Section {
                    Text("* Required fields")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Load existing profile data
                name = profileController.patient.name
                address = profileController.patient.address
                phoneNumber = profileController.patient.phoneNumber
                emergencyContactName = profileController.patient.emergencyContactName
                emergencyContactNumber = profileController.patient.emergencyContactNumber
                emergencyRelationship = profileController.patient.emergencyRelationship
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateForm() {
                            profileController.updateProfile(
                                name: name,
                                address: address,
                                phoneNumber: phoneNumber,
                                emergencyContactName: emergencyContactName,
                                emergencyContactNumber: emergencyContactNumber,
                                emergencyRelationship: emergencyRelationship
                            )
                            isPresented = false
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func validateForm() -> Bool {
        // Validate name (only alphabets and not empty)
        if name.isEmpty {
            errorMessage = "Please enter a name"
            showError = true
            return false
        }
        
        if !name.trimmingCharacters(in: .whitespaces).isEmpty && !name.trimmingCharacters(in: .whitespaces).contains(where: { $0.isLetter }) {
            errorMessage = "Name must contain at least one letter"
            showError = true
            return false
        }
        
        // Validate address
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter an address"
            showError = true
            return false
        }
        
        // Validate phone number (exactly 10 digits)
        if phoneNumber.isEmpty {
            errorMessage = "Please enter a phone number"
            showError = true
            return false
        }
        
        if phoneNumber.count != 10 {
            errorMessage = "Phone number must be exactly 10 digits"
            showError = true
            return false
        }
        
        // Validate emergency contact name
        if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter an emergency contact name"
            showError = true
            return false
        }
        
        // Validate emergency contact number
        if emergencyContactNumber.isEmpty {
            errorMessage = "Please enter an emergency contact number"
            showError = true
            return false
        }
        
        if emergencyContactNumber.count != 10 {
            errorMessage = "Emergency contact number must be exactly 10 digits"
            showError = true
            return false
        }
        
        // Validate relationship
        if emergencyRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter the relationship with emergency contact"
            showError = true
            return false
        }
        
        return true
    }
}



