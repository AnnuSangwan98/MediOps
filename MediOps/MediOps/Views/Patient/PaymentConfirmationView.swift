import SwiftUI

struct PaymentFinalView: View {
    let doctor: Doctor
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccess = false
    @State private var sliderOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let maxSliderOffset: CGFloat = 300 // Adjust this value based on your needs
    private let consultationFee = 500.0 // Default consultation fee
    private let bookingFee = 10.0
    
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
                            Text("Rs.\(Int(consultationFee))")
                        }
                        
                        HStack {
                            Text("Booking fee")
                            Spacer()
                            Text("Rs.\(Int(bookingFee))")
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
                        Text("Rs.\(Int(consultationFee + bookingFee))")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding()
                
                Spacer()
                
                // Sliding confirmation button
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.teal.opacity(0.2))
                        .frame(height: 60)
                    
                    // Slider button
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.teal)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        )
                        .offset(x: sliderOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    let newOffset = sliderOffset + value.translation.width
                                    sliderOffset = min(max(0, newOffset), maxSliderOffset)
                                }
                                .onEnded { value in
                                    isDragging = false
                                    if sliderOffset >= maxSliderOffset - 20 {
                                        withAnimation {
                                            sliderOffset = maxSliderOffset
                                            showSuccess = true
                                        }
                                    } else {
                                        withAnimation {
                                            sliderOffset = 0
                                        }
                                    }
                                }
                        )
                    
                    // Text
                    Text("Swipe to Pay")
                        .foregroundColor(.teal)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 60)
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
