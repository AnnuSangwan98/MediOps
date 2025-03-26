//
//  PatientOTPVerificationView.swift
//  MediOps
//
//  Created by Sharvan on 18/03/25.
//

import SwiftUI
import Combine

struct PatientOTPVerificationView: View {
    let email: String
    @State private var currentOTP: String
    @EnvironmentObject private var navigationState: AppNavigationState
    
    @State private var otpInput: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var isLoading = false
    @State private var isResending = false
    @State private var isVerified = false
    @State private var navigateToHome = false
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // Create a default profile controller
    private let profileController = PatientProfileController()
    
    @ObservedObject private var viewModel = HospitalViewModel.shared
    
    @State private var selectedDate: Date = Date()
    
    init(email: String, expectedOTP: String) {
        self.email = email
        self._currentOTP = State(initialValue: expectedOTP)
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
                    
                    TextField("Enter 6-digit OTP", text: $otpInput)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: otpInput) { newValue in
                            otpInput = String(newValue.prefix(6)).filter { "0123456789".contains($0) }
                        }
                    
                    HStack {
                        Text("Resend OTP in \(timeRemaining)s")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if timeRemaining == 0 {
                            Button("Resend OTP") {
                                resendOTP()
                            }
                            .font(.caption)
                            .foregroundColor(.teal)
                        }
                    }
                    
                    Button(action: verifyOTP) {
                        HStack {
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
                    .disabled(otpInput.count != 6 || isLoading)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.teal)
                Text("Back")
                    .foregroundColor(.teal)
            }
        })
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                if isVerified {
                    // Set root view to HomeTabView
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: HomeTabView())
                    }
                }
            }
        } message: {
            Text(successMessage)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func verifyOTP() {
        guard otpInput.count == 6 else {
            errorMessage = "Please enter a valid 6-digit OTP"
            showError = true
            return
        }
        
        if otpInput == currentOTP {
            isLoading = true
            Task {
                do {
                    let isValid = EmailService.shared.verifyOTP(email: email, otp: otpInput)
                    
                    await MainActor.run {
                        isLoading = false
                        isVerified = true
                        successMessage = "Verification successful!"
                        showSuccess = true
                        navigationState.signIn(as: .patient)
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Verification failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        } else {
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
    
    private func resendOTP() {
        isResending = true
        startTimer()
        
        Task {
            do {
                let newOTP = try await EmailService.shared.sendOTP(to: email, role: "Patient")
                await MainActor.run {
                    currentOTP = newOTP
                    successMessage = "OTP resent successfully"
                    showSuccess = true
                    isResending = false
                    otpInput = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to resend OTP: \(error.localizedDescription)"
                    showError = true
                    isResending = false
                }
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

