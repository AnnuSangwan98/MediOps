//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import Foundation

struct PatientProfile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var age: String
    var gender: String
    var bloodGroup: String
    var address: String
    var phoneNumber: String
    var emergencyContactName: String
    var emergencyContactNumber: String
    var emergencyRelationship: String
    var familyMembers: [FamilyMember] = []
}

struct FamilyMember: Identifiable, Codable {
    var id = UUID()
    var name: String
    var age: String
    var gender: String
    var bloodGroup: String
    var address: String
    var phoneNumber: String
    var emergencyContactName: String
    var emergencyContactNumber: String
    var emergencyRelationship: String
}



