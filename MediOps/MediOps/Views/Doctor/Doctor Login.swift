import SwiftUI

struct DoctorLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var doctorId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showChangePasswordSheet: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // Computed properties for validation
    private var isValidLoginInput: Bool {
        return !doctorId.isEmpty && !password.isEmpty &&
               isValidAdminId(doctorId) && isValidPassword(password)
    }
    
    private var isValidPasswordChange: Bool {
        return !newPassword.isEmpty && !confirmPassword.isEmpty &&
               newPassword == confirmPassword && isValidPassword(newPassword)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and Header
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                        
                        Image(systemName: "stethoscope")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Doctor Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doctor ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter doctor ID (e.g. DOC001)", text: $doctorId)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: doctorId) { _, newValue in
                                // Automatically format to uppercase for "HOS" part
                                if newValue.count >= 3 {
                                    let hosPrefix = newValue.prefix(3).uppercased()
                                    let numericPart = newValue.dropFirst(3)
                                    doctorId = hosPrefix + numericPart
                                } else if newValue.count > 0 {
                                    doctorId = newValue.uppercased()
                                }
                            }
                    }
                    
                    // Password field with requirements hint and toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
                        Text("Must be at least 8 characters with exactly one uppercase letter, one lowercase letter, one number, and one special character (@$!%*?&)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            Text("Login")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [
                                isValidLoginInput ? Color.teal : Color.gray.opacity(0.5),
                                isValidLoginInput ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .shadow(color: isValidLoginInput ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .disabled(!isValidLoginInput)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            NavigationLink(destination: DoctorHomeView(), isActive: $isLoggedIn) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordSheets(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isValidInput: isValidPasswordChange,
                onSubmit: handlePasswordChange
            )
        }
    }
    
    private func handleLogin() {
        guard let url = URL(string: "http://localhost:8082/validate-doctor") else {
            errorMessage = "Invalid server configuration"
            showError = true
            return
        }
        
        let credentials: [String: Any] = [
            "doctorId": doctorId, 
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                        self.showError = true
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.errorMessage = "Invalid server response"
                        self.showError = true
                        return
                    }
                    
                    guard let data = data else {
                        self.errorMessage = "No data received"
                        self.showError = true
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let status = json["status"] as? String,
                           let valid = json["valid"] as? Bool {
                            
                            if status == "success" {
                                if valid {
                                    self.isLoggedIn = true
                                } else {
                                    self.errorMessage = "Invalid credentials"
                                    self.showError = true
                                }
                            } else {
                                self.errorMessage = "Server error: Invalid response format"
                                self.showError = true
                            }
                        } else {
                            self.errorMessage = "Invalid response format"
                            self.showError = true
                        }
                    } catch {
                        self.errorMessage = "Failed to parse server response"
                        self.showError = true
                    }
                }
            }.resume()
        } catch {
            self.errorMessage = "Failed to prepare request"
            self.showError = true
        }
    }
    
    private func handlePasswordChange() {
        showChangePasswordSheet = false
        isLoggedIn = true
    }
    
    private func isValidAdminId(_ id: String) -> Bool {
        let adminIdRegex = #"^DOC\d+$"#
        return NSPredicate(format: "SELF MATCHES %@", adminIdRegex).evaluate(with: id)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else { return false }
        
        // Check for at least one number
        let numberRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) else { return false }
        
        // Check for at least one special character
        let specialCharRegex = ".*[@#$%^&*()\\-_=+\\[\\]{}|;:'\",.<>/?]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) else { return false }
        
        return true
    }
}

// Change Password Sheet
struct ChangePasswordSheets: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    var isValidInput: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Change Password")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.teal)
                .padding(.top, 20)
            
            // Form fields
            VStack(spacing: 20) {
                // New Password field with toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ZStack {
                        if isNewPasswordVisible {
                            TextField("Enter new password", text: $newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Enter new password", text: $newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                isNewPasswordVisible.toggle()
                            }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    Text("Must contain at least 8 characters, one uppercase letter, one number, and one special character")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ZStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Submit Button
            Button(action: onSubmit) {
                Text("Submit")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [
                            isValidInput ? Color.teal : Color.gray.opacity(0.5),
                            isValidInput ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: isValidInput ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .disabled(!isValidInput)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(.top, 20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}


#Preview {
    NavigationStack {
        DoctorLoginView()
    }
}
