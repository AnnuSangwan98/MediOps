import SwiftUI

struct OTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToDashboard = false
    
    let email: String
    let expectedOTP: String
    let role: String
    
    @State private var enteredOTP = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func verifyOTP() {
        isLoading = true
        
        if enteredOTP == expectedOTP {
            Task {
                do {
                    // Verify OTP with backend
                    let isValid = try await SupabaseService.shared.verifyOTP(email: email, otp: enteredOTP)
                    
                    await MainActor.run {
                        isLoading = false
                        if isValid {
                            navigateToDashboard = true
                        } else {
                            errorMessage = "Invalid OTP. Please try again."
                            showError = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } else {
            isLoading = false
            errorMessage = "Invalid OTP. Please try again."
            showError = true
        }
    }
    
    private func resendOTP() {
        isLoading = true
        let newOTP = String(Int.random(in: 100000...999999))
        
        Task {
            do {
                try await SupabaseService.shared.sendOTP(to: email, otp: newOTP)
                
                await MainActor.run {
                    isLoading = false
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
            Text("Enter Verification Code")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("We've sent a verification code to\n\(email)")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            TextField("Enter OTP", text: $enteredOTP)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: verifyOTP) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Verify")
                }
            }
            .disabled(enteredOTP.count != 6 || isLoading)
            .buttonStyle(.borderedProminent)
            
            Button("Resend Code", action: resendOTP)
                .disabled(isLoading)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToDashboard) {
            if role.lowercased() == "patient" {
                PatientDashboardView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    OTPVerificationView(email: "test@example.com", expectedOTP: "123456", role: "patient")
} 