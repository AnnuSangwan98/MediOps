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
        isLoading = true
        
        Task {
            do {
                // First verify credentials
                let user = try await SupabaseService.shared.verifyPatientCredentials(
                    email: email,
                    password: password
                )
                
                // Then send OTP - this is now bypassed for development in EmailService
                let otp = try await EmailService.shared.sendOTP(
                    to: email,
                    role: "patient"
                )
                
                // Update UI on main thread
                await MainActor.run {
                    isLoading = false
                    currentOTP = otp
                    
                    // Navigate to OTP verification
                    navigationPath.append("OTPVerification")
                }
            } catch let error as NSError {
                await MainActor.run {
                    isLoading = false
                    
                    // Provide a more user-friendly error message
                    if error.domain == "NSURLErrorDomain" {
                        errorMessage = "Network error: Please check your internet connection"
                    } else if error.domain == "AuthError" {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                    
                    showError = true
                }
            }
        }
    }
    
    private func isValidInput() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return false
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            showError = true
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
