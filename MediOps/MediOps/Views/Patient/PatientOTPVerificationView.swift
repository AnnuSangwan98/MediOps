import SwiftUI
import Combine

struct PatientOTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    
    let email: String
    let expectedOTP: String
    
    @State private var otpText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var isLoading = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining = 60
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.teal)
                
                Text("OTP Verification")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.teal)
                
                Text("Please enter the verification code sent to\n\(email)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 50)
            
            // OTP Input
            VStack(spacing: 15) {
                TextField("Enter 6-digit OTP", text: $otpText)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .onChange(of: otpText) { newValue in
                        if newValue.count > 6 {
                            otpText = String(newValue.prefix(6))
                        }
                    }
                    .textFieldStyle(CustomTextFieldStyle())
                    .frame(maxWidth: 200)
                
                // Timer and Resend Button
                HStack {
                    if timeRemaining > 0 {
                        Text("Resend OTP in \(timeRemaining)s")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Button(action: resendOTP) {
                            Text("Resend OTP")
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                    }
                }
            }
            
            // Verify Button
            Button(action: verifyOTP) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title3)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(
                    otpText.count == 6 ?
                    LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                   startPoint: .leading,
                                   endPoint: .trailing) :
                    LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .cornerRadius(15)
                .shadow(color: otpText.count == 6 ? .teal.opacity(0.3) : .gray.opacity(0.3),
                       radius: 5, x: 0, y: 5)
            }
            .disabled(otpText.count != 6 || isLoading)
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                // Sign in and navigate to patient home
                navigationState.signIn(as: .patient)
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func verifyOTP() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if otpText == expectedOTP {
                successMessage = "OTP verified successfully! You will be redirected to the home screen."
                showSuccess = true
            } else {
                errorMessage = "Invalid OTP. Please try again."
                showError = true
            }
            isLoading = false
        }
    }
    
    private func resendOTP() {
        Task {
            do {
                let newOTP = try await EmailService.shared.sendOTP(to: email, role: "Patient")
                print("New OTP sent: \(newOTP)")
                await MainActor.run {
                    timeRemaining = 60
                    timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to resend OTP. Please try again."
                    showError = true
                }
            }
        }
    }
}
