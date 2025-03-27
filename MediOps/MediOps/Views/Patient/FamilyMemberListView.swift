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
    @State private var showAddMember = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profileController.patient.familyMembers) { member in
                    NavigationLink(destination: FamilyMemberDetailView(member: member)) {
                        FamilyMemberRow(member: member)
                    }
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
                Text("Relation: \(member.emergencyRelationship)")
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
                
                // Personal Information
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personal Information")
                            .font(.headline)
                            .padding(.bottom, 5)
                        InfoRow(title: "Name", value: member.name)
                        InfoRow(title: "Age", value: member.age)
                        InfoRow(title: "Gender", value: member.gender)
                        InfoRow(title: "Blood Group", value: member.bloodGroup)
                        InfoRow(title: "Phone Number", value: member.phoneNumber)
                        InfoRow(title: "Address", value: member.address)
                    }
                }
                
                // Emergency Contact
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}


