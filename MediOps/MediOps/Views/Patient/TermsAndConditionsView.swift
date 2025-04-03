import SwiftUI

struct TermsAndConditionsView: View {
    @Binding var isAccepted: Bool
    let onAccept: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Terms and Conditions")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    
                    // Terms Content
                    VStack(alignment: .leading, spacing: 15) {
                        Text("By registering as a blood donor, you agree to:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TermRow(text: "Provide accurate personal and medical information")
                            TermRow(text: "Be available for blood donation when contacted")
                            TermRow(text: "Maintain good health practices")
                            TermRow(text: "Notify us of any changes in your health status")
                            TermRow(text: "Follow pre-donation guidelines")
                        }
                        .padding(.leading)
                        
                        Text("Important Notes:")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TermRow(text: "Your information will be kept confidential")
                            TermRow(text: "You can cancel your registration at any time")
                            TermRow(text: "You will be notified only when your blood type is needed")
                        }
                        .padding(.leading)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            onAccept(true)
                            dismiss()
                        }) {
                            Text("I Accept")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            onAccept(false)
                            dismiss()
                        }) {
                            Text("Decline")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onAccept(false)
                        dismiss()
                    }
                }
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
                .font(.system(size: 16))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    TermsAndConditionsView(isAccepted: .constant(false)) { _ in }
} 