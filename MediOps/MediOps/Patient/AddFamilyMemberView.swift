import SwiftUI

struct AddFamilyMemberView: View {
    @ObservedObject var profileController: PatientProfileController
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender = "Male"
    @State private var bloodGroup = "A+"
    @State private var address = ""
    @State private var phoneNumber = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactNumber = ""
    @State private var emergencyRelationship = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    let genders = ["Male", "Female", "Other"]
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    
    private var calculatedAge: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return "\(ageComponents.year ?? 0)"
    }
    
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
                    
                    DatePicker(
                        "Date of Birth *",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    
                    Text("Age: \(calculatedAge) years")
                        .foregroundColor(.gray)
                    
                    Picker("Gender *", selection: $gender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    
                    Picker("Blood Group *", selection: $bloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
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
                        if validateForm() {
                            profileController.addFamilyMember(
                                name: name,
                                age: calculatedAge,
                                gender: gender,
                                bloodGroup: bloodGroup,
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
        
        // Validate age (must be at least 0)
        if Int(calculatedAge) ?? 0 < 0 {
            errorMessage = "Invalid birth date"
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
