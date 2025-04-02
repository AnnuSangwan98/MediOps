import SwiftUI

struct PaymentFinalView: View {
    let doctor: HospitalDoctor
    let appointmentDate: Date
    let appointmentTime: Date
    let slotId: Int
    let startTime: String
    let endTime: String
    let rawStartTime: String
    let rawEndTime: String
    let isPremium: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToSuccess = false
    @State private var sliderOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isProcessing = false
    @State private var bookingError: String? = nil
    
    private let maxSliderOffset: CGFloat = 300 // Adjust this value based on your needs
    private let consultationFee = 500.0 // Default consultation fee
    private let bookingFee = 10.0
    private let premiumFee = 200.0
    
    private var totalAmount: Double {
        let baseAmount = consultationFee + bookingFee
        return isPremium ? baseAmount + premiumFee : baseAmount
    }
    
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
                        
                        if isPremium {
                            HStack {
                                Text("Premium fee")
                                    .foregroundColor(.teal)
                                Spacer()
                                Text("Rs.\(Int(premiumFee))")
                                    .foregroundColor(.teal)
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
                        Text("Rs.\(Int(totalAmount))")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                .padding()
                
                Spacer()
                
                if let error = bookingError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Sliding confirmation button
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 60)
                    
                    HStack {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 50, height: 50)
                            .padding(.leading, 5)
                            .offset(x: sliderOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if isProcessing { return }
                                        isDragging = true
                                        let newOffset = value.translation.width
                                        sliderOffset = min(max(0, newOffset), maxSliderOffset - 60)
                                    }
                                    .onEnded { value in
                                        if isProcessing { return }
                                        isDragging = false
                                        if sliderOffset > maxSliderOffset * 0.6 {
                                            withAnimation {
                                                sliderOffset = maxSliderOffset - 60
                                                processPayment()
                                            }
                                        } else {
                                            withAnimation {
                                                sliderOffset = 0
                                            }
                                        }
                                    }
                            )
                            .overlay(
                                Group {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                        
                        Spacer()
                    }
                    
                    Text(isProcessing ? "Processing..." : "Swipe to Pay")
                        .foregroundColor(.teal)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 60)
                .padding()
                .disabled(isProcessing)
            }
            .navigationBarItems(trailing: Button("✕") { dismiss() })
            .navigationDestination(isPresented: $navigateToSuccess) {
                BookingSuccessView(
                    doctor: doctor,
                    appointmentDate: appointmentDate,
                    startTime: startTime,
                    endTime: endTime, 
                    rawStartTime: rawStartTime,
                    rawEndTime: rawEndTime,
                    isPremium: isPremium
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
    
    private func processPayment() {
        isProcessing = true
        bookingError = nil
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Here you would handle the actual payment and appointment creation
            // Make sure to use rawStartTime and rawEndTime for database storage
            createAppointment()
        }
    }
    
    private func createAppointment() {
        // Use the rawStartTime and rawEndTime for creating the appointment in database
        // This ensures consistency between what's displayed and what's stored
        
        Task {
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: appointmentDate)
                
                // Prepare appointment data
                let appointmentData: [String: Any] = [
                    "doctor_id": doctor.id,
                    "hospital_id": doctor.hospitalId,
                    "appointment_date": dateString,
                    "slot_id": slotId,
                    "slot_start_time": rawStartTime,  // Use raw time for database
                    "slot_end_time": rawEndTime,      // Use raw time for database
                    "is_premium": isPremium,
                    "status": "upcoming",
                    "payment_status": "completed",
                    "payment_amount": totalAmount
                ]
                
                // Insert appointment into database
                let supabase = SupabaseController.shared
                _ = try await supabase.insert(into: "appointments", values: appointmentData)
                
                // Success! Navigate to success screen
                DispatchQueue.main.async {
                    isProcessing = false
                    navigateToSuccess = true
                }
                
            } catch {
                // Handle error
                DispatchQueue.main.async {
                    isProcessing = false
                    bookingError = "Failed to create appointment: \(error.localizedDescription)"
                    withAnimation {
                        sliderOffset = 0
                    }
                }
            }
        }
    }
} 