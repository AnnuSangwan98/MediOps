import SwiftUI

struct PaymentConfirmationView: View {
    let doctor: DoctorDetail
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Confirm Payment")
                    .font(.title2)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.teal)
                        Text("Pay with")
                        Spacer()
                        Text("•••• 5941")
                        Button("Change") {}
                            .foregroundColor(.teal)
                    }
                    
                    Divider()
                    
                    Text("Bill Details")
                        .font(.headline)
                    
                    Group {
                        HStack {
                            Text("Consultation fees:")
                            Spacer()
                            Text("$\(Int(doctor.consultationFee))")
                        }
                        
                        HStack {
                            Text("Booking fee")
                            Spacer()
                            Text("$10")
                        }
                        
                        if showSuccess {
                            HStack {
                                Text("Promo applied")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("-$3")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.gray)
                    
                    Text("This booking will be charged in USD (USD 207) Contact the bank directly for their policies regarding currency conversion and applicable foreign transaction fees.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical)
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Text("(Incl. VAT)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("$207")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding()
                
                Spacer()
                
                // Swipe to pay button
                Button(action: { showSuccess.toggle() }) {
                    HStack {
                        Image(systemName: "chevron.right.2")
                        Text("Swipe to Pay")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("✕") { dismiss() })
            .sheet(isPresented: $showSuccess) {
                BookingSuccessView(doctor: doctor, appointmentDate: appointmentDate, appointmentTime: appointmentTime)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
}
