import SwiftUI

struct BloodDonationRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isTermsAccepted = false
    @State private var showRegistrationCard = false
    @Binding var isRegistered: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Blood Donation Registration")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    // Terms and Conditions
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Blood Donation Terms & Conditions")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TermRow(text: "You must be at least 18 years old and in good health.")
                            TermRow(text: "Minimum weight: 50kg (110 lbs).")
                            TermRow(text: "No blood donation in the last 3 months.")
                            TermRow(text: "No recent infections, surgeries, or chronic illnesses.")
                            TermRow(text: "No high-risk behaviors affecting blood safety.")
                            TermRow(text: "You must pass the health screening before donation.")
                        }
                        
                        Text("By proceeding, you confirm that you meet the above conditions.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Terms Acceptance
                    Toggle(isOn: $isTermsAccepted) {
                        Text("I accept the terms and conditions")
                            .font(.subheadline)
                    }
                    .padding(.top)
                    
                    // Register Button
                    Button(action: {
                        if isTermsAccepted {
                            showRegistrationCard = true
                        }
                    }) {
                        Text("Register")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isTermsAccepted ? Color.teal : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isTermsAccepted)
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRegistrationCard) {
                RegistrationSuccessView(isRegistered: $isRegistered, dismiss: dismiss)
            }
        }
    }
}

struct TermRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.teal)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct RegistrationSuccessView: View {
    @Binding var isRegistered: Bool
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Registration Successful!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Thank you for registering as a blood donor. Your information has been saved in our database.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button("Done") {
                isRegistered = true
                dismiss()
            }
            .padding()
            .background(Color.teal)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    BloodDonationRegistrationView(isRegistered: .constant(false))
} 