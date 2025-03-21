//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import SwiftUI

struct FamilyMemberListView: View {
    @ObservedObject var profileController: PatientProfileController
    @Environment(\.dismiss) var dismiss
    @State private var showAddForm = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profileController.patient.familyMembers) { member in
                    NavigationLink(destination: FamilyMemberProfileView(profileController: profileController, member: member)) {
                        VStack(alignment: .leading) {
                            Text(member.name)
                                .font(.headline)
                            HStack {
                                Text("Age: \(member.age)")
                                Spacer()
                                Text("Relation: \(member.emergencyRelationship)")
                            }
                            .foregroundColor(.gray)
                        }
                        .padding(6)
                    }
                }
                .onDelete { indexSet in
                    profileController.deleteFamilyMember(at: indexSet)
                }
            }
            .navigationTitle("Family Members")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showAddForm = true
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                AddFamilyMemberView(profileController: profileController, isPresented: $showAddForm)
            }
        }
    }
}

struct FamilyMemberProfileView: View {
    @ObservedObject var profileController: PatientProfileController
    var member: FamilyMember
    @Environment(\.dismiss) var dismiss
    @State private var showEditForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.teal)
                    .padding(.top, 30)
                
                Text(member.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                HStack(spacing: 25) {
                    VStack {
                        Image(systemName: "calendar")
                        Text(member.age)
                    }
                    VStack {
                        Image(systemName: "person.fill")
                        Text(member.gender)
                    }
                    VStack {
                        Image(systemName: "drop.fill")
                        Text(member.bloodGroup)
                    }
                }
                .foregroundColor(.gray)
                
                VStack(spacing: 16) {
                    CardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personal Information")
                                .font(.headline)
                                .padding(.bottom, 5)
                            InfoRow(title: "Address", value: member.address)
                            InfoRow(title: "Phone Number", value: member.phoneNumber)
                            InfoRow(title: "Blood Group", value: member.bloodGroup)
                        }
                    }
                    
                    CardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Emergency Contact")
                                .font(.headline)
                                .padding(.bottom, 5)
                            InfoRow(title: "Name", value: member.emergencyContactName)
                            InfoRow(title: "Contact No.", value: member.emergencyContactNumber)
                            InfoRow(title: "Relationship", value: member.emergencyRelationship)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Member Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditForm = true
                }
            }
        }
        .sheet(isPresented: $showEditForm) {
            EditFamilyMemberView(profileController: profileController, member: member, isPresented: $showEditForm)
        }
    }
}

struct EditFamilyMemberView: View {
    @ObservedObject var profileController: PatientProfileController
    let member: FamilyMember
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
                    InfoRow(title: "Age", value: member.age)
                    InfoRow(title: "Gender", value: member.gender)
                    InfoRow(title: "Blood Group", value: member.bloodGroup)
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
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Load existing member data
                name = member.name
                address = member.address
                phoneNumber = member.phoneNumber
                emergencyContactName = member.emergencyContactName
                emergencyContactNumber = member.emergencyContactNumber
                emergencyRelationship = member.emergencyRelationship
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
                            profileController.updateFamilyMember(
                                id: member.id,
                                name: name,
                                age: member.age,
                                gender: member.gender,
                                bloodGroup: member.bloodGroup,
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


