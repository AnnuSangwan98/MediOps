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
    @State private var isLoading: Bool = false
    
    // Reset token handling
    @State private var resetToken: String = ""
    @State private var passwordResetRequested: Bool = false
    @State private var passwordResetSuccess: Bool = false
    
    // New password fields
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
                    
                    if !passwordResetRequested {
                        emailSection
                    } else if !passwordResetSuccess {
                        newPasswordSection
                    } else {
                        successSection
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Processing...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.teal.opacity(0.8)))
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
            Text("Enter your email address to reset your password")
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
            
            Button(action: handlePasswordResetRequest) {
                Text("Send Reset Link")
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
            .disabled(email.isEmpty || !isValidEmail || isLoading)
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
            
            Button(action: handlePasswordReset) {
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
            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || !isValidPassword || newPassword != confirmPassword || isLoading)
        }
        .padding(.horizontal)
    }
    
    private var successSection: some View {
        VStack(spacing: 25) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("Password Reset Successful!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.teal)
            
            Text("Your password has been reset successfully. You can now log in with your new password.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button(action: {
                dismiss()
            }) {
                Text("Back to Login")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
            }
        }
        .padding(.horizontal)
    }
    
    private func handlePasswordResetRequest() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        isLoading = true
        
        Task {
            do {
                // First check if the user exists
                let userExists = try await AuthService.shared.checkPatientExists(email: normalizedEmail)
                
                if !userExists {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "No account found with this email address."
                        showError = true
                    }
                    return
                }
                
                // User exists, send password reset email
                resetToken = try await EmailService.shared.sendPasswordResetEmail(
                    to: normalizedEmail,
                    role: "Patient"
                )
                
                await MainActor.run {
                    isLoading = false
                    passwordResetRequested = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send password reset email: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func handlePasswordReset() {
        if newPassword != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        if !isValidPassword {
            errorMessage = "Password does not meet the requirements"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Verify the token is valid
                let emailFromToken = try await EmailService.shared.verifyPasswordResetToken(token: resetToken)
                
                // Get the user ID from email
                let users = try await SupabaseController.shared.select(
                    from: "users",
                    where: "email",
                    equals: emailFromToken
                )
                
                guard let userData = users.first, let userId = userData["id"] as? String else {
                    throw NSError(domain: "PasswordReset", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "User not found"
                    ])
                }
                
                // Hash the new password
                let passwordHash = SupabaseController.shared.hashPassword(newPassword)
                
                // Update the password in the database
                let updateData: [String: String] = [
                    "password_hash": passwordHash,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await SupabaseController.shared.update(
                    table: "users",
                    data: updateData,
                    where: "id",
                    equals: userId
                )
                
                await MainActor.run {
                    isLoading = false
                    passwordResetSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to reset password: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}



