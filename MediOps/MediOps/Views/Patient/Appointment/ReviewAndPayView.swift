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
    @ObservedObject private var translationManager = TranslationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
                        .fill(themeManager.colors.primary)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(doctor.name)
                            .font(.title3)
                            .foregroundColor(themeManager.colors.text)
                        Text(doctor.specialization)
                            .foregroundColor(themeManager.colors.subtext)
                    }
                }
                .padding()
                
                // Appointment details
                VStack(alignment: .leading, spacing: 10) {
                    Text("appointment".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(themeManager.colors.primary)
                        Text(appointmentDate.formatted(date: .long, time: .omitted))
                            .foregroundColor(themeManager.colors.text)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(themeManager.colors.primary)
                        Text("\(startTime) to \(endTime)")
                            .foregroundColor(themeManager.colors.text)
                    }
                    
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(themeManager.colors.primary)
                        Text("Appointment Slot ID: \(slotId)")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.subtext)
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(themeManager.colors.primary)
                        Text("Raw times: \(rawStartTime) to \(rawEndTime)")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.subtext)
                    }
                }
                .padding()
                
                // Patient info
                VStack(alignment: .leading, spacing: 10) {
                    Text("patient_info".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("Note: You can describe your health concerns or any relevant details in the text field below.")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.subtext)
                    
                    TextField("Enter your health concerns...", text: $healthConcerns)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(themeManager.colors.text)
                }
                .padding()
                
                // Premium Switch
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $isPremium) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("premium_appointment".localized)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.colors.text)
                        }
                    }
                    .tint(themeManager.colors.primary)
                    .onChange(of: isPremium) { newValue in
                        if newValue {
                            showPremiumAlert = true
                        }
                    }
                    
                    if isPremium {
                        Text("Priority access for appointments and lab reports")
                            .font(.caption)
                            .foregroundColor(themeManager.colors.subtext)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: themeManager.colors.primary.opacity(0.1), radius: 5)
                
                // Payment details
                VStack(alignment: .leading, spacing: 15) {
                    Text("payment_details".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    VStack(spacing: 10) {
                        HStack {
                            Text("consultation_fees".localized)
                                .foregroundColor(themeManager.colors.text)
                            Spacer()
                            Text("Rs.\(Int(consultationFee))")
                                .foregroundColor(themeManager.colors.text)
                        }
                        
                        HStack {
                            Text("booking_fee".localized)
                                .foregroundColor(themeManager.colors.text)
                            Spacer()
                            Text("Rs.\(Int(bookingFee))")
                                .foregroundColor(themeManager.colors.text)
                        }
                        
                        if isPremium {
                            HStack {
                                Text("premium_fee".localized)
                                    .foregroundColor(themeManager.colors.primary)
                                Spacer()
                                Text("Rs.\(Int(premiumFee))")
                                    .foregroundColor(themeManager.colors.primary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("total_pay".localized)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.text)
                            Spacer()
                            Text("Rs.\(Int(totalAmount))")
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.text)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("review_and_pay".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("premium_appointment".localized, isPresented: $showPremiumAlert) {
            Button("continue".localized, role: .none) {}
            Button("cancel".localized, role: .cancel) {
                isPremium = false
            }
        } message: {
            Text("By enabling it you will get the priority in appointment and lab reports")
        }
        
        // Pay button
        Button(action: {
            if selectedPatient == "Other" {
                if otherPatientName.isEmpty || otherPatientAge.isEmpty {
                    return
                }
            }
            showConfirmation = true
        }) {
            HStack {
                Text("pay".localized)
                Text("Rs.\(Int(totalAmount))")
                    .padding(.horizontal, 8)
                    .background(themeManager.colors.primary.opacity(0.2))
                    .cornerRadius(4)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.colors.primary)
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
