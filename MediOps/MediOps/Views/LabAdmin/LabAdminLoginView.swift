import SwiftUI

// Add extension for lab admin specific auth errors
extension AuthError {
    static let missingHospitalInfo = AuthError.custom("Missing hospital information for lab admin")
}

struct LabAdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var labId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var navigateToLabAdminHome: Bool = false
    
    // Services
    private let supabase = SupabaseController.shared
    @EnvironmentObject private var navigationState: AppNavigationState
    
    // Computed properties for validation
    private var isValidLoginInput: Bool {
        return !labId.isEmpty && !password.isEmpty &&
               isValidLabId(labId) && isValidPassword(password)
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
                    Image(systemName: "flask.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.teal)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                    
                    Text("Lab Admin Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Lab Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lab Admin ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter lab ID (e.g. LAB002)", text: $labId)
                            .textFieldStyle(CustomTextFieldStyles())
                            .onChange(of: labId) { _, newValue in
                                // Automatically format to uppercase for "LAB" part
                                if newValue.count >= 3 {
                                    let labPrefix = newValue.prefix(3).uppercased()
                                    let numericPart = newValue.dropFirst(3)
                                    labId = labPrefix + numericPart
                                } else if newValue.count > 0 {
                                    labId = newValue.uppercased()
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
            
            NavigationLink(destination: LabAdminHomeView(), isActive: $navigateToLabAdminHome) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButtons())
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
                // Query the lab_admins table directly to find the lab admin with the matching ID
                let labAdmins = try await supabase.select(
                    from: "lab_admins",
                    where: "id",
                    equals: labId
                )
                
                // Check if lab admin exists
                guard let labAdmin = labAdmins.first else {
                    print("Login failed: No lab admin found with ID \(labId)")
                    throw AuthError.userNotFound
                }
                
                // Verify password
                guard let storedPassword = labAdmin["password"] as? String,
                      storedPassword == password else {
                    print("Login failed: Invalid password for lab admin \(labId)")
                    throw AuthError.invalidCredentials
                }
                
                print("Lab admin authentication successful for ID: \(labId)")
                
                // Get the hospital ID associated with this lab admin
                guard let hospitalId = labAdmin["hospital_id"] as? String else {
                    print("Login failed: No hospital ID associated with lab admin \(labId)")
                    throw AuthError.missingHospitalInfo
                }
                
                // Store lab admin ID and hospital ID in UserDefaults
                UserDefaults.standard.set(labId, forKey: "lab_admin_id")
                UserDefaults.standard.set(hospitalId, forKey: "hospital_id")
                print("Saved lab admin ID to UserDefaults: \(labId)")
                print("Saved hospital ID to UserDefaults: \(hospitalId)")
                
                await MainActor.run {
                    isLoading = false
                    // Update navigation state and sign in as lab admin
                    navigationState.signIn(as: .labAdmin)
                    // Navigate to lab admin dashboard
                    navigateToLabAdminHome = true
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
    
    // Validates that the lab ID is in format LAB followed by 3 digits
    private func isValidLabId(_ id: String) -> Bool {
        let labIdRegex = #"^LAB\d{3}$"#
        return NSPredicate(format: "SELF MATCHES %@", labIdRegex).evaluate(with: id)
    }
    
    // Validates password complexity according to the Supabase table constraint
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else { return false }
        
        // Check for at least one lowercase letter
        let lowercaseRegex = ".*[a-z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: password) else { return false }
        
        // Check for at least one number
        let numberRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) else { return false }
        
        // Check for at least one special character (@$!%*?&)
        let specialCharRegex = ".*[@$!%*?&]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) else { return false }
        
        return true
    }
}

#Preview {
    NavigationStack {
        LabAdminLoginView()
    }
} 