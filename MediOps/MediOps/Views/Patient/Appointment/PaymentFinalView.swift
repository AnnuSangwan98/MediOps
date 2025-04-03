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
        // Use the rawStartTime and rawEndTime for creating the appointment in database
        // This ensures consistency between what's displayed and what's stored
        
        Task {
            do {
                guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                }
                
                // Get patient_id from the patients table - try multiple approaches
                let patientResults = try await SupabaseController.shared.select(
                    from: "patients",
                    where: "user_id", 
                    equals: userId
                )
                
                // Check if we have patients data and extract patient ID
                var patientId: String? = nil
                
                if let patientData = patientResults.first {
                    // Try patient_id first
                    if let pid = patientData["patient_id"] as? String, !pid.isEmpty {
                        patientId = pid
                    } 
                    // Fall back to id field if patient_id is not available
                    else if let pid = patientData["id"] as? String {
                        patientId = pid
                    }
                }
                
                // If we don't have a patient ID from the first query, try direct SQL
                if patientId == nil {
                    // Try one more fallback - get patient records by direct user_id match
                    let directResults = try await SupabaseController.shared.select(
                        from: "patients", 
                        where: "user_id", 
                        equals: userId
                    )
                    
                    if let firstRecord = directResults.first,
                       let id = firstRecord["id"] as? String {
                        patientId = id
                    }
                }
                
                // Final check to ensure we have a patient ID
                if patientId == nil {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find patient record for this user"])
                }
                
                // Generate appointment ID in the format APPT[0-9]{3}[A-Z]
                let randomNum = String(format: "%03d", Int.random(in: 0...999))
                let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
                let appointmentId = "APPT\(randomNum)\(randomLetter)"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: appointmentDate)
                
                // Format times properly for database storage - 24-hour format
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                // Initialize with default values
                var formattedStartTime = "12:00:00"
                var formattedEndTime = "13:00:00"
                
                // If rawTimes are in the correct format, use them directly
                if let date = timeFormatter.date(from: rawStartTime) {
                    formattedStartTime = rawStartTime
                } else {
                    // Try to convert from any other format to HH:mm:ss
                    let displayFormatter = DateFormatter()
                    // Try different formats
                    for format in ["h:mm a", "HH:mm", "h:mm", "hh:mm a"] {
                        displayFormatter.dateFormat = format
                        if let date = displayFormatter.date(from: rawStartTime) {
                            formattedStartTime = timeFormatter.string(from: date)
                            break
                        }
                    }
                }
                
                // Same for end time
                if let date = timeFormatter.date(from: rawEndTime) {
                    formattedEndTime = rawEndTime
                } else {
                    // Try to convert from any other format to HH:mm:ss
                    let displayFormatter = DateFormatter()
                    // Try different formats
                    for format in ["h:mm a", "HH:mm", "h:mm", "hh:mm a"] {
                        displayFormatter.dateFormat = format
                        if let date = displayFormatter.date(from: rawEndTime) {
                            formattedEndTime = timeFormatter.string(from: date)
                            break
                        }
                    }
                }
                
                // Format the slot JSON properly - ensure it uses the same formatted times
                let slotJson = """
                {"doctor_id": "\(doctor.id)", "start_time": "\(formattedStartTime)", "end_time": "\(formattedEndTime)"}
                """
                
                // Create appointment data with all required fields
                let appointmentData: [String: Any] = [
                    "id": appointmentId,
                    "patient_id": patientId!,
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
                
                // Create and add local appointment object for state management
                // Convert formatted database times to display format
                let displayStartTime = formatTimeForDisplay(formattedStartTime)
                let displayEndTime = formatTimeForDisplay(formattedEndTime)
                
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
                    try await HospitalViewModel.shared.fetchAppointments(for: patientId!)
                }
                
            } catch {
                // Handle error
                DispatchQueue.main.async {
                    isProcessing = false
                    bookingError = "Failed to create appointment: \(error.localizedDescription)"
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