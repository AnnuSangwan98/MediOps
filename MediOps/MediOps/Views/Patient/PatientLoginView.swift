import SwiftUI

struct PatientLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToOTP = false
    @State private var showForgotPassword = false
    @State private var isLoading = false
    @State private var currentOTP: String = ""
    @State private var navigationPath = NavigationPath()
    @State private var isAuthenticated = false
    
    private var isloginButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email) && password.count >= 8
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.teal)
                        }
                        
                        Text("Patient Login")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.teal)
                    }
                    .padding(.top, 50)
                    
                    // Login Form
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter email address", text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        VStack(alignment: .leading, spacing: 8){
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter password (minimum 8 characters)", text: $password)
                                .textContentType(.password)
                                .textFieldStyle(CustomTextFieldStyle())
                            if !password.isEmpty && password.count < 8 {
                                Text("Password must be at least 8 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            Button(action: { showForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 4)
                        }
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Proceed")
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
                                isloginButtonEnabled ?
                                LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                               startPoint: .leading,
                                               endPoint: .trailing) :
                                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(color: isloginButtonEnabled ? .teal.opacity(0.3) : .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .disabled(!isloginButtonEnabled || isLoading)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    NavigationLink(destination: PatientSignupView()) {
                        HStack {
                            Text("Not a user?")
                                .foregroundColor(.gray)
                            Text("SignUp here")
                                .foregroundColor(.teal)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "OTPVerification" {
                    PatientOTPVerificationView(email: email, expectedOTP: currentOTP)
                } else if destination == "PatientHome" {
                    PatientHomeView()
                }
            }
            .navigationDestination(isPresented: $navigateToOTP) {
                PatientOTPVerificationView(email: email, expectedOTP: currentOTP)
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                PatientForgotPasswordView()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: CustomBackButton())
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            print("PatientLoginView appeared")
        }
    }
    
    private func handleLogin() {
        guard isValidInput() else { return }
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        isLoading = true
        
        print("PATIENT LOGIN: Attempting login with normalized email: \(normalizedEmail)")
        
        Task {
            do {
                // Attempt to login with the provided credentials
                let (patient, token) = try await AuthService.shared.loginPatient(email: normalizedEmail, password: password)
                
                print("PATIENT LOGIN: Successfully authenticated user: \(normalizedEmail)")
                print("PATIENT LOGIN: Patient ID: \(patient.id), Name: \(patient.name)")
                
                // Store the token securely
                UserDefaults.standard.set(token, forKey: "auth_token")
                UserDefaults.standard.set(patient.id, forKey: "current_patient_id")
                UserDefaults.standard.set(patient.userId, forKey: "current_user_id")
                
                await MainActor.run {
                    isLoading = false
                    isAuthenticated = true
                    
                    // Navigate to the patient home screen
                    navigationPath.append("PatientHome")
                }
            } catch let error as AuthError {
                // Provide specific error messages based on the error type
                await MainActor.run {
                    isLoading = false
                    
                    switch error {
                    case .userNotFound:
                        errorMessage = "Patient account not found. Please check your email or sign up first."
                        print("PATIENT LOGIN ERROR: User not found for email: \(normalizedEmail)")
                        
                    case .invalidCredentials:
                        errorMessage = "Invalid password. Please try again."
                        print("PATIENT LOGIN ERROR: Invalid credentials for email: \(normalizedEmail)")
                        
                    case .invalidRole:
                        errorMessage = "This account is not registered as a patient."
                        print("PATIENT LOGIN ERROR: Invalid role (not a patient) for email: \(normalizedEmail)")
                        
                    default:
                        errorMessage = error.localizedDescription
                        print("PATIENT LOGIN ERROR: \(error.localizedDescription)")
                    }
                    
                    showError = true
                }
            } catch {
                // Handle any other errors
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Login failed: \(error.localizedDescription)"
                    print("PATIENT LOGIN ERROR: Unexpected error: \(error.localizedDescription)")
                    showError = true
                }
            }
        }
    }
    
    private func isValidInput() -> Bool {
        // Check email format
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return false
        }
        
        // Check password
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            showError = true
            return false
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
} 