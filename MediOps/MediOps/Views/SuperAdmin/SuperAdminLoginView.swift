import SwiftUI

struct SuperAdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var adminId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // Computed properties for validation
    private var isValidLoginInput: Bool {
        return !adminId.isEmpty && !password.isEmpty &&
               isValidAdminId(adminId) && isValidPassword(password)
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
                    
                    Text("Super Admin Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Super Admin ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter super admin ID (e.g. HOS001)", text: $adminId)
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
                    
                    // Password field with toggle
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
            
            NavigationLink(destination: SuperAdminDashboardView(), isActive: $isLoggedIn) {
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
    }
    
    private func handleLogin() {
        // TODO: Implement actual login logic here
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

#Preview {
    NavigationStack {
        SuperAdminLoginView()
    }
}
