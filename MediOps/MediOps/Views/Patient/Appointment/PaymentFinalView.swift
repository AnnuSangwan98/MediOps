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
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var navigateToSuccess = false
    @State private var sliderOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isProcessing = false
    @State private var bookingError: String? = nil
    @State private var refreshID = UUID() // For UI refresh on theme change
    
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
            ZStack {
                // Apply themed background
                if themeManager.isPatient {
                    themeManager.currentTheme.background
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    Text("Confirm Payment")
                        .font(.title2)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                            Text("Pay with")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            Spacer()
                            Text("•••• 5941")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            Button("Change") {}
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        }
                        
                        Divider()
                        
                        Text("Bill Details")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        
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
                                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                                    Spacer()
                                    Text("Rs.\(Int(premiumFee))")
                                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                                }
                            }
                        }
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        
                        Text("This booking will be charged in USD (USD 207) Contact the bank directly for their policies regarding currency conversion and applicable foreign transaction fees.")
                            .font(.caption)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            .padding(.vertical)
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            Text("(Incl. VAT)")
                                .font(.caption)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            Spacer()
                            Text("Rs.\(Int(totalAmount))")
                                .font(.headline)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        }
                    }
                    .padding()
                    .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
                    .cornerRadius(12)
                    .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .gray.opacity(0.1), radius: 5)
                    .padding()
                    
                    Spacer()
                    
                    if let error = bookingError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Replace slider with a direct button for easier booking
                    Button(action: {
                        if !isProcessing {
                            processPayment()
                        }
                    }) {
                        Text(isProcessing ? "Processing..." : "Book Now")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(isProcessing)
                    .padding(.bottom, 20)
                }
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
        Task {
            do {
                guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                }
                
                print("🔍 Fetching patient record for user ID: \(userId)")
                
                // Get patient_id from the patients table - try multiple approaches
                let patientResults = try await SupabaseController.shared.select(
                    from: "patients",
                    where: "user_id", 
                    equals: userId
                )
                
                print("Found \(patientResults.count) patient records")
                
                // Extract the PAT format patient_id
                guard let patientData = patientResults.first,
                      let patientId = patientData["patient_id"] as? String else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find patient_id"])
                }
                
                print("📝 Creating appointment for patient: \(patientId)")
                
                // Format date for database
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: appointmentDate)
                
                // Format times consistently for database storage
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                // Ensure we have proper time formats for database
                var formattedStartTime = rawStartTime
                var formattedEndTime = rawEndTime
                
                // Add seconds if needed
                if !formattedStartTime.contains(":") {
                    formattedStartTime += ":00"
                } else if formattedStartTime.components(separatedBy: ":").count == 2 {
                    formattedStartTime += ":00"
                }
                
                if !formattedEndTime.contains(":") {
                    formattedEndTime += ":00"
                } else if formattedEndTime.components(separatedBy: ":").count == 2 {
                    formattedEndTime += ":00"
                }
                
                // Create slot JSON for database
                let slotData: [String: String] = [
                    "start_time": formattedStartTime,
                    "end_time": formattedEndTime
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: slotData)
                let slotJson = String(data: jsonData, encoding: .utf8) ?? ""
                
                // Generate appointment ID
                let randomNum = String(format: "%03d", Int.random(in: 0...999))
                let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
                let appointmentId = "APPT\(randomNum)\(randomLetter)"
                
                // First, get the current filled_slots count
                let doctorResults = try await SupabaseController.shared.select(
                    from: "doctors",
                    where: "id",
                    equals: doctor.id
                )
                
                guard let doctorData = doctorResults.first else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find doctor record"])
                }
                
                let currentFilledSlots = doctorData["filled_slots"] as? Int ?? 0
                
                // Create appointment in database
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId,  // Using PAT format ID from patients table
                    "doctor_id": doctor.id,
                    "hospital_id": doctor.hospitalId,
                    "appointment_date": dateString,
                    "status": "upcoming",
                    "reason": "Medical consultation",
                    "isdone": false,
                    "is_premium": isPremium,
                    "slot_start_time": formattedStartTime,
                    "slot_end_time": formattedEndTime,
                    "slot": slotJson
                ]
                
                // Use the insert method (which uses REST API)
                try await SupabaseController.shared.insert(into: "appointments", values: appointmentData)
                print("✅ Successfully inserted appointment")
                
                // Update the filled_slots count in the doctors table
                let updatedFilledSlots = currentFilledSlots + 1
                try await SupabaseController.shared.update(
                    table: "doctors",
                    data: ["filled_slots": updatedFilledSlots],
                    where: "id",
                    equals: doctor.id
                )
                print("✅ Updated filled_slots count to \(updatedFilledSlots)")
                
                // Create and add local appointment object for state management
                // Convert formatted database times to display format
                let displayStartTime = formatTimeForDisplay(formattedStartTime)
                let displayEndTime = formatTimeForDisplay(formattedEndTime)
                
                print("💾 Saving appointment with times: DB=(\(formattedStartTime)-\(formattedEndTime)) Display=(\(displayStartTime)-\(displayEndTime))")
                
                let appointment = Appointment(
                    id: appointmentId,
                    doctor: doctor.toModelDoctor(),
                    date: appointmentDate,
                    time: timeFormatter.date(from: formattedStartTime) ?? Date(),
                    status: .upcoming,
                    startTime: displayStartTime,
                    endTime: displayEndTime,
                    isPremium: isPremium
                )
                
                // Add to appointment manager
                await MainActor.run {
                    AppointmentManager.shared.addAppointment(appointment)
                    
                    // Success! Navigate to success screen
                    isProcessing = false
                    navigateToSuccess = true
                }
                
                // Refresh appointments from database
                if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                    print("🔄 Refreshing appointments after booking with user ID: \(userId)")
                    try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                }
                
            } catch {
                // Handle error with detailed logging
                print("❌ Error creating appointment: \(error.localizedDescription)")
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
    
    // Helper function to convert database time format to display format
    private func formatTimeForDisplay(_ databaseTime: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let date = inputFormatter.date(from: databaseTime) {
            return outputFormatter.string(from: date)
        }
        
        // Try alternative formats
        let alternativeFormats = ["HH:mm", "h:mm a", "hh:mm a", "h:mm"]
        for format in alternativeFormats {
            inputFormatter.dateFormat = format
            if let date = inputFormatter.date(from: databaseTime) {
                return outputFormatter.string(from: date)
            }
        }
        
        print("⚠️ Warning: Could not format time: \(databaseTime)")
        return databaseTime
    }
} 