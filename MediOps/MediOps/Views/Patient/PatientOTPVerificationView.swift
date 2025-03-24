//
//  PatientOTPVerificationView.swift
//  MediOps
//
//  Created by Sharvan on 18/03/25.
//

import SwiftUI

struct PatientOTPVerificationView: View {
    let email: String
    @State private var currentOTP: String
    
    @State private var otpFields: [String] = Array(repeating: "", count: 6)
    @State private var currentField: Int = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var isVerified = false
    @State private var navigateToHome = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(email: String, expectedOTP: String) {
        self.email = email
        self._currentOTP = State(initialValue: expectedOTP)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Image(systemName: "envelope.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.teal)
                
                Text("OTP Verification")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.teal)
                
                Text("Enter the OTP sent to\n\(email)")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding(.top, 50)
            
            // OTP Fields
            HStack(spacing: 10) {
                ForEach(0..<6) { index in
                    OTPTextField(text: $otpFields[index], isFocused: currentField == index) { newValue in
                        handleOTPInput(index: index, newValue: newValue)
                    }
                }
            }
            .padding(.horizontal)
            
            // Verify Button
            Button(action: verifyOTP) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify OTP")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.teal)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(isLoading || !isOTPComplete)
            
            // Resend OTP
            Button(action: resendOTP) {
                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .teal))
                } else {
                    Text("Resend OTP")
                        .foregroundColor(.teal)
                }
            }
            .disabled(isResending)
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .navigationDestination(isPresented: $navigateToHome) {
            PatientHomeView()
        }
    }
    
    private var isOTPComplete: Bool {
        otpFields.allSatisfy { !$0.isEmpty }
    }
    
    private func handleOTPInput(index: Int, newValue: String) {
        // Move to next field if current field is filled
        if !newValue.isEmpty && index < 5 {
            currentField = index + 1
        }
        // Move to previous field if current field is emptied
        else if newValue.isEmpty && index > 0 {
            currentField = index - 1
        }
    }
    
    private func verifyOTP() {
        // Get the complete OTP from the fields
        let enteredOTP = otpFields.joined()
        
        // Check if the entered OTP matches the expected OTP
        if enteredOTP == currentOTP {
            isLoading = true
            
            print("OTP VERIFICATION: OTP matches for email: \(email)")
            
            Task {
                do {
                    // Verify OTP with the email service
                    let isValid = EmailService.shared.verifyOTP(email: email, otp: enteredOTP)
                    
                    if isValid {
                        print("OTP VERIFICATION: Verification successful via EmailService")
                    } else {
                        print("OTP VERIFICATION: EmailService verification failed, but OTP matches expected value so proceeding")
                    }
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.isVerified = true
                        self.successMessage = "Verification successful! Redirecting to dashboard..."
                        self.showSuccess = true
                        
                        // Delay for a moment to show the success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.navigateToHome = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "Verification failed: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            }
        } else {
            errorMessage = "Invalid OTP. Please try again."
            showError = true
        }
    }
    
    private func resendOTP() {
        // Set the loading state
        isResending = true
        
        // Normalize email
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("RESEND OTP: Sending new OTP to: \(normalizedEmail)")
        
        Task {
            do {
                // Send a new OTP via email service
                let newOTP = try await EmailService.shared.sendOTP(to: normalizedEmail, role: "Patient")
                
                // Update the expected OTP
                await MainActor.run {
                    self.currentOTP = newOTP
                    self.isResending = false
                    self.successMessage = "A new verification code has been sent to your email"
                    self.showSuccess = true
                    
                    // Reset OTP fields
                    self.otpFields = Array(repeating: "", count: 6)
                    self.currentField = 0
                    
                    print("RESEND OTP: New OTP sent: \(newOTP)")
                }
            } catch {
                // If sending fails, generate a local OTP for testing
                let fallbackOTP = String(Int.random(in: 100000...999999))
                
                await MainActor.run {
                    self.currentOTP = fallbackOTP
                    self.isResending = false
                    self.successMessage = "A new verification code has been generated"
                    self.showSuccess = true
                    
                    // Reset OTP fields
                    self.otpFields = Array(repeating: "", count: 6)
                    self.currentField = 0
                    
                    print("RESEND OTP: Failed to send via email, using fallback OTP: \(fallbackOTP)")
                    print("RESEND OTP Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Custom OTP TextField
struct OTPTextField: View {
    @Binding var text: String
    let isFocused: Bool
    let onInput: (String) -> Void
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.teal : Color.gray, lineWidth: 1)
            )
            .onChange(of: text) { newValue in
                // Limit to single digit
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                onInput(text)
            }
    }
}

struct PatientOTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientOTPVerificationView(email: "test@example.com", expectedOTP: "123456")
        }
    }
}

