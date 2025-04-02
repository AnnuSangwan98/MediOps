import SwiftUI

struct ReviewAndPayView: View {
    let doctor: HospitalDoctor
    let appointmentDate: Date
    let appointmentTime: Date
    let slotId: Int
    let startTime: String
    let endTime: String
    let rawStartTime: String
    let rawEndTime: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var promoCode = ""
    @State private var showConfirmation = false
    @State private var showPaymentConfirmation = false
    @State private var selectedPatient = "Myself"
    @State private var showPatientSelector = false
    @State private var otherPatientName = ""
    @State private var otherPatientAge = ""
    @State private var otherPatientGender = "Male"
    @State private var healthConcerns = ""
    @State private var isPremium = false
    @State private var showPremiumAlert = false
    
    private let bookingFee = 10.0
    private let consultationFee = 500.0
    private let premiumFee = 200.0
    private let genderOptions = ["Male", "Female", "Other"]
    
    var totalAmount: Double {
        let baseAmount = consultationFee + bookingFee
        return isPremium ? baseAmount + premiumFee : baseAmount
    }
    
    var body: some View {
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
                        Text("\(startTime) to \(endTime)")
                    }
                    
                    HStack {
                        Image(systemName: "tag")
                        Text("Appointment Slot ID: \(slotId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // For debugging - can be removed in production
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Raw times: \(rawStartTime) to \(rawEndTime)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                // Patient info
                VStack(alignment: .leading, spacing: 10) {
                    Text("Patient info")
                        .font(.headline)
                    
                    Text("Note: You can describe your health concerns or any relevant details in the text field below.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Enter your health concerns...", text: $healthConcerns)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Premium Switch
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $isPremium) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Premium Appointment")
                                .fontWeight(.medium)
                        }
                    }
                    .tint(.teal)
                    .onChange(of: isPremium) { newValue in
                        if newValue {
                            showPremiumAlert = true
                        }
                    }
                    
                    if isPremium {
                        Text("Priority access for appointments and lab reports")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                
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
                        
                        if isPremium {
                            HStack {
                                Text("Premium fee")
                                Spacer()
                                Text("Rs.\(Int(premiumFee))")
                            }
                            .foregroundColor(.teal)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Pay")
                                .fontWeight(.bold)
                            Spacer()
                            Text("Rs.\(Int(totalAmount))")
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Review & Pay")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Premium Appointment", isPresented: $showPremiumAlert) {
            Button("Continue", role: .none) {
                // Keep premium enabled
            }
            Button("Cancel", role: .cancel) {
                isPremium = false
            }
        } message: {
            Text("By enabling it you will get the priority in appointment and lab reports")
        }
        
        // Pay button
        Button(action: {
            // Validate other patient details if needed
            if selectedPatient == "Other" {
                if otherPatientName.isEmpty || otherPatientAge.isEmpty {
                    return // Add proper validation alert here
                }
            }
            showConfirmation = true
        }) {
            HStack {
                Text("Pay")
                Text("Rs.\(Int(totalAmount))")
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
            PaymentFinalView(
                doctor: doctor,
                appointmentDate: appointmentDate,
                appointmentTime: appointmentTime,
                slotId: slotId,
                startTime: startTime,
                endTime: endTime,
                rawStartTime: rawStartTime,
                rawEndTime: rawEndTime,
                isPremium: isPremium
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
}
