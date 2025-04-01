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
                Text("Proceed")
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
        
        print("PASSWORD RESET: Starting for email: \(normalizedEmail)")
        
        Task {
            do {
                // Download all users data directly
                let allUsers = try await SupabaseController.shared.select(from: "users")
                print("PASSWORD RESET: Downloaded \(allUsers.count) users from database")
                
                // Debug: Print all emails to verify
                print("PASSWORD RESET: Available emails in users table:")
                var foundUserId: String? = nil
                var foundUserRole: String? = nil
                
                for user in allUsers {
                    if let userEmail = user["email"] as? String {
                        print("  - \(userEmail)")
                        
                        // Case-insensitive matching
                        if userEmail.lowercased() == normalizedEmail {
                            foundUserId = user["id"] as? String
                            foundUserRole = user["role"] as? String
                            print("PASSWORD RESET: ✓ Found matching user: \(userEmail), ID: \(foundUserId ?? "unknown"), Role: \(foundUserRole ?? "unknown")")
                        }
                    }
                }
                
                // Also check patients table as a backup
                let allPatients = try await SupabaseController.shared.select(from: "patients")
                print("PASSWORD RESET: Downloaded \(allPatients.count) patients from database")
                
                var foundPatientByEmail = false
                var foundPatientByUserId = false
                
                // Check patients table by email first
                for patient in allPatients {
                    if let patientEmail = patient["email"] as? String, 
                       patientEmail.lowercased() == normalizedEmail {
                        foundPatientByEmail = true
                        print("PASSWORD RESET: ✓ Found patient with matching email: \(patientEmail)")
                    }
                    
                    // If we found a user ID, also check by user_id
                    if let userId = foundUserId,
                       let patientUserId = patient["user_id"] as? String,
                       patientUserId == userId {
                        foundPatientByUserId = true
                        print("PASSWORD RESET: ✓ Found patient with matching user_id: \(userId)")
                    }
                }
                
                // No account found in either table
                if foundUserId == nil && !foundPatientByEmail {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "No account found with this email address."
                        showError = true
                    }
                    return
                }
                
                // If we made it here, we found an account
                print("PASSWORD RESET: Account verification successful")
                
                // Send an actual password reset email with a token
                do {
                    let role = foundUserRole ?? "Patient" // Default to Patient if role not found
                    resetToken = try await EmailService.shared.sendPasswordResetEmail(to: normalizedEmail, role: role)
                    print("PASSWORD RESET: Reset token email sent successfully: \(resetToken)")
                    
                    await MainActor.run {
                        isLoading = false
                        passwordResetRequested = true
                    }
                } catch {
                    print("PASSWORD RESET: Failed to send reset email: \(error.localizedDescription)")
                    
                    // Fallback to simulated token for development/testing
                    resetToken = UUID().uuidString
                    print("PASSWORD RESET: Using fallback token: \(resetToken)")
                    
                    await MainActor.run {
                        isLoading = false
                        passwordResetRequested = true
                    }
                }
            } catch {
                print("PASSWORD RESET ERROR: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to verify account: \(error.localizedDescription)"
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
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("PASSWORD RESET: Processing new password for email: \(normalizedEmail)")
        
        Task {
            do {
                // Directly download all users and find the one we need
                let allUsers = try await SupabaseController.shared.select(from: "users")
                print("PASSWORD RESET: Downloaded \(allUsers.count) users for password update")
                
                var userId: String? = nil
                
                // Find user with case-insensitive matching
                for user in allUsers {
                    if let userEmail = user["email"] as? String, 
                       userEmail.lowercased() == normalizedEmail {
                        userId = user["id"] as? String
                        print("PASSWORD RESET: Found user with ID: \(userId ?? "unknown") to update password")
                        break
                    }
                }
                
                guard let userId = userId else {
                    throw NSError(domain: "PasswordReset", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "User not found when trying to update password"
                    ])
                }
                
                // Hash the new password (for development, this is just plain text)
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
                
                print("PASSWORD RESET: Successfully updated password for user ID: \(userId)")
                
                await MainActor.run {
                    isLoading = false
                    passwordResetSuccess = true
                }
                
            } catch {
                print("PASSWORD RESET ERROR: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to reset password: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}



