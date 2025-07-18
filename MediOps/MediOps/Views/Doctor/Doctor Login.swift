import SwiftUI

struct DoctorLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var doctorId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showChangePasswordSheet: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    
    // Computed properties for validation
    private var isValidLoginInput: Bool {
        return !doctorId.isEmpty && !password.isEmpty &&
               isValidAdminId(doctorId) && isValidPassword(password)
    }
    
    private var isValidPasswordChange: Bool {
        return !newPassword.isEmpty && !confirmPassword.isEmpty &&
               newPassword == confirmPassword && isValidPassword(newPassword)
    }
    
    var body: some View {
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
                        
                        Image(systemName: "stethoscope")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Doctor Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doctor ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter doctor ID (e.g. DOCXXX)", text: $doctorId)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: doctorId) { _, newValue in
                                // Automatically format to uppercase for "HOS" part
                                if newValue.count >= 3 {
                                    let hosPrefix = newValue.prefix(3).uppercased()
                                    let numericPart = newValue.dropFirst(3)
                                    doctorId = hosPrefix + numericPart
                                } else if newValue.count > 0 {
                                    doctorId = newValue.uppercased()
                                }
                            }
                    }
                    
                    // Password field with requirements hint and toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
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
                    
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                                Text("Logging in...")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Login")
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
                            LinearGradient(gradient: Gradient(colors: [
                                (!isLoading && isValidLoginInput) ? Color.teal : Color.gray.opacity(0.5),
                                (!isLoading && isValidLoginInput) ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .shadow(color: (!isLoading && isValidLoginInput) ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                    .disabled(!isValidLoginInput || isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            NavigationLink(destination: DoctorHomeView(), isActive: $isLoggedIn) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordSheets(
                newPassword: $newPassword,
                confirmPassword: $confirmPassword,
                isValidInput: isValidPasswordChange,
                isLoading: isLoading,
                onSubmit: handlePasswordChange
            )
        }
    }
    
    private func handleLogin() {
        // Validate input
        guard isValidLoginInput else {
            errorMessage = "Please enter valid credentials"
            showError = true
            return
        }
        
        // Show loading state
        isLoading = true
        
        Task {
            do {
                print("Attempting to login with doctorId: \(doctorId)")
                let supabase = SupabaseController.shared
                
                // Query the doctors table to find the matching doctor
                let doctorData = try await supabase.select(
                    from: "doctors",
                    where: "id",
                    equals: doctorId
                )
                
                guard let doctorInfo = doctorData.first else {
                    await MainActor.run {
                        errorMessage = "Doctor ID not found"
                        showError = true
                        isLoading = false // Reset loading state
                    }
                    return
                }
                
                print("Found doctor: \(doctorInfo)")
                
                // Verify password
                guard let storedPassword = doctorInfo["password"] as? String,
                      storedPassword == password else {
                    await MainActor.run {
                        errorMessage = "Invalid password"
                        showError = true
                        isLoading = false // Reset loading state
                    }
                    return
                }
                
                // Check doctor status
                guard let status = doctorInfo["doctor_status"] as? String,
                      status == "active" else {
                    await MainActor.run {
                        errorMessage = "Your account is not active. Please contact the hospital administrator."
                        showError = true
                        isLoading = false // Reset loading state
                    }
                    return
                }
                
                // Store doctor information in UserDefaults
                UserDefaults.standard.set(doctorId, forKey: "current_doctor_id")
                UserDefaults.standard.set("doctor", forKey: "userRole")
                
                // Check if first time login
                if let isFirstTimeLogin = doctorInfo["is_first_time_login"] as? Bool, isFirstTimeLogin {
                    // Show password change sheet for first time login
                    await MainActor.run {
                        showChangePasswordSheet = true
                        isLoading = false // Reset loading state
                    }
                } else {
                    // Update login timestamp
                    try? await supabase.update(
                        table: "doctors",
                        data: ["login_in_at": ISO8601DateFormatter().string(from: Date())],
                        where: "id",
                        equals: doctorId
                    )
                    
                    // Navigate to home screen
                    await MainActor.run {
                        isLoading = false // Reset loading state
                        isLoggedIn = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Login failed: \(error.localizedDescription)"
                    showError = true
                    isLoading = false // Reset loading state
                    print("Login error: \(error)")
                }
            }
        }
    }
    
    private func handlePasswordChange() {
        guard isValidPasswordChange else {
            errorMessage = "Invalid password format"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let supabase = SupabaseController.shared
                
                // Update password and set first-time login to false
                try await supabase.update(
                    table: "doctors",
                    data: [
                        "password": newPassword,
                        "is_first_time_login": "false", // Convert Boolean to String
                        "login_in_at": ISO8601DateFormatter().string(from: Date())
                    ],
                    where: "id",
                    equals: doctorId
                )
                
                await MainActor.run {
                    isLoading = false // Reset loading state
                    showChangePasswordSheet = false
                    isLoggedIn = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update password: \(error.localizedDescription)"
                    showError = true
                    isLoading = false // Reset loading state
                    print("Password update error: \(error)")
                }
            }
        }
    }
    
    private func isValidAdminId(_ id: String) -> Bool {
        let adminIdRegex = #"^DOC\d{3}$"#
        return NSPredicate(format: "SELF MATCHES %@", adminIdRegex).evaluate(with: id)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // The regex matches the constraint from the Supabase table:
        // "Password must be at least 8 characters and contain at least one uppercase letter, 
        // one lowercase letter, one number, and one special character"
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
}

// Change Password Sheet
struct ChangePasswordSheets: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @State private var isNewPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    var isValidInput: Bool
    var isLoading: Bool
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
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                        Text("Updating...")
                            .font(.title3)
                            .fontWeight(.semibold)
                    } else {
                        Text("Submit")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(
                    LinearGradient(gradient: Gradient(colors: [
                        (!isLoading && isValidInput) ? Color.teal : Color.gray.opacity(0.5),
                        (!isLoading && isValidInput) ? Color.teal.opacity(0.8) : Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing)
                )
                .cornerRadius(15)
                .shadow(color: (!isLoading && isValidInput) ? .teal.opacity(0.3) : .gray.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .disabled(!isValidInput || isLoading)
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


#Preview {
    NavigationStack {
        DoctorLoginView()
    }
}
