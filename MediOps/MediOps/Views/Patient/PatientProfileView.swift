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
    @State private var phone: String = ""
    @State private var address: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Phone Number")) {
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Address")) {
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                name = profileController.patient.name
                phone = profileController.patient.phoneNumber
                address = profileController.patient.address
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profileController.updateProfile(name: name, phoneNumber: phone, address: address)
                        isPresented = false
                    }
                }
            }
        }
    }
}



