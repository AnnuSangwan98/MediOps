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
                    .disabled(!isFormValid)
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
        
        // Call the onUpdate closure with the updated lab admin
        onUpdate(updatedLabAdmin)
        dismiss()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
} 