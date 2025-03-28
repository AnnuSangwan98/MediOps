import SwiftUI
// Import custom components from the app
import SwiftUI

struct LabLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var labId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var currentLabAdmin: LabAdmin? = nil
    
    private let adminController = AdminController.shared
    private let supabase = SupabaseController.shared
    
    // Computed properties for validation
    private var isValidLoginInput: Bool {
        return !labId.isEmpty && !password.isEmpty &&
               isValidLabId(labId) && password.count >= 6 // Simplified password check for login
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
                        
                        Image(systemName: "document.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Lab Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Lab ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lab ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter lab ID (e.g. LAB001)", text: $labId)
                            .textFieldStyle(LabTextFieldStyle())
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
                    
                    // Password field with toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textFieldStyle(LabTextFieldStyle())
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(LabTextFieldStyle())
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
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
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
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: LabBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay(
            NavigationLink(destination: Group {
                if let labAdmin = currentLabAdmin {
                    LabDashboardView(labAdmin: labAdmin)
                } else {
                    EmptyView()
                }
            }, isActive: $isLoggedIn) {
                EmptyView()
            }
        )
    }
    
    private func handleLogin() {
        guard isValidLoginInput else { return }
        isLoading = true
        
        // Perform authentication against Supabase
        Task {
            do {
                // Query the lab_admins table for the matching lab ID
                print("Attempting to authenticate lab admin with ID: \(labId)")
                let labAdmins = try await supabase.select(
                    from: "lab_admins",
                    where: "id",
                    equals: labId
                )
                
                guard let labAdmin = labAdmins.first else {
                    print("Lab admin not found with ID: \(labId)")
                    throw LabAuthError.invalidCredentials
                }
                
                // Verify password
                guard let storedPassword = labAdmin["password"] as? String,
                      storedPassword == password else {
                    print("Invalid password for lab admin: \(labId)")
                    throw LabAuthError.invalidCredentials
                }
                
                print("Lab admin authenticated successfully: \(labId)")
                
                // Use the public getLabAdmin method
                let admin = try await adminController.getLabAdmin(id: labId)
                print("Lab admin details retrieved: \(admin.name), \(admin.id)")
                
                // Update UI on main thread
                await MainActor.run {
                    print("Setting currentLabAdmin and activating navigation")
                    self.currentLabAdmin = admin
                    self.isLoading = false
                    self.isLoggedIn = true
                    
                    // Force UI update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !self.isLoggedIn {
                            print("Navigation didn't activate, forcing again")
                            self.isLoggedIn = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Login failed: \(error.localizedDescription)"
                    if let authError = error as? LabAuthError {
                        switch authError {
                        case .invalidCredentials:
                            errorMessage = "Invalid lab ID or password. Please try again."
                        default:
                            errorMessage = "Authentication failed. Please try again."
                        }
                    }
                    showError = true
                }
                print("Lab login error: \(error)")
            }
        }
    }
    
    // Validates that the lab ID is in format LAB followed by numbers
    private func isValidLabId(_ id: String) -> Bool {
        let labIdRegex = #"^LAB\d+$"#
        return NSPredicate(format: "SELF MATCHES %@", labIdRegex).evaluate(with: id)
    }
    
    // Validates password complexity (only used for form validation, not login)
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
struct LabTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Custom Back Button
struct LabBackButton: View {
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

// Authentication Error
enum LabAuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError:
            return "Network error. Check your connection"
        case .serverError:
            return "Server error. Please try again later"
        }
    }
}

#Preview {
    NavigationStack {
        LabLoginView()
    }
}
