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
            
            NavigationLink(destination: LabDashboardView(), isActive: $isLoggedIn) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: LabBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleLogin() {
        guard isValidLoginInput else { return }
        
        // Simulate authentication process
        // In a real app, this would call your authentication service
        
        // Mock login verification
        if labId.starts(with: "LAB") && isValidPassword(password) {
            // Successful login
            isLoggedIn = true
        } else {
            // Failed login
            errorMessage = "Invalid lab ID or password. Please try again."
            showError = true
        }
    }
    
    // Validates that the lab ID is in format LAB followed by numbers
    private func isValidLabId(_ id: String) -> Bool {
        let labIdRegex = #"^LAB\d+$"#
        return NSPredicate(format: "SELF MATCHES %@", labIdRegex).evaluate(with: id)
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

#Preview {
    NavigationStack {
        LabLoginView()
    }
}
