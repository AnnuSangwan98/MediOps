import SwiftUI

struct ReviewAndPayView: View {
    let doctor: Doctor
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var promoCode = ""
    @State private var showConfirmation = false
    @State private var showPaymentConfirmation = false
    
    private let bookingFee = 10.0
    private let consultationFee = 500.0 // Default consultation fee
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Doctor info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.title3)
                            Text(doctor.specialization)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // Appointment details
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointment")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(appointmentDate.formatted(date: .long, time: .omitted))
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                            Text(appointmentTime.formatted(date: .omitted, time: .shortened))
                        }
                    }
                    .padding()
                    
                    // Patient info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Patient info")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                )
                            
                            Text("Myself")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        
                        Text("Note: You can describe your health concerns or any relevant details in the text field below.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your health concerns...", text: .constant(""))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()

                    .padding()
                    
                    // Payment details
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Payment Details")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Consultation fees:")
                                Spacer()
                                Text("Rs.\(Int(consultationFee))")
                            }
                            
                            HStack {
                                Text("Booking fee")
                                Spacer()
                                Text("Rs.\(Int(bookingFee))")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Pay")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Rs.\(Int(consultationFee + bookingFee))")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Review & Pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            
            // Pay button
            Button(action: { showConfirmation.toggle() }) {
                HStack {
                    Text("Pay")
                    Text("Rs.\(Int(consultationFee + bookingFee))")
                        .padding(.horizontal, 8)
                        .background(Color.teal.opacity(0.2))
                        .cornerRadius(4)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.teal)
                .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $showConfirmation) {
                PaymentFinalView(doctor: doctor, appointmentDate: appointmentDate, appointmentTime: appointmentTime)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
}
