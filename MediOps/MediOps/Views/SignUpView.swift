import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var age = 0
    @State private var gender = ""
    @State private var isLoading = false
    @State private var showOTPVerification = false
    @State private var currentOTP = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func handleProceed() {
        // Validate all fields
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            showError = true
            return
        }
        
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            showError = true
            return
        }
        
        guard age > 0 else {
            errorMessage = "Please enter a valid age"
            showError = true
            return
        }
        
        guard !gender.isEmpty else {
            errorMessage = "Please select your gender"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // First create the user and get OTP
                let (patient, token) = try await AuthService.shared.signUpPatient(
                    email: email,
                    password: password,
                    username: name,
                    age: age,
                    gender: gender
                )
                
                // Generate an OTP (we should move this to a dedicated service)
                let otp = String(Int.random(in: 100000...999999))
                currentOTP = otp
                
                // TODO: Send OTP email (replace with actual implementation)
                print("OTP: \(otp) would be sent to \(email)")
                
                await MainActor.run {
                    isLoading = false
                    showOTPVerification = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: handleProceed) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Proceed")
                        .fontWeight(.semibold)
                }
            }
            .disabled(isLoading)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .fullScreenCover(isPresented: $showOTPVerification) {
            NavigationView {
                PatientOTPVerificationView(
                    email: email,
                    expectedOTP: currentOTP
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
} 
