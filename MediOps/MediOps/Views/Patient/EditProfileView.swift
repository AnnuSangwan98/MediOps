import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = EditProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var patientController: PatientProfileController

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                if !viewModel.nameIsValid && !viewModel.name.isEmpty {
                    Text("Name must be at least 2 characters long")
                        .foregroundColor(.red)
                }
                
                TextField("Age", text: Binding(
                    get: { String(viewModel.age) },
                    set: { viewModel.age = Int($0) ?? 0 }
                ))
                .keyboardType(.numberPad)
                if !viewModel.ageIsValid {
                    Text("Age must be between 1 and 120")
                        .foregroundColor(.red)
                }
                
                Picker("Gender", selection: $viewModel.gender) {
                    Text("Select Gender").tag("")
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                if !viewModel.genderIsValid && !viewModel.gender.isEmpty {
                    Text("Please select a gender")
                        .foregroundColor(.red)
                }
                
                Picker("Blood Group", selection: $viewModel.bloodGroup) {
                    Text("Select Blood Group").tag("")
                    Text("A+").tag("A+")
                    Text("A-").tag("A-")
                    Text("B+").tag("B+")
                    Text("B-").tag("B-")
                    Text("AB+").tag("AB+")
                    Text("AB-").tag("AB-")
                    Text("O+").tag("O+")
                    Text("O-").tag("O-")
                }
                if !viewModel.bloodGroupIsValid && !viewModel.bloodGroup.isEmpty {
                    Text("Please select a valid blood group")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Contact Information")) {
                TextField("Phone Number", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
                if !viewModel.phoneNumberIsValid && !viewModel.phoneNumber.isEmpty {
                    Text("Please enter a valid 10-digit phone number")
                        .foregroundColor(.red)
                }
                
                TextField("Address", text: $viewModel.address)
                if !viewModel.addressIsValid && !viewModel.address.isEmpty {
                    Text("Address cannot be empty")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Emergency Contact")) {
                TextField("Emergency Contact Name", text: $viewModel.emergencyContactName)
                if !viewModel.emergencyContactNameIsValid && !viewModel.emergencyContactName.isEmpty {
                    Text("Emergency contact name must be at least 2 characters")
                        .foregroundColor(.red)
                }
                
                TextField("Emergency Contact Number", text: $viewModel.emergencyContactNumber)
                    .keyboardType(.phonePad)
                if !viewModel.emergencyContactNumberIsValid && !viewModel.emergencyContactNumber.isEmpty {
                    Text("Please enter a valid 10-digit emergency contact number")
                        .foregroundColor(.red)
                }
                
                TextField("Relationship", text: $viewModel.emergencyRelationship)
                if !viewModel.emergencyRelationshipIsValid && !viewModel.emergencyRelationship.isEmpty {
                    Text("Relationship must be specified")
                        .foregroundColor(.red)
                }
            }
            
            Button(action: {
                if viewModel.isFormValid {
                    viewModel.updateProfile()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Update Profile")
                }
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .frame(maxWidth: .infinity)
        }
        .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") { 
                dismiss()
                if let userId = UserDefaults.standard.string(forKey: "userId") ?? UserDefaults.standard.string(forKey: "current_user_id") {
                    Task {
                        await patientController.loadProfile(userId: userId)
                    }
                }
            }
        } message: {
            Text("Profile updated successfully!")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if let userId = UserDefaults.standard.string(forKey: "userId") ?? UserDefaults.standard.string(forKey: "current_user_id") {
                        Task {
                            await patientController.loadProfile(userId: userId)
                        }
                    }
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}

class EditProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var bloodGroup: String = ""
    @Published var phoneNumber: String = ""
    @Published var address: String = ""
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactNumber: String = ""
    @Published var emergencyRelationship: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showingSuccessAlert: Bool = false

    private let supabase: SupabaseController
    private let patientController: PatientProfileController

    // Validation computed properties
    var nameIsValid: Bool {
        name.count >= 2
    }
    
    var ageIsValid: Bool {
        age > 0 && age <= 120
    }
    
    var genderIsValid: Bool {
        !gender.isEmpty
    }
    
    var bloodGroupIsValid: Bool {
        ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"].contains(bloodGroup)
    }
    
    var phoneNumberIsValid: Bool {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    var addressIsValid: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var emergencyContactNameIsValid: Bool {
        emergencyContactName.count >= 2
    }
    
    var emergencyContactNumberIsValid: Bool {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: emergencyContactNumber)
    }
    
    var emergencyRelationshipIsValid: Bool {
        !emergencyRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isFormValid: Bool {
        nameIsValid &&
        ageIsValid &&
        genderIsValid &&
        bloodGroupIsValid &&
        phoneNumberIsValid &&
        addressIsValid &&
        emergencyContactNameIsValid &&
        emergencyContactNumberIsValid &&
        emergencyRelationshipIsValid
    }

    init(supabase: SupabaseController = SupabaseController.shared, patientController: PatientProfileController = PatientProfileController()) {
        self.supabase = supabase
        self.patientController = patientController
    }

    func updateProfile() {
        // Validate all fields before proceeding
        guard isFormValid else {
            error = "Please fix all validation errors before submitting"
            return
        }
        
        print("📱 EDIT PROFILE: Starting profile update")
        isLoading = true
        error = nil
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                          UserDefaults.standard.string(forKey: "current_user_id") else {
            print("📱 EDIT PROFILE ERROR: No user ID found in UserDefaults")
            error = "No user ID found. Please sign in again."
            isLoading = false
            return
        }
        
        // Create patient data dictionary with all fields
        var patientData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "age": age,
            "gender": gender,
            "blood_group": bloodGroup,
            "phone_number": phoneNumber,
            "address": address.trimmingCharacters(in: .whitespacesAndNewlines),
            "emergency_contact_name": emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines),
            "emergency_contact_number": emergencyContactNumber,
            "emergency_relationship": emergencyRelationship.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        Task {
            do {
                print("📱 EDIT PROFILE: Fetching current patient record")
                let patients = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patient = patients.first, let patientId = patient["id"] as? String else {
                    await MainActor.run {
                        error = "Could not find your patient record."
                        isLoading = false
                    }
                    return
                }
                
                if patient["patient_id"] == nil {
                    patientData["patient_id"] = patientId
                }
                
                let result = try await supabase.update(
                    table: "patients",
                    id: patientId,
                    data: patientData
                )
                
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                    Task {
                        await patientController.loadProfile(userId: userId)
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to update profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
