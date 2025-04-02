import SwiftUI

struct EditLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var gender: UILabAdmin.Gender
    @State private var dateOfBirth: Date
    @State private var experience: Int
    @State private var qualification: String
    @State private var address: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    // Add reference to AdminController
    private let adminController = AdminController.shared
    
    let labAdmin: UILabAdmin
    let onUpdate: (UILabAdmin) -> Void
    
    init(labAdmin: UILabAdmin, onUpdate: @escaping (UILabAdmin) -> Void) {
        self.labAdmin = labAdmin
        self.onUpdate = onUpdate
        
        // Initialize state variables with lab admin's current data
        _fullName = State(initialValue: labAdmin.fullName)
        _email = State(initialValue: labAdmin.email)
        _phoneNumber = State(initialValue: labAdmin.phone.replacingOccurrences(of: "+91", with: ""))
        _gender = State(initialValue: labAdmin.gender)
        _dateOfBirth = State(initialValue: labAdmin.dateOfBirth)
        _experience = State(initialValue: labAdmin.experience)
        _qualification = State(initialValue: labAdmin.qualification)
        _address = State(initialValue: labAdmin.address)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !qualification.isEmpty &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UILabAdmin.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              in: ...Date(),
                              displayedComponents: .date)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Edit Lab Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateLabAdminDetails()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25)
    }
    
    private func updateLabAdminDetails() {
        guard isFormValid else {
            alertMessage = "Please fill out all required fields"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create updated UILabAdmin for the UI
        let updatedLabAdmin = UILabAdmin(
            id: labAdmin.id,
            fullName: fullName,
            email: email,
            phone: "+91" + phoneNumber,
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            address: address
        )
        
        // Update in Supabase
        Task {
            do {
                // Get the labAdminId string from the UUID
                let labAdminId = getLabAdminId(from: labAdmin.id)
                print("UPDATE LAB ADMIN: Using ID: \(labAdminId)")
                
                // First, fetch the current lab admin from the database to get the hospitalId
                let existingLabAdmin = try await adminController.getLabAdmin(id: labAdminId)
                print("UPDATE LAB ADMIN: Got existing lab admin with hospital ID: \(existingLabAdmin.hospitalId)")
                
                // Create the database model preserving the original hospitalId
                let labAdminModel = LabAdmin(
                    id: labAdminId,
                    hospitalId: existingLabAdmin.hospitalId,
                    name: fullName,
                    email: email,
                    contactNumber: phoneNumber, // Store without +91 prefix
                    department: qualification, // Using qualification as department
                    address: address,
                    createdAt: existingLabAdmin.createdAt, // Preserve original creation date
                    updatedAt: Date() // Update the modified date
                )
                
                // Save to database
                try await adminController.updateLabAdmin(labAdminModel)
                print("UPDATE LAB ADMIN: Successfully updated lab admin in Supabase")
                
                // Update UI
                await MainActor.run {
                    // Call the onUpdate closure with the updated lab admin
                    onUpdate(updatedLabAdmin)
                    
                    // Show success message
                    alertMessage = "Lab admin updated successfully in database"
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("UPDATE LAB ADMIN ERROR: \(error.localizedDescription)")
                    alertMessage = "Failed to update lab admin: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    // Helper function to get the correct labAdminId string
    private func getLabAdminId(from uuid: UUID) -> String {
        // First check if we have an original ID from Supabase
        if let originalId = labAdmin.originalId, !originalId.isEmpty {
            print("Using original Supabase ID: \(originalId)")
            return originalId
        }
        
        // Fallback to UUID string conversion
        let idString = String(describing: uuid)
        
        // If it's already a LAB formatted ID, return it
        if idString.hasPrefix("LAB") {
            return idString
        }
        
        // If all fails, log a warning and use UUID string
        print("WARNING: Using UUID as lab admin ID: \(idString). This may cause database issues.")
        return idString
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

#Preview {
    EditLabAdminView(
        labAdmin: UILabAdmin(
            id: UUID(),
            fullName: "John Doe",
            email: "john@example.com",
            phone: "+911234567890",
            gender: .male,
            dateOfBirth: Date(),
            experience: 5,
            qualification: "MBBS",
            address: "123 Main St"
        )
    ) { updatedLabAdmin in
        print("Lab admin updated: \(updatedLabAdmin.fullName)")
    }
} 