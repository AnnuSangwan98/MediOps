import SwiftUI

struct AddHospitalView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Hospital info
    @State private var hospitalName = ""
    @State private var adminName = ""
    @State private var licenseNumber = ""
    
    // Address info
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    
    // Contact info
    @State private var phone = ""
    @State private var email = ""
    
    // Status indicators
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var credentialsSent = false
    
    var onSave: (UIActivity) -> Void
    
    // Validation
    private var isFormValid: Bool {
        !hospitalName.isEmpty &&
        !adminName.isEmpty &&
        isValidLicense(licenseNumber) &&
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        isValidZipCode(zipCode) &&
        isValidPhone(phone) &&
        isValidEmail(email)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Hospital Information")) {
                    TextField("Hospital Name", text: $hospitalName)
                    
                    TextField("Admin Name", text: $adminName)
                    
                    TextField("License Number (XX12345)", text: $licenseNumber)
                        .onChange(of: licenseNumber) { _, newValue in
                            licenseNumber = newValue.uppercased()
                        }
                }
                
                Section(header: Text("Address")) {
                    TextField("Street", text: $street)
                    
                    TextField("City", text: $city)
                    
                    TextField("State", text: $state)
                    
                    TextField("Zip Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .onChange(of: zipCode) { _, newValue in
                            if newValue.count > 10 {
                                zipCode = String(newValue.prefix(10))
                            }
                        }
                }
                
                Section(header: Text("Contact Information")) {
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                            .onChange(of: phone) { _, newValue in
                                // Keep only digits and limit to 10
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phone = String(filtered.prefix(10))
                                } else {
                                    phone = filtered
                                }
                            }
                    }
                    
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Hospital")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHospital()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white)
                                    )
                                Text(credentialsSent ? "Sending admin credentials..." : "Saving hospital information...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)
                            }
                        )
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func saveHospital() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                // Add hospital to database
                let hospital = try await AdminController.shared.createHospital(
                    name: hospitalName,
                    adminName: adminName,
                    licenseNumber: licenseNumber,
                    street: street,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    phone: "+91\(phone)",
                    email: email
                )
                
                // Create an activity for the hospital addition
                let uiHospital = UIHospital(
                    name: hospital.name,
                    adminName: hospital.adminName,
                    licenseNumber: hospital.licenseNumber,
                    street: hospital.street,
                    city: hospital.city,
                    state: hospital.state,
                    zipCode: hospital.zipCode,
                    phone: hospital.phone,
                    email: hospital.email
                )
                
                // Define a hospitalAdded activity type 
                let activity = UIActivity(
                    type: .hospitalAdded,
                    title: "New Hospital: \(hospitalName)",
                    timestamp: Date(),
                    status: .pending,
                    doctorDetails: nil,
                    labAdminDetails: nil,
                    hospitalDetails: uiHospital
                )
                
                // Set flag to indicate credentials are being sent
                await MainActor.run {
                    credentialsSent = true
                }
                
                // Send hospital admin credentials
                do {
                    let baseUrl = EmailService.shared.baseServerUrl
                    let url = URL(string: "\(baseUrl)/send-credentials")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let details: [String: Any] = [
                        "fullName": adminName,
                        "hospitalName": hospitalName,
                        "hospitalId": hospital.id,
                        "licenseNumber": licenseNumber,
                        "street": street,
                        "city": city,
                        "state": state,
                        "zipCode": zipCode,
                        "phone": "+91\(phone)"
                    ]
                    
                    let payload: [String: Any] = [
                        "to": email,
                        "accountType": "hospital",
                        "details": details
                    ]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: payload)
                    request.httpBody = jsonData
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    // Check for successful response
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        print("Credentials sent successfully to \(email)")
                    } else {
                        print("Failed to send credentials email: \(response)")
                    }
                } catch {
                    print("Error sending credentials: \(error.localizedDescription)")
                    // Note: we continue even if credential email fails
                }
                
                await MainActor.run {
                    isLoading = false
                    // Call the onSave callback with the new activity
                    self.onSave(activity)
                    
                    // Show success alert and dismiss
                    self.alertMessage = "Hospital added successfully and admin credentials sent"
                    self.showAlert = true
                    
                    // Dismiss the view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to save hospital: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    // Validation helper methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    private func isValidZipCode(_ zipCode: String) -> Bool {
        let zipRegex = #"^\d{5,6}$"#
        return NSPredicate(format: "SELF MATCHES %@", zipRegex).evaluate(with: zipCode)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        return phone.count == 10 && phone.allSatisfy { $0.isNumber }
    }
}

#Preview {
    AddHospitalView { _ in }
} 