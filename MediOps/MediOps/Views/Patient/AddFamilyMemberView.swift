import SwiftUI

struct AddFamilyMemberView: View {
    @ObservedObject var profileController: PatientProfileController
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var age = ""
    @State private var gender = ""
    @State private var bloodGroup = ""
    @State private var address = ""
    @State private var phoneNumber = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactNumber = ""
    @State private var emergencyRelationship = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                    TextField("Gender", text: $gender)
                    TextField("Blood Group", text: $bloodGroup)
                }
                
                Section(header: Text("Contact Details")) {
                    TextField("Address", text: $address)
                    TextField("Phone Number", text: $phoneNumber)
                }
                
                Section(header: Text("Emergency Contact")) {
                    TextField("Contact Name", text: $emergencyContactName)
                    TextField("Contact Number", text: $emergencyContactNumber)
                    TextField("Relationship", text: $emergencyRelationship)
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
                        profileController.patient.familyMembers.append(newMember)
                        isPresented = false
                    }
                }
            }
        }
    }
}
