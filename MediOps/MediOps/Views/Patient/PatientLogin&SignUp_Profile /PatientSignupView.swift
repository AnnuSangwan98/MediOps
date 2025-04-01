import SwiftUI

struct PatientSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Not Specified"
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToOTP = false
    @State private var suggestedPassword: String? = nil
    @State private var currentOTP: String = ""
    @State private var isLoading = false
    
    let genders = ["Not Specified", "Male", "Female", "Other"]
    
    private var isValidName: Bool {
        let nameRegex = "^[A-Za-z\\s]+$"
        let namePred = NSPredicate(format:"SELF MATCHES %@", nameRegex)
        return namePred.evaluate(with: name)
    }
        
    private var isValidAge: Bool {
        if let ageNum = Int(age) {
            return ageNum > 0 && ageNum < 200
        }
        return false
    }
        
    private var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPred.evaluate(with: password)
    }
    
    // MARK: - Validation
    
    private func validateAndShowError() -> Bool {
        // Check all validation conditions
        if name.isEmpty {
            errorMessage = "Name cannot be empty"
            showError = true
            return false
        }
        
        if !isValidName {
            errorMessage = "Name can only contain letters and spaces"
            showError = true
            return false
        }
        
        if email.isEmpty {
            errorMessage = "Email cannot be empty"
            showError = true
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Password cannot be empty"
            showError = true
            return false
        }
        
        if !isValidPassword {
            errorMessage = "Password must be at least 8 characters with uppercase, lowercase, number and special character"
            showError = true
            return false
        }
        
        if confirmPassword.isEmpty {
            errorMessage = "Please confirm your password"
            showError = true
            return false
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return false
        }
        
        if age.isEmpty {
            errorMessage = "Age cannot be empty"
            showError = true
            return false
        }
        
        if !isValidAge {
            errorMessage = "Please enter a valid age"
            showError = true
            return false
        }
        
        if gender.isEmpty {
            errorMessage = "Please select a gender"
            showError = true
            return false
        }
        
        return true
    }

    private func isValidInput() -> Bool {
        // Only check validation conditions without modifying state
        if name.isEmpty || !isValidName { return false }
        if email.isEmpty || !isValidEmail(email) { return false }
        if password.isEmpty || !isValidPassword { return false }
        if confirmPassword.isEmpty || password != confirmPassword { return false }
        if age.isEmpty || !isValidAge { return false }
        if gender.isEmpty { return false }
        return true
    }
    
    private var isSubmitButtonEnabled: Bool {
        isValidInput()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func generateSuggestedPassword() -> String {
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialCharacters = "@$!%*?&"
        
        var password = ""
        password += String(uppercaseLetters.randomElement()!)
        password += String(lowercaseLetters.randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(specialCharacters.randomElement()!)
        
        let allCharacters = uppercaseLetters + lowercaseLetters + numbers
        for _ in 0..<4 {
            password += String(allCharacters.randomElement()!)
        }
        
        return String(password.shuffled())
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("Patient Details")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                        .padding(.top)
                    
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your full name", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                            if !name.isEmpty && !isValidName {
                                Text("Name should only contain letters and spaces")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Enter age", text: $age)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .frame(maxWidth: 120)
                            }
                            .frame(maxWidth: 120, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Menu {
                                    ForEach(genders, id: \.self) { genderOption in
                                        Button(action: {
                                            gender = genderOption
                                        }) {
                                            Text(genderOption)
                                                .foregroundColor(.black)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(gender)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 57)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !age.isEmpty && !isValidAge {
                            Text("Age must be between 1 and 199")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            if !email.isEmpty && !isValidEmail(email) {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 0)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Enter password", text: $password)
                                .textContentType(.newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Button(action: {
                                suggestedPassword = generateSuggestedPassword()
                            }) {
                                Text("Generate Strong Password")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                            }
                            .padding(.top, 4)
                            
                            if let suggested = suggestedPassword {
                                HStack {
                                    Text("Suggested: \(suggested)")
                                        .font(.caption)
                                        .foregroundColor(.teal)
                                    
                                    Button(action: {
                                        password = suggested
                                        confirmPassword = suggested
                                        suggestedPassword = nil
                                    }) {
                                        Text("Use")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.teal)
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            if !password.isEmpty {
                                if !isValidPassword {
                                    Text("Password must contain:")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 4)
                                    
                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Text("•")
                                            Text("8+ chars")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        
                                        HStack(spacing: 4) {
                                            Text("•")
                                            Text("Uppercase")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        
                                        HStack(spacing: 4) {
                                            Text("•")
                                            Text("Lowercase")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        
                                        HStack(spacing: 4) {
                                            Text("•")
                                            Text("Number")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                    .padding(.top, 2)
                                    
                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Text("•")
                                            Text("Special (@$!%*?&)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        Button(action: handleSignup) {
                            HStack {
                                Text("Proceed")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(
                                isSubmitButtonEnabled ?
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
                        .disabled(!isSubmitButtonEnabled)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 30)
                }
                NavigationLink(destination: PatientLoginView()) {
                    HStack {
                        Text("Already a user?")
                            .foregroundColor(.gray)
                        Text("Login here")
                            .foregroundColor(.teal)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToOTP) {
            PatientOTPVerificationView(email: email, expectedOTP: currentOTP)
        }
        if isLoading {
            ProgressView("Creating account...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
        }
    }
    
    private func handleSignup() {
        guard validateAndShowError() else { return }
        isLoading = true
        
        // Normalize email for consistency
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("SIGNUP VIEW: Starting signup process for email: \(normalizedEmail)")
        
        Task {
            do {
                // Try to register the patient with all required fields
                let (patient, _) = try await AuthService.shared.signUpPatient(
                    email: normalizedEmail,
                    password: password,
                    username: name,
                    age: Int(age) ?? 0,
                    gender: gender
                )
                
                print("SIGNUP VIEW: Patient registered successfully with ID: \(patient.id)")
                
                // Send OTP email to the user for verification
                do {
                    let otp = try await EmailService.shared.sendOTP(to: normalizedEmail, role: "Patient")
                    print("SIGNUP VIEW: OTP sent via email: \(otp) to: \(normalizedEmail)")
                    
                    // Update UI on main thread
                    await MainActor.run {
                        isLoading = false
                        currentOTP = otp
                        
                        // Navigate to OTP verification
                        navigateToOTP = true
                    }
                } catch {
                    print("SIGNUP VIEW: Failed to send OTP email: \(error.localizedDescription)")
                    
                    // Fallback to local OTP generation for testing purposes
                    let otp = String(Int.random(in: 100000...999999))
                    print("SIGNUP VIEW: Fallback to local OTP: \(otp) for email: \(normalizedEmail)")
                    
                    await MainActor.run {
                        isLoading = false
                        currentOTP = otp
                        
                        // Navigate to OTP verification
                        navigateToOTP = true
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    isLoading = false
                    
                    if error == AuthError.emailAlreadyExists {
                        errorMessage = "A user with this email already exists. Please login instead."
                    } else if error == AuthError.invalidUserData {
                        errorMessage = "Invalid user data provided. Please check your information."
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    // More detailed error for debugging
                    print("SIGNUP ERROR: \(error)")
                    
                    showError = true
                }
            } catch let error as NSError {
                await MainActor.run {
                    isLoading = false
                    
                    // Check for PostgreSQL unique constraint violation error
                    if error.localizedDescription.contains("violates unique constraint") {
                        errorMessage = "This email is already registered. Please login instead."
                        print("SIGNUP VIEW: Caught unique constraint violation, email already in use")
                    } else {
                        errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    }
                    
                    print("SIGNUP ERROR: Unexpected error: \(error)")
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    print("SIGNUP ERROR: Unknown error: \(error)")
                    showError = true
                }
            }
        }
    }
}
