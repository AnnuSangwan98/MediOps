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
                    NavigationLink(destination: FamilyMemberProfileView(member: member)) {
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


