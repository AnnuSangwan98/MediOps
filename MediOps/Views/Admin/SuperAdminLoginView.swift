import SwiftUI

class SuperAdminAuthViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var showError = false
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    // Fixed credentials
    private let ADMIN_USERNAME = "SUPER1"
    private let ADMIN_PASSWORD = "Super@123"
    
    var isValidInput: Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedUsername.isEmpty && !trimmedPassword.isEmpty
    }
    
    func login() {
        print("Attempting login with username: \(username), password: \(password)")
        // Trim whitespace to prevent login issues
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedUsername.isEmpty || trimmedPassword.isEmpty {
            errorMessage = "Please enter both username and password"
            showError = true
            isAuthenticated = false
            return
        }
        
        if trimmedUsername == ADMIN_USERNAME && trimmedPassword == ADMIN_PASSWORD {
            print("Login successful")
            isAuthenticated = true
            showError = false
            errorMessage = ""
        } else {
            print("Login failed")
            errorMessage = "No user found. Please check your credentials."
            showError = true
            isAuthenticated = false
        }
    }
    
    func logout() {
        isAuthenticated = false
        username = ""
        password = ""
        errorMessage = ""
    }
}

struct SuperAdminLoginView: View {
    @StateObject private var viewModel = SuperAdminAuthViewModel()
    @State private var isPasswordVisible = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        // Circular logo background
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                            .overlay(
                                Image(systemName: "person.badge.key.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.teal)
                            )
                        
                        Text("Super Admin Login")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.teal)
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: 25) {
                        // Super Admin ID Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Super Admin ID")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            TextField("", text: $viewModel.username)
                                .font(.title3)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .shadow(color: .gray.opacity(0.2), radius: 5)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            HStack {
                                if isPasswordVisible {
                                    TextField("", text: $viewModel.password)
                                        .font(.title3)
                                } else {
                                    SecureField("", text: $viewModel.password)
                                        .font(.title3)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.2), radius: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Login Button
                    Button(action: {
                        viewModel.login()
                    }) {
                        HStack {
                            Text("Login")
                                .font(.title2)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.isValidInput ?
                            Color.teal.opacity(0.9) :
                            Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(!viewModel.isValidInput)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .alert("Login Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
                SuperAdminDashboardView()
                    .navigationBarBackButtonHidden()
            }
        }
    }
}

#Preview {
    SuperAdminLoginView()
} 