//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import Foundation

class PatientProfileController: ObservableObject {
    @Published var patient: PatientProfile {
        didSet {
            // Save to UserDefaults whenever the patient data changes
            if let encoded = try? JSONEncoder().encode(patient) {
                UserDefaults.standard.set(encoded, forKey: "patientProfile")
            }
        }
    }
    
    init() {
        // Try to load from UserDefaults
        if let savedPatient = UserDefaults.standard.data(forKey: "patientProfile"),
           let decodedPatient = try? JSONDecoder().decode(PatientProfile.self, from: savedPatient) {
            self.patient = decodedPatient
        } else {
            // Default values if no saved data exists
            self.patient = PatientProfile(
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
        }
    }
    
    func updateProfile(
        name: String,
        address: String,
        phoneNumber: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) {
        patient.name = name
        patient.address = address
        patient.phoneNumber = phoneNumber
        patient.emergencyContactName = emergencyContactName
        patient.emergencyContactNumber = emergencyContactNumber
        patient.emergencyRelationship = emergencyRelationship
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
    
    func updateFamilyMember(
        id: UUID,
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
        if let index = patient.familyMembers.firstIndex(where: { $0.id == id }) {
            let updatedMember = FamilyMember(
                id: id,
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
            patient.familyMembers[index] = updatedMember
        }
    }
    
    func deleteFamilyMember(at indexSet: IndexSet) {
        patient.familyMembers.remove(atOffsets: indexSet)
    }
}

