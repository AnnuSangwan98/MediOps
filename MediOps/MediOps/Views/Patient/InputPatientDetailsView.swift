import SwiftUI

struct InputPatientDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var bloodGroup: String = ""
    @State private var gender: String = "Male"
    @State private var email: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToHome = false
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    Text("Patient Details")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                        .padding(.top, 50)
                    
                    // Form Content
                    VStack(spacing: 25) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your full name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Age field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your age", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Blood Group field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Blood Group")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Menu {
                                ForEach(bloodGroups, id: \.self) { group in
                                    Button(group) {
                                        bloodGroup = group
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(bloodGroup.isEmpty ? "Select Blood Group" : bloodGroup)
                                        .foregroundColor(bloodGroup.isEmpty ? .gray : .black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Gender field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(genders, id: \.self) { gender in
                                    Text(gender).tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email ID")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Submit Button
                        Button(action: handleSubmit) {
                            HStack {
                                Text("Complete Signup")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToHome) {
            PatientHomeView()
        }
    }
    
    private func handleSubmit() {
        // Validate all fields
        if name.isEmpty || age.isEmpty || bloodGroup.isEmpty || email.isEmpty {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        // TODO: Save patient details
        navigateToHome = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    NavigationStack {
        InputPatientDetailsView()
    }
} 
