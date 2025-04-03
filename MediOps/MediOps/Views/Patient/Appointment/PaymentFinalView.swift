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
    @ObservedObject private var translationManager = TranslationManager.shared
    
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
                Text("confirm_payment".localized)
                    .font(.title2)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.teal)
                        Text("pay_with".localized)
                        Spacer()
                        Text("•••• 5941")
                        Button("change".localized) {}
                            .foregroundColor(.teal)
                    }
                    
                    Divider()
                    
                    Text("bill_details".localized)
                        .font(.headline)
                    
                    Group {
                        HStack {
                            Text("consultation_fees".localized)
                            Spacer()
                            Text("Rs.\(Int(consultationFee))")
                        }
                        
                        HStack {
                            Text("booking_fee".localized)
                            Spacer()
                            Text("Rs.\(Int(bookingFee))")
                        }
                        
                        if isPremium {
                            HStack {
                                Text("premium_fee".localized)
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
                        Text("total_pay".localized)
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
                    
                    Text(isProcessing ? "processing".localized : "swipe_to_pay".localized)
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
        Task {
            do {
                guard let userId = UserDefaults.standard.string(forKey: "current_user_id") else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                }
                
                print("🔍 Fetching patient record for user ID: \(userId)")
                
                // Get patient_id (PAT format) from the patients table
                let patientResults = try await SupabaseController.shared.select(
                    from: "patients",
                    where: "user_id", 
                    equals: userId
                )
                
                print("Found \(patientResults.count) patient records")
                
                // Extract the PAT format patient_id
                guard let patientData = patientResults.first,
                      let patientId = patientData["patient_id"] as? String else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find PAT format patient_id"])
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
                
                // Create appointment in database using PAT format patient_id
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
                
                // Insert appointment with PAT format patient_id
                try await SupabaseController.shared.insert(into: "appointments", values: appointmentData)
                print("✅ Successfully inserted appointment with patient_id: \(patientId)")
                
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
                    isProcessing = false
                    navigateToSuccess = true
                }
                
                // Refresh appointments from database using PAT format ID
                print("🔄 Refreshing appointments for patient_id: \(patientId)")
                try await HospitalViewModel.shared.fetchAppointments(for: patientId)
                
            } catch {
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