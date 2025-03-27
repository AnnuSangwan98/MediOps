import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var adminId: String = ""
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
        return !adminId.isEmpty && !password.isEmpty &&
               isValidAdminId(adminId) && isValidPassword(password)
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
                    Image(systemName: "person.badge.key.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.teal)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                    
                    Text("Admin Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Admin ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter admin ID (e.g. HOS001)", text: $adminId)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: adminId) { _, newValue in
                                // Automatically format to uppercase for "HOS" part
                                if newValue.count >= 3 {
                                    let hosPrefix = newValue.prefix(3).uppercased()
                                    let numericPart = newValue.dropFirst(3)
                                    adminId = hosPrefix + numericPart
                                } else if newValue.count > 0 {
                                    adminId = newValue.uppercased()
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
                        
                        Text("Must contain at least 8 characters, one uppercase letter, one number, and one special character")
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
            
            NavigationLink(destination: AdminHomeView(), isActive: $isLoggedIn) {
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
            ChangePasswordSheet(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isValidInput: isValidPasswordChange,
                onSubmit: handlePasswordChange
            )
        }
    }
    
    private func handleLogin() {
        // Create the request body
        let credentials = [
            "userId": adminId,
            "password": password,
            "userType": "hospital"
        ]
        
        // Create the URL request
        guard let url = URL(string: "http://localhost:8082/validate-credentials") else {
            errorMessage = "Invalid server URL"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert credentials to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: credentials) else {
            errorMessage = "Error preparing request"
            showError = true
            return
        }
        
        request.httpBody = jsonData
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received from server"
                    self.showError = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    self.showError = true
                    return
                }
                
                // Check HTTP status code
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error (Status \(httpResponse.statusCode))"
                    self.showError = true
                    return
                }
                
                // Parse the response using Codable
                do {
                    let decoder = JSONDecoder()
                    struct LoginResponse: Codable {
                        let status: String
                        let message: String
                        let valid: Bool
                        let data: LoginData?
                        
                        struct LoginData: Codable {
                            let userId: String
                            let userType: String
                            let remainingTime: Int
                        }
                    }
                    
                    let response = try decoder.decode(LoginResponse.self, from: data)
                    
                    if response.status == "success" && response.valid {
                        self.showChangePasswordSheet = true
                    } else {
                        self.errorMessage = response.message
                        self.showError = true
                    }
                } catch let decodingError {
                    print("Parsing error: \(decodingError)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                    self.errorMessage = "Unable to process server response. Please try again."
                    self.showError = true
                }
            }
        }.resume()
    }
    
    private func handlePasswordChange() {
        showChangePasswordSheet = false
        isLoggedIn = true
    }
    
    // Validates that the admin ID is in format HOS followed by numbers
    private func isValidAdminId(_ id: String) -> Bool {
        let adminIdRegex = #"^HOS\d+$"#
        return NSPredicate(format: "SELF MATCHES %@", adminIdRegex).evaluate(with: id)
    }
    
    // Validates password complexity
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
struct ChangePasswordSheet: View {
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
                
                // Confirm Password field with toggle
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

// Custom TextField Style
struct CustomTextFieldStyles: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Custom Back Button
struct CustomBackButtons: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.teal)
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .background(Circle().fill(Color.white))
                .shadow(color: .gray.opacity(0.2), radius: 3)
        }
    }
}

#Preview {
    NavigationStack {
        AdminLoginView()
    }
}
