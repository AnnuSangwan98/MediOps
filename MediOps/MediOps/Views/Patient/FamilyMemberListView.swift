//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import SwiftUI

// Temporarily define these components until proper importing is resolved
fileprivate struct CardView<Content: View>: View {
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

fileprivate struct InfoRow: View {
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

struct FamilyMemberListView: View {
    @ObservedObject var profileController: PatientProfileController
    @Environment(\.dismiss) var dismiss
    @State private var showAddMember = false
    
    var body: some View {
        NavigationStack {
            List {
                if let patient = profileController.patient {
                    ForEach(profileController.familyMembers) { member in
                        NavigationLink(destination: FamilyMemberDetailView(member: member)) {
                            FamilyMemberRow(member: member)
                        }
                    }
                } else {
                    Text("No patient information available")
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddMember = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddFamilyMemberView(profileController: profileController, isPresented: $showAddMember)
            }
        }
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(member.name)
                .font(.headline)
            HStack {
                Text("Age: \(member.age)")
                Spacer()
                Text("Relation: \(member.relationship)")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct FamilyMemberDetailView: View {
    let member: FamilyMember
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.teal)
                    .padding(.top, 30)
                
                Text(member.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                // Quick Info
                HStack(spacing: 25) {
                    VStack {
                        Image(systemName: "calendar")
                        Text("\(member.age)")
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
                
                // Personal Information
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personal Information")
                            .font(.headline)
                            .padding(.bottom, 5)
                        InfoRow(title: "Name", value: member.name)
                        InfoRow(title: "Age", value: "\(member.age)")
                        InfoRow(title: "Gender", value: member.gender)
                        InfoRow(title: "Blood Group", value: member.bloodGroup)
                        InfoRow(title: "Phone Number", value: member.phone)
                        InfoRow(title: "Relationship", value: member.relationship)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Member Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FamilyMemberProfileView: View {
    var member: FamilyMember
    @Environment(\.dismiss) var dismiss
    
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
                        Text("\(member.age)")
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
                            InfoRow(title: "Phone Number", value: member.phone)
                            InfoRow(title: "Blood Group", value: member.bloodGroup)
                            InfoRow(title: "Relationship", value: member.relationship)
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

struct AddFamilyMemberView: View {
    @ObservedObject var profileController: PatientProfileController
    @Binding var isPresented: Bool
    @State private var member = FamilyMember.empty()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let genders = ["Male", "Female", "Other"]
    private let relationships = ["Spouse", "Parent", "Child", "Sibling", "Other"]
    private let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $member.name)
                    
                    Stepper("Age: \(member.age)", value: $member.age, in: 1...120)
                    
                    Picker("Gender", selection: $member.gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    
                    Picker("Relationship", selection: $member.relationship) {
                        ForEach(relationships, id: \.self) { relationship in
                            Text(relationship).tag(relationship)
                        }
                    }
                    
                    Picker("Blood Group", selection: $member.bloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Phone Number", text: $member.phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMember()
                    }
                    .disabled(isLoading || member.name.isEmpty || member.phone.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveMember() {
        isLoading = true
        
        Task {
            let success = await profileController.addFamilyMember(member)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    isPresented = false
                } else {
                    errorMessage = "Failed to add family member"
                    showError = true
                }
            }
        }
    }
}


