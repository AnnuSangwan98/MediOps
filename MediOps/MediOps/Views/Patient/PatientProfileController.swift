//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import Foundation

class PatientProfileController: ObservableObject {
    @Published var patient = PatientProfile(
        name: "Akash Deo",
        age: "60 Years",
        gender: "Male",
        bloodGroup: "AB+",
        address: "Bangalore",
        phoneNumber: "9999999999",
        emergencyContactName: "Astha",
        emergencyContactNumber: "9999999999",
        emergencyRelationship: "Daughter"
    )
    
    func updateProfile(name: String, phoneNumber: String, address: String) {
        patient.name = name
        patient.phoneNumber = phoneNumber
        patient.address = address
    }
    
    func addFamilyMember(
        name: String,
        age: String,
        gender: String,
        bloodGroup: String,
        address: String,
        phoneNumber: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) {
        let newMember = FamilyMember(
            name: name,
            age: age,
            gender: gender,
            bloodGroup: bloodGroup,
            address: address,
            phoneNumber: phoneNumber,
            emergencyContactName: emergencyContactName,
            emergencyContactNumber: emergencyContactNumber,
            emergencyRelationship: emergencyRelationship
        )
        patient.familyMembers.append(newMember)
    }


}

