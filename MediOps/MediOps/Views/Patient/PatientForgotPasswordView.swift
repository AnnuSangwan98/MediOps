//
//  PatientForgotPasswordView.swift
//  MediOps
//
//  Created by Sharvan on 20/03/25.
//

import SwiftUI

struct PatientForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var otpSent: Bool = false
    @State private var otp: String = ""
    @State private var otpVerified: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    private var isValidEmail: Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPred.evaluate(with: newPassword)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("Reset Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                        .padding(.top, 50)
                    
                    if !otpSent {
                        emailSection
                    } else if !otpVerified {
                        otpSection
                    } else {
                        newPasswordSection
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var emailSection: some View {
        VStack(spacing: 20) {
            Text("Enter your email address to receive an OTP")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(CustomTextFieldStyle())
                
                if !email.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Button(action: handleSendOTP) {
                Text("Send OTP")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        !email.isEmpty && isValidEmail ?
                        LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                       startPoint: .leading,
                                       endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
            }
            .disabled(email.isEmpty || !isValidEmail)
        }
        .padding(.horizontal)
    }
    
    private var otpSection: some View {
        VStack(spacing: 20) {
            Text("Enter the OTP sent to\n\(email)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("OTP")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Enter OTP", text: $otp)
                    .keyboardType(.numberPad)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            Button(action: handleVerifyOTP) {
                Text("Verify OTP")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        !otp.isEmpty ?
                        LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                       startPoint: .leading,
                                       endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
            }
            .disabled(otp.isEmpty)
            
            Button(action: handleResendOTP) {
                Text("Resend OTP")
                    .foregroundColor(.teal)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
    
    private var newPasswordSection: some View {
        VStack(spacing: 20) {
            Text("Set your new password")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                SecureField("Enter new password", text: $newPassword)
                    .textFieldStyle(CustomTextFieldStyle())
                
                if !newPassword.isEmpty && !isValidPassword {
                    Text("Password must contain uppercase, lowercase, number, and special character")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                SecureField("Confirm new password", text: $confirmPassword)
                    .textFieldStyle(CustomTextFieldStyle())
                
                if !confirmPassword.isEmpty && confirmPassword != newPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Button(action: handleResetPassword) {
                Text("Reset Password")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        !newPassword.isEmpty && !confirmPassword.isEmpty && isValidPassword && newPassword == confirmPassword ?
                        LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                       startPoint: .leading,
                                       endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
            }
            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || !isValidPassword || newPassword != confirmPassword)
        }
        .padding(.horizontal)
    }
    
    private func handleSendOTP() {
        if !isValidEmail {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        otpSent = true
    }
    
    private func handleVerifyOTP() {
        if otp.count != 6 {
            errorMessage = "Please enter a valid OTP"
            showError = true
            return
        }
        
        otpVerified = true
    }
    
    private func handleResendOTP() {
        errorMessage = "New OTP has been sent to your email"
        showError = true
    }
    
    private func handleResetPassword() {
        if !isValidPassword {
            errorMessage = "Password doesn't meet the requirements"
            showError = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        dismiss()
    }
}



