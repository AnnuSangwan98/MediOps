import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var adminId: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading = false
    @State private var navigateToAdminHome = false
    
    // Services
    private let authService = AuthService.shared
    private let userController = UserController.shared
    
    // Computed properties for validation
    private var isValidInput: Bool {
        return !adminId.isEmpty && !password.isEmpty &&
               isValidAdminId(adminId) && isValidPassword(password)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo or App Name
                    Text("Hospital Admin Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.teal)
                    
                    VStack(spacing: 20) {
                        // Admin ID Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Admin ID")
                                .foregroundColor(.gray)
                            TextField("Enter your admin ID", text: $adminId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .foregroundColor(.gray)
                            HStack {
                                if isPasswordVisible {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Login Button
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput && !isLoading ? Color.teal : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(!isValidInput || isLoading)
                    
                    Spacer()
                }
                .padding(.top, 50)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
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
            .background(
                NavigationLink(destination: HospitalAdminDashboardView(), isActive: $navigateToAdminHome) {
                    EmptyView()
                }
            )
        }
    }
    
    private func handleLogin() {
        guard isValidInput else { return }
        
        isLoading = true
        
        Task {
            do {
                // Attempt to login
                let authResponse = try await userController.login(email: adminId, password: password)
                
                // Verify the user is a hospital admin
                guard authResponse.user.role == .hospitalAdmin else {
                    throw AuthError.invalidRole
                }
                
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

#Preview {
    AdminLoginView()
        .environmentObject(AppNavigationState())
} 