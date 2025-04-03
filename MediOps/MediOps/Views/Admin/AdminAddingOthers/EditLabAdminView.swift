import SwiftUI

struct EditLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var gender: UILabAdmin.Gender
    @State private var dateOfBirth: Date
    @State private var experience: Int
    @State private var selectedQualifications: Set<String>
    @State private var license: String
    @State private var address: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isFetchingData = true // Add state for initial data loading
    
    // Add reference to AdminController
    private let adminController = AdminController.shared
    
    // Add allowed qualifications
    private let availableQualifications = ["MLT", "DMLT", "M.Sc"]
    
    let labAdmin: UILabAdmin
    let onUpdate: (UILabAdmin) -> Void
    
    init(labAdmin: UILabAdmin, onUpdate: @escaping (UILabAdmin) -> Void) {
        self.labAdmin = labAdmin
        self.onUpdate = onUpdate
        
        // Initialize state variables with lab admin's current data (will be updated from Supabase)
        _fullName = State(initialValue: labAdmin.fullName)
        _email = State(initialValue: labAdmin.email)
        _phoneNumber = State(initialValue: labAdmin.phone.replacingOccurrences(of: "+91", with: ""))
        _gender = State(initialValue: labAdmin.gender)
        _dateOfBirth = State(initialValue: labAdmin.dateOfBirth)
        _experience = State(initialValue: labAdmin.experience)
        
        // Initialize selectedQualifications from qualification string
        let quals = labAdmin.qualification.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        _selectedQualifications = State(initialValue: Set(quals))
        
        // Initialize license from license field, fallback to originalId
        _license = State(initialValue: labAdmin.license ?? labAdmin.originalId ?? "")
        
        _address = State(initialValue: labAdmin.address)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !selectedQualifications.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Personal Information")) {
                        TextField("Full Name", text: $fullName)
                            .onChange(of: fullName) { _, newValue in
                                // Only allow letters and spaces
                                fullName = newValue.filter { $0.isLetter || $0.isWhitespace }
                            }
                        if !fullName.isEmpty && !isValidName(fullName) {
                            Text("Name should only contain letters and spaces")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Picker("Gender", selection: $gender) {
                            ForEach(UILabAdmin.Gender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        
//                        DatePicker("Date of Birth",
//                                  selection: $dateOfBirth,
//                                  in: ...Date(),
//                                  displayedComponents: .date)
                    }
                    
                    Section(header: Text("Professional Information")) {
                        // Qualifications picker
                        VStack(alignment: .leading) {
                            Text("Qualifications")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.bottom, 5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(availableQualifications, id: \.self) { qualification in
                                        QualificationToggle(
                                            title: qualification,
                                            isSelected: selectedQualifications.contains(qualification),
                                            action: {
                                                if selectedQualifications.contains(qualification) {
                                                    selectedQualifications.remove(qualification)
                                                } else {
                                                    selectedQualifications.insert(qualification)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            
                            if selectedQualifications.isEmpty {
                                Text("Select at least one qualification")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 5)
                        
                        TextField("License (XX12345)", text: $license)
                            .onChange(of: license) { _, newValue in
                                // Format and validate license input
                                var formatted = newValue.uppercased()
                                
                                // If length is more than 7, truncate it
                                if formatted.count > 7 {
                                    formatted = String(formatted.prefix(7))
                                }
                                
                                // For the first two characters, only allow letters
                                if formatted.count <= 2 {
                                    formatted = formatted.filter { $0.isLetter }
                                } else {
                                    // Split into letters and numbers
                                    let prefix = String(formatted.prefix(2)).filter { $0.isLetter }
                                    let remainingInput = String(formatted.dropFirst(2))
                                    let numbers = remainingInput.filter { $0.isNumber }
                                    
                                    // Combine with proper formatting
                                    formatted = prefix + (numbers.count > 5 ? String(numbers.prefix(5)) : numbers)
                                }
                                
                                license = formatted
                            }
                        
                        // Display experience as text instead of stepper
                        HStack {
                            Text("Experience:")
                                .foregroundColor(.primary)
                            Text("\(experience) years")
                                .foregroundColor(.secondary)
                        }
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
                                    // Keep only digits and limit to 10
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
                        .disabled(!isFormValid || isLoading || isFetchingData)
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
                .disabled(isFetchingData) // Disable form while fetching data
                
                // Loading overlay for initial data fetch
                if isFetchingData {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Loading lab admin data...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .task {
                await fetchLabAdminData()
            }
        }
    }
    
    // Fetch lab admin data directly from Supabase
    private func fetchLabAdminData() async {
        guard let originalId = labAdmin.originalId, !originalId.isEmpty else {
            // If no original ID, just use the data passed in the initializer
            isFetchingData = false
            return
        }
        
        do {
            // Fetch the lab admin data directly from Supabase
            let fetchedLabAdmin = try await adminController.getLabAdmin(id: originalId)
            
            // Update all state variables with the fetched data
            await MainActor.run {
                fullName = fetchedLabAdmin.name
                email = fetchedLabAdmin.email
                phoneNumber = fetchedLabAdmin.contactNumber
                
                // Check gender - default to current gender if not specified
                // (gender isn't stored in Supabase but we need it for the UI)
                
                // Update date of birth if available
                if let dob = fetchedLabAdmin.dateOfBirth {
                    dateOfBirth = dob
                }
                
                // Update experience
                experience = fetchedLabAdmin.experience
                
                // Update qualifications
                if let qualifications = fetchedLabAdmin.qualification, !qualifications.isEmpty {
                    selectedQualifications = Set(qualifications.filter { availableQualifications.contains($0) })
                    
                    // If none of the fetched qualifications are in our available list, default to first
                    if selectedQualifications.isEmpty && !availableQualifications.isEmpty {
                        selectedQualifications.insert(availableQualifications[0])
                    }
                }
                
                // Update license
                if let licenseNo = fetchedLabAdmin.licenseNo {
                    license = licenseNo
                }
                
                // Update address
                address = fetchedLabAdmin.address
                
                // Mark data as loaded
                isFetchingData = false
            }
        } catch {
            await MainActor.run {
                print("Failed to fetch lab admin data: \(error.localizedDescription)")
                // Even on error, mark as not fetching and use the initial data
                isFetchingData = false
                
                alertMessage = "Could not fetch the latest data: \(error.localizedDescription)"
                showAlert = true
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
            originalId: labAdmin.originalId,
            fullName: fullName,
            email: email,
            phone: "+91" + phoneNumber,
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: selectedQualifications.joined(separator: ", "),
            license: license,
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
                    department: "Pathology & Laboratory", // Fixed value
                    address: address,
                    qualification: Array(selectedQualifications), // Pass as array of strings
                    licenseNo: license,
                    dateOfBirth: dateOfBirth, // Add dateOfBirth
                    experience: experience, // Add experience
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
    
    // Add function to validate name
    private func isValidName(_ name: String) -> Bool {
        let nameRegex = "^[A-Za-z\\s]{2,}$"
        return name.range(of: nameRegex, options: .regularExpression) != nil
    }
    
    // Add helper function to validate license
    private func isValidLicense(_ license: String) -> Bool {
        // Check if license is exactly 7 characters
        guard license.count == 7 else { return false }
        
        // Check first two characters are letters and last five are numbers
        let firstTwo = license.prefix(2)
        let lastFive = license.suffix(5)
        
        return firstTwo.allSatisfy { $0.isLetter } && lastFive.allSatisfy { $0.isNumber }
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
            qualification: "MLT",
            address: "123 Main St"
        )
    ) { updatedLabAdmin in
        print("Lab admin updated: \(updatedLabAdmin.fullName)")
    }
} 
