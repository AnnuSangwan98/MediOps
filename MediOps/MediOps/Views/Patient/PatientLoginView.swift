import SwiftUI

struct PatientLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mobileNumber: String = ""
    @State private var otp: String = ""
    @State private var isOtpSent: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var timeRemaining: Int = 60
    @State private var timer: Timer? = nil
    @State private var navigateToHome = false
    
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
                        
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Patient Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Mobile Number field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mobile Number")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("+91")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            TextField("Enter mobile number", text: $mobileNumber)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                        }
                        .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    if isOtpSent {
                        // OTP field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter OTP")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter 6-digit OTP", text: $otp)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            HStack {
                                Text("Resend OTP in \(timeRemaining)s")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                if timeRemaining == 0 {
                                    Button("Resend OTP") {
                                        sendOtp()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.teal)
                                }
                            }
                        }
                    }
                    
                    // Action Button
                    Button(action: isOtpSent ? handleOtpVerification : sendOtp) {
                        HStack {
                            Text(isOtpSent ? "Verify OTP" : "Send OTP")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Image(systemName: isOtpSent ? "checkmark.circle" : "arrow.right")
                                .font(.title3)
                        }
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
                    .padding(.top, 10)
                }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Login Navigation Link
                    NavigationLink(destination: PatientSignupView()) {
                        HStack {
                            Text("Not a user?")
                                .foregroundColor(.gray)
                            Text("SignUp here")
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
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .navigationDestination(isPresented: $navigateToHome) {
            PatientHomeView()
        }
    }
    
    private func sendOtp() {
        // Validate mobile number
        if mobileNumber.count != 10 {
            errorMessage = "Please enter a valid 10-digit mobile number"
            showError = true
            return
        }
        
        // TODO: Implement actual OTP sending logic
        isOtpSent = true
        startTimer()
    }
    
    private func handleOtpVerification() {
        // Validate OTP
        if otp.count != 6 {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        // TODO: Implement actual OTP verification logic
        navigateToHome = true
    }
    
    private func startTimer() {
        timeRemaining = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PatientLoginView()
    }
} 
