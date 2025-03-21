//
//  PatientOTPVerificationView.swift
//  MediOps
//
//  Created by Sharvan on 18/03/25.
//

import SwiftUI

struct PatientOTPVerificationView: View {
    let email: String
    let expectedOTP: String
    
    @State private var otpFields: [String] = Array(repeating: "", count: 6)
    @State private var currentField: Int = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isVerified = false
    @State private var navigateToHome = false
    
    @Environment(\.dismiss) private var dismiss
    
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
                Text("Resend OTP")
                    .foregroundColor(.teal)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
        
        // Normalize email by trimming whitespace and converting to lowercase
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check if the entered OTP matches the expected OTP
        if enteredOTP == expectedOTP {
            isLoading = true
            
            print("OTP verification successful, updating email_verified status for: \(normalizedEmail)")
            
            // Update the email_verified status in the database
            Task {
                do {
                    // First get patient by email
                    let patients = try await SupabaseController.shared.select(
                        from: "patients",
                        where: "email",
                        equals: normalizedEmail
                    )
                    
                    if let patientData = patients.first, let patientId = patientData["id"] as? String {
                        print("Found patient with ID: \(patientId), updating email verification status")
                        
                        // Update email_verified status
                        try await PatientController.shared.verifyPatientEmail(patientId: patientId)
                        
                        await MainActor.run {
                            isLoading = false
                            isVerified = true
                            navigateToHome = true
                        }
                    } else {
                        print("Patient not found for email: \(normalizedEmail)")
                        throw NSError(domain: "PatientError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Patient not found"])
                    }
                } catch {
                    print("Error verifying email: \(error.localizedDescription)")
                    
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Failed to verify email: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        } else {
            errorMessage = "Invalid OTP. Please try again."
            showError = true
        }
    }
    
    private func resendOTP() {
        Task {
            do {
                try await EmailService.shared.sendOTP(to: email, role: "Patient")
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to resend OTP: \(error.localizedDescription)"
                    showError = true
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

#Preview {
    NavigationView {
        PatientOTPVerificationView(email: "test@example.com", expectedOTP: "123456")
    }
}

