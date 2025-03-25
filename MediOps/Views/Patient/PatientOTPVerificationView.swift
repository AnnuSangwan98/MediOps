import SwiftUI
import Combine

struct PatientOTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    let expectedOTP: String
    
    @State private var otp: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer? = nil
    @State private var navigateToHome = false
    @State private var isLoading = false
    
    private var isVerifyButtonEnabled: Bool {
        otp.count == 6
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                        
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                            .symbolEffect(.bounce, options: .repeating)
                    }
                    
                    Text("OTP Verification")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                VStack(spacing: 25) {
                    Text("Enter the verification code sent to")
                        .foregroundColor(.gray)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    TextField("Enter 6-digit OTP", text: $otp)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(otp.count == 6 ? Color.teal : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: otp) { newValue in
                            if newValue.count > 6 {
                                otp = String(newValue.prefix(6))
                            }
                            otp = newValue.filter { "0123456789".contains($0) }
                        }
                        .padding(.horizontal, 40)
                    
                    HStack {
                        if timeRemaining > 0 {
                            Text("Resend OTP in \(timeRemaining)s")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Button("Resend OTP") {
                                sendOtp(isResend: true)
                            }
                            .font(.caption)
                            .foregroundColor(.teal)
                        }
                        
                        Spacer()
                        
                        Text("Enter 6-digit verification code")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: handleOtpVerification) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            isVerifyButtonEnabled ? Color.teal : Color.gray.opacity(0.3),
                                            isVerifyButtonEnabled ? Color.teal.opacity(0.8) : Color.gray.opacity(0.2)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 55)
                                .shadow(color: isVerifyButtonEnabled ? Color.teal.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                            
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Verify OTP")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Image(systemName: "checkmark.circle")
                                        .font(.title3)
                                }
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .disabled(!isVerifyButtonEnabled || isLoading)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert(showError ? "Error" : "Success", isPresented: Binding(
            get: { showError || showSuccess },
            set: { newValue in
                showError = newValue && showError
                showSuccess = newValue && showSuccess
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(showError ? errorMessage : successMessage)
        }
        .onAppear {
            sendOtp()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .navigationDestination(isPresented: $navigateToHome) {
            PatientHomeView()
        }
    }
    
    private func sendOtp(isResend: Bool = false) {
        Task {
            do {
                let url = URL(string: "http://172.20.2.50:8082/send-email")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "to": email,
                    "role": "patient",
                    "otp": expectedOTP
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            startTimer()
                            if isResend {
                                successMessage = "OTP resent successfully"
                                showSuccess = true
                            }
                        } else {
                            errorMessage = "Failed to send OTP. Please try again."
                            showError = true
                        }
                    } else {
                        errorMessage = "Invalid server response. Please try again."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Network error. Please check your connection and try again."
                    showError = true
                }
            }
        }
    }
    
    private func handleOtpVerification() {
        if otp.count != 6 {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        isLoading = true
        
        // Verify OTP matches
        if otp == expectedOTP {
            successMessage = "OTP verified successfully!"
            showSuccess = true
            
            // Delay navigation to allow user to see success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
                navigateToHome = true
            }
        } else {
            isLoading = false
            errorMessage = "Invalid OTP. Please try again."
            showError = true
        }
    }
    
    private func startTimer() {
        timeRemaining = 30
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
    PatientOTPVerificationView(
        email: "test@example.com",
        expectedOTP: "123456"
    )
} 