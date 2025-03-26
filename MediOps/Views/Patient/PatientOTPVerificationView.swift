import SwiftUI

struct PatientOTPVerificationView: View {
    @State private var otpInput = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            Text("Enter OTP")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            TextField("Enter 6-digit OTP", text: $otpInput)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .bold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .onChange(of: otpInput) { newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        otpInput = String(newValue.prefix(6))
                    }
                    // Only allow digits
                    otpInput = newValue.filter { "0123456789".contains($0) }
                }
                .padding(.horizontal)

            Button(action: verifyOTP) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify OTP")
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
                    otpInput.count == 6 ?
                    LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                   startPoint: .leading,
                                   endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray]),
                                       startPoint: .leading,
                                       endPoint: .trailing)
                )
                .cornerRadius(15)
                .shadow(color: otpInput.count == 6 ? .teal.opacity(0.3) : .gray.opacity(0.3), radius: 5, x: 0, y: 5)
            }
            .disabled(isLoading || otpInput.count != 6)
            .padding(.horizontal)
            .padding(.top, 10)

            // Resend OTP
        }
    }

    private func verifyOTP() {
        // Implementation of verifyOTP function
    }
}

struct PatientOTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        PatientOTPVerificationView()
    }
} 