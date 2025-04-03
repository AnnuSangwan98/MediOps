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
    @ObservedObject private var themeManager = ThemeManager.shared
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
    @State private var refreshID = UUID() // For UI refresh on theme change
    
    private let bookingFee = 10.0
    private let consultationFee = 500.0
    private let premiumFee = 200.0
    private let genderOptions = ["Male", "Female", "Other"]
    
    var totalAmount: Double {
        let baseAmount = consultationFee + bookingFee
        return isPremium ? baseAmount + premiumFee : baseAmount
    }
    
    var body: some View {
        ZStack {
            // Apply themed background
            if themeManager.isPatient {
                themeManager.currentTheme.background
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Doctor info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.title3)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            Text(doctor.specialization)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                    }
                    .padding()
                    
                    // Appointment details
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointment")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .primary)
                            Text(appointmentDate.formatted(date: .long, time: .omitted))
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .primary)
                            Text("\(startTime) to \(endTime)")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        }
                        
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .primary)
                            Text("Appointment Slot ID: \(slotId)")
                                .font(.caption)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                        
                        // For debugging - can be removed in production
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .primary)
                            Text("Raw times: \(rawStartTime) to \(rawEndTime)")
                                .font(.caption)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                    }
                    .padding()
                    
                    // Patient info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Patient info")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        
                        Text("Note: You can describe your health concerns or any relevant details in the text field below.")
                            .font(.caption)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        
                        TextField("Enter your health concerns...", text: $healthConcerns)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
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
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            }
                        }
                        .tint(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        .onChange(of: isPremium) { newValue in
                            if newValue {
                                showPremiumAlert = true
                            }
                        }
                        
                        if isPremium {
                            Text("Priority access for appointments and lab reports")
                                .font(.caption)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                    }
                    .padding()
                    .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
                    .cornerRadius(12)
                    .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .gray.opacity(0.1), radius: 5)
                    
                    // Payment details
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Payment Details")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Consultation fees:")
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                                Spacer()
                                Text("Rs.\(Int(consultationFee))")
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            }
                            
                            HStack {
                                Text("Booking fee")
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                                Spacer()
                                Text("Rs.\(Int(bookingFee))")
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            }
                            
                            if isPremium {
                                HStack {
                                    Text("Premium fee")
                                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                                    Spacer()
                                    Text("Rs.\(Int(premiumFee))")
                                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Pay")
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                                Spacer()
                                Text("Rs.\(Int(totalAmount))")
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
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
            
            // Pay button at the bottom
            VStack {
                Spacer()
                
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
                            .background(themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.2) : Color.teal.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
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
        .onAppear {
            // Setup theme change listener
            setupThemeChangeListener()
        }
        .id(refreshID) // Force refresh when ID changes
    }
    
    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Generate new ID to force view refresh
            refreshID = UUID()
        }
    }
}
