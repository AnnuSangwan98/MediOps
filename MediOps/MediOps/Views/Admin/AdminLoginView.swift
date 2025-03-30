import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var adminId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var navigateToAdminHome: Bool = false
    
    // Services
    private let supabase = SupabaseController.shared
    @EnvironmentObject private var navigationState: AppNavigationState
    
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
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                        
                        Image(systemName: "person.badge.key.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
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
                            .textFieldStyle(CustomTextFieldStyles())
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
                                    .textFieldStyle(CustomTextFieldStyles())
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyles())
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
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [
                                isValidLoginInput && !isLoading ? Color.teal : Color.gray.opacity(0.5),
                                isValidLoginInput && !isLoading ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .shadow(color: isValidLoginInput && !isLoading ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .disabled(!isValidLoginInput || isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            // Modern navigation API
            .navigationDestination(isPresented: $navigateToAdminHome) {
                AdminHomeView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .tint(.white)
                    Text("Authenticating...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.7)))
            }
        }
    }
    
    
    private func handleLogin() {
        guard isValidLoginInput else { return }
        
        isLoading = true
        
        Task {
            do {
                // Query the hospital_admins table directly to find the admin with the matching ID
                let admins = try await supabase.select(
                    from: "hospitals",
                    where: "id",
                    equals: adminId
                )
                
                // Check if admin exists
                guard let admin = admins.first else {
                    print("Login failed: No admin found with ID \(adminId)")
                    throw AuthError.userNotFound
                }
                
                // Verify password
                guard let storedPassword = admin["password"] as? String,
                      storedPassword == password else {
                    print("Login failed: Invalid password for admin \(adminId)")
                    throw AuthError.invalidCredentials
                }
                
                print("Admin authentication successful for ID: \(adminId)")
                
                // Store hospital ID in UserDefaults
                UserDefaults.standard.set(adminId, forKey: "hospital_id")
                print("Saved hospital ID to UserDefaults: \(adminId)")
                
                await MainActor.run {
                    isLoading = false
                    // Update navigation state and sign in as hospital admin
                    navigationState.signIn(as: .hospitalAdmin)
                    // Navigate to admin dashboard
                    navigateToAdminHome = true
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "An unexpected error occurred"
                    showError = true
                }
            }
        }
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

//// Custom Back Button
//struct CustomBackButtons: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        Button(action: {
//            dismiss()
//        }) {
//            Image(systemName: "chevron.left")
//                .foregroundColor(.teal)
//                .font(.system(size: 16, weight: .semibold))
//                .padding(10)
//                .background(Circle().fill(Color.white))
//                .shadow(color: .gray.opacity(0.2), radius: 3)
//        }
//    }
//}

#Preview {
    NavigationStack {
        AdminLoginView()
    }
}
