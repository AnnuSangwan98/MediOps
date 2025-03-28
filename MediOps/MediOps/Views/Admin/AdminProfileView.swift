import SwiftUI

struct AdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var showLogoutAlert = false
    @State private var showResetPasswordSheet = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showResetSuccess = false
    @State private var showResetError = false
    @State private var resetErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.teal)
                    .padding(.top, 20)
                
                Text("Admin Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Form {
                    Section(header: Text("Personal Information")) {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text("Hospital Admin")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text("admin@mediops.com")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            Text("Hospital Administrator")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text("Security")) {
                        Button(action: {
                            showResetPasswordSheet = true
                        }) {
                            HStack {
                                Text("Reset Password")
                                Spacer()
                                Image(systemName: "key.fill")
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Logout")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Yes, Logout", role: .destructive) {
                    // First sign out in navigation state
                    navigationState.signOut()
                    
                    // Dismiss the profile sheet
                    dismiss()
                    
                    // Get the scene delegate window
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else { return }
                    
                    // Reset to RoleSelectionView
                    let contentView = NavigationStack {
                        RoleSelectionView()
                    }
                    .environmentObject(navigationState)
                    
                    window.rootViewController = UIHostingController(rootView: contentView)
                    window.makeKeyAndVisible()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .sheet(isPresented: $showResetPasswordSheet) {
                ResetPasswordView(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    onSubmit: handlePasswordReset,
                    onCancel: { showResetPasswordSheet = false }
                )
            }
            .alert("Success", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been successfully reset.")
            }
            .alert("Error", isPresented: $showResetError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetErrorMessage)
            }
        }
    }
    
    private func handlePasswordReset() {
        // Validate current password
        guard !currentPassword.isEmpty else {
            resetErrorMessage = "Please enter your current password."
            showResetError = true
            return
        }
        
        // Validate new password
        guard isValidPassword(newPassword) else {
            resetErrorMessage = "New password must be at least 8 characters and include uppercase, lowercase, number, and special character."
            showResetError = true
            return
        }
        
        // Validate password confirmation
        guard newPassword == confirmPassword else {
            resetErrorMessage = "New passwords don't match."
            showResetError = true
            return
        }
        
        // In a real app, call the authentication service to change the password
        // For now, we'll simulate a successful password change
        
        // Clear the form
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        
        // Close the password reset sheet
        showResetPasswordSheet = false
        
        // Show success message
        showResetSuccess = true
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: password) else { return false }
        
        // Check for at least one number
        let numberRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) else { return false }
        
        // Check for at least one special character
        let specialCharRegex = ".*[@#$%^&*()\\-_=+\\[\\]{}|;:'\",.<>/?]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) else { return false }
        
        return true
    }
}

// Password Reset View
struct ResetPasswordView: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @Environment(\.dismiss) private var dismiss
    
    var onSubmit: () -> Void
    var onCancel: () -> Void
    
    var isFormValid: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty &&
        newPassword == confirmPassword && newPassword.count >= 8
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    HStack {
                        if isCurrentPasswordVisible {
                            TextField("Enter current password", text: $currentPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Enter current password", text: $currentPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button {
                            isCurrentPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isCurrentPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                
                Section(header: Text("New Password")) {
                    HStack {
                        if isNewPasswordVisible {
                            TextField("Enter new password", text: $newPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Enter new password", text: $newPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button {
                            isNewPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 44, height: 44)
                    }
                    
                    Text("Must contain at least 8 characters, one uppercase letter, one number, and one special character")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Confirm Password")) {
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm new password", text: $confirmPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Confirm new password", text: $confirmPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button {
                            isConfirmPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                
                Section {
                    Button(action: onSubmit) {
                        Text("Reset Password")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isFormValid ? Color.teal : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    AdminProfileView()
        .environmentObject(AppNavigationState())
} 