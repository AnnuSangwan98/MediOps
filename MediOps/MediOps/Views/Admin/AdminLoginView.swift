import SwiftUI

struct AdminLoginView: View {
    var body: some View {
        LoginView(
            title: "Admin Login",
            initialCredentials: AdminCredentials(id: "", password: ""),
            onLogin: { credentials in
                // Handle admin login
            }
        )
    }
}

// Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    var isValidInput: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Change Password")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.teal)
                .padding(.top, 20)
            
            // Form fields
            VStack(spacing: 20) {
                // New Password field with toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ZStack {
                        if isNewPasswordVisible {
                            TextField("Enter new password", text: $newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Enter new password", text: $newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                isNewPasswordVisible.toggle()
                            }) {
                                Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    Text("Must contain at least 8 characters, one uppercase letter, one number, and one special character")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                
                // Confirm Password field with toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ZStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        } else {
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Submit Button
            Button(action: onSubmit) {
                Text("Submit")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [
                            isValidInput ? Color.teal : Color.gray.opacity(0.5),
                            isValidInput ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .shadow(color: isValidInput ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .disabled(!isValidInput)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(.top, 20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// Custom TextField Style
struct CustomTextFieldStyles: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Custom Back Button
struct CustomBackButtons: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.teal)
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .background(Circle().fill(Color.white))
                .shadow(color: .gray.opacity(0.2), radius: 3)
        }
    }
}

#Preview {
    NavigationStack {
        AdminLoginView()
    }
}
