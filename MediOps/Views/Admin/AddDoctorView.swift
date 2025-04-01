import SwiftUI

struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var doctorId: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var specialization: String = ""
    @State private var license: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var onComplete: (ActivityStatus) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Doctor ID Field (Added manually)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doctor ID")
                                .foregroundColor(.gray)
                            TextField("Enter doctor ID (e.g., DOC123)", text: $doctorId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        .padding(.horizontal)
                        
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .foregroundColor(.gray)
                            TextField("Enter first name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .foregroundColor(.gray)
                            TextField("Enter last name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .foregroundColor(.gray)
                            TextField("Enter email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.horizontal)
                        
                        // Phone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone")
                                .foregroundColor(.gray)
                            TextField("Enter phone number", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                        .padding(.horizontal)
                        
                        // Specialization
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specialization")
                                .foregroundColor(.gray)
                            TextField("Enter specialization", text: $specialization)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // License
                        VStack(alignment: .leading, spacing: 8) {
                            Text("License Number")
                                .foregroundColor(.gray)
                            TextField("Enter license number", text: $license)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        // Add Button
                        Button(action: addDoctor) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Add Doctor")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && !isLoading ? Color.teal : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.teal)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !doctorId.isEmpty && 
        !firstName.isEmpty && 
        !lastName.isEmpty && 
        !email.isEmpty && 
        !phone.isEmpty && 
        !specialization.isEmpty && 
        !license.isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func addDoctor() {
        guard isFormValid else { return }
        
        isLoading = true
        
        // Create doctor object
        let doctor = UIDoctor(
            id: doctorId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            specialization: specialization,
            license: license
        )
        
        // Here you would typically call your API service to add the doctor
        // For now, we'll simulate a successful addition
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Create activity status with doctor details
            let status = ActivityStatus(success: true, message: "Doctor added successfully", doctorDetails: doctor)
            
            // Call completion handler
            onComplete(status)
            dismiss()
        }
    }
}

// This struct would be defined elsewhere in your app
struct ActivityStatus {
    let success: Bool
    let message: String
    let doctorDetails: UIDoctor?
    
    init(success: Bool, message: String, doctorDetails: UIDoctor? = nil) {
        self.success = success
        self.message = message
        self.doctorDetails = doctorDetails
    }
}

// This struct would be defined elsewhere in your app
struct UIDoctor: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let specialization: String
    let license: String
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

#Preview {
    AddDoctorView { _ in }
}