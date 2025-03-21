import SwiftUI

struct PatientSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Male"
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToOTP = false
    @State private var suggestedPassword: String? = nil
    @State private var currentOTP: String = ""
    @State private var isLoading = false
    
    let genders = ["Male", "Female", "Other"]
    
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
        
    private var isSubmitButtonEnabled: Bool {
        !name.isEmpty && isValidName &&
        !age.isEmpty && isValidAge &&
        !email.isEmpty && isValidEmail &&
        isValidPassword && confirmPassword == password
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
                            
                            if !email.isEmpty && !isValidEmail {
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
    
    private var isValidEmail: Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func handleSignup() {
        guard isSubmitButtonEnabled else { return }
        isLoading = true
        
        // Normalize email by trimming whitespace and converting to lowercase
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("Registering new patient with email: \(normalizedEmail)")
        
        Task {
            do {
                // First check if user already exists
                let userExists = try await UserController.shared.checkUserExists(email: normalizedEmail)
                
                if userExists {
                    print("DEBUG: User already exists with this email. Cannot register.")
                    throw AuthError.emailAlreadyExists
                }
                
                let (patient, token) = try await AuthService.shared.signUpPatient(
                    email: normalizedEmail,
                    password: password,
                    username: name,
                    age: Int(age) ?? 0,
                    gender: gender
                )
                
                print("Successfully registered patient with ID: \(patient.id)")
                
                // Verify user was created successfully
                let verifyUser = try await UserController.shared.checkUserExists(email: normalizedEmail)
                print("DEBUG: After registration, user exists check: \(verifyUser)")
                
                let otp = try await EmailService.shared.sendOTP(
                    to: normalizedEmail,
                    role: "patient"
                )
                
                print("OTP sent: \(otp)")
                
                await MainActor.run {
                    isLoading = false
                    currentOTP = otp
                    navigateToOTP = true
                }
            } catch {
                print("Registration error: \(error.localizedDescription)")
                
                if let authError = error as? AuthError, authError == AuthError.emailAlreadyExists {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "An account with this email already exists. Please log in instead."
                        showError = true
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Failed to create account: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        }
    }
}
