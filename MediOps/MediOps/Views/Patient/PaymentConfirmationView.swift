import SwiftUI

struct PaymentConfirmationView: View {
    let doctor: DoctorDetail
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var selectedPaymentMethod: PaymentMethod = .upiCard
    @State private var showPaymentSheet = false
    
    enum PaymentMethod {
        case upiCard
        case payLater
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Payment Method")
                    .font(.title2)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    // Payment Method Selection
                    VStack(spacing: 15) {
                        Button(action: { selectedPaymentMethod = .upiCard }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.teal)
                                Text("UPI / Card")
                                    .foregroundColor(.black)
                                Spacer()
                                if selectedPaymentMethod == .upiCard {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.teal)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                        
                        Button(action: { selectedPaymentMethod = .payLater }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.teal)
                                Text("Pay Later")
                                    .foregroundColor(.black)
                                Spacer()
                                if selectedPaymentMethod == .payLater {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.teal)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                    }
                    
                    Divider()
                    
                    Text("Bill Details")
                        .font(.headline)
                    
                    Group {
                        HStack {
                            Text("Consultation fees:")
                            Spacer()
                            Text("Rs.\(Int(doctor.consultationFee))")
                        }
                        
                        HStack {
                            Text("Booking fee")
                            Spacer()
                            Text("Rs.10")
                        }
                        
                        if showSuccess {
                            HStack {
                                Text("Promo applied")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("Rs. -3")
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
                        Text("Rs.207")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding()
                
                Spacer()
                
                // Pay Button
                Button(action: {
                    if selectedPaymentMethod == .upiCard {
                        showPaymentSheet = true
                    } else {
                        showSuccess = true
                    }
                }) {
                    Text(selectedPaymentMethod == .upiCard ? "Pay Now" : "Confirm Pay Later")
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
            .sheet(isPresented: $showPaymentSheet) {
                PaymentSheetView(doctor: doctor, appointmentDate: appointmentDate, appointmentTime: appointmentTime)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
}

struct PaymentSheetView: View {
    let doctor: DoctorDetail
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var selectedPaymentType: PaymentType = .upi
    
    enum PaymentType {
        case upi
        case card
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Payment Type")
                    .font(.title2)
                    .padding(.top)
                
                VStack(spacing: 15) {
                    Button(action: { selectedPaymentType = .upi }) {
                        HStack {
                            Image(systemName: "iphone.fill")
                                .foregroundColor(.teal)
                            Text("UPI")
                                .foregroundColor(.black)
                            Spacer()
                            if selectedPaymentType == .upi {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                    
                    Button(action: { selectedPaymentType = .card }) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.teal)
                            Text("Card")
                                .foregroundColor(.black)
                            Spacer()
                            if selectedPaymentType == .card {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.1), radius: 5)
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: { showSuccess = true }) {
                    Text("Pay Rs.207")
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
    }
}
