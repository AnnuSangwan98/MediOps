import SwiftUI
import class MediOps.SupabaseController
import enum MediOps.SupabaseError

struct DoctorAppointmentDetailsView: View {
    let appointment: DoctorAppointmentModel
    
    @State private var patientDetails: PatientDetailModel? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isUpdatingStatus = false
    @State private var showCompletionSuccess = false
    @State private var showCompletionConfirmation = false
    @State private var showPrescriptionSheet = false
    @State private var prescriptionData = DoctorPrescriptionData()
    @State private var isSavingPrescription = false
    @State private var prescriptionError: String? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showPrescriptionSuccess = false
    @State private var showPrescriptionList = false
    @State private var prescriptionsList: [PrescriptionViewModel] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Appointment Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Status badge
                    Text(appointment.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(appointment.status.color.opacity(0.2))
                        .foregroundColor(appointment.status.color)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Appointment Information Card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Appointment Information")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Divider()
                    
                    // Date & Time
                    HStack(spacing: 25) {
                        // Date
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundColor(.teal)
                            }
                            
                            Text(formatDate(appointment.appointmentDate))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Time
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "clock")
                                    .foregroundColor(.teal)
                            }
                            
                            // First try to show both times
                            if let endTime = appointment.slotEndTime, !endTime.isEmpty {
                                if !appointment.slotTime.isEmpty {
                                    Text("\(appointment.slotTime) - \(endTime)")
                                        .font(.body)
                                        .fontWeight(.medium)
                                } else {
                                    // Only end time exists
                                    Text(endTime)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            } else if !appointment.slotTime.isEmpty {
                                // Only start time exists
                                Text(appointment.slotTime)
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                // No time information
                                Text("—")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    if !appointment.reason.isEmpty {
                        // Reason
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Reason")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "list.clipboard")
                                    .foregroundColor(.teal)
                            }
                            
                            Text(appointment.reason)
                                .font(.body)
                        }
                    }
                    
                    if let isPremium = appointment.isPremium, isPremium {
                        Divider()
                        
                        // Premium
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            
                            Text("Premium Appointment")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.gray.opacity(0.1), radius: 5)
                .padding(.horizontal)
                
                // Patient Information Card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Patient Information")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading patient details...")
                            Spacer()
                        }
                        .padding()
                    } else if let error = errorMessage {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .padding()
                    } else if let patient = patientDetails {
                        Divider()
                        
                        // Patient Name
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "person")
                                    .foregroundColor(.teal)
                            }
                            
                            Text(patient.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        // Gender & Age
                        HStack(spacing: 25) {
                            // Gender
                            VStack(alignment: .leading, spacing: 5) {
                                Label {
                                    Text("Gender")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } icon: {
                                    Image(systemName: patient.gender.lowercased() == "male" ? "person" : "person.fill")
                                        .foregroundColor(.teal)
                                }
                                
                                Text(patient.gender)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            // Age
                            VStack(alignment: .leading, spacing: 5) {
                                Label {
                                    Text("Age")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } icon: {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.teal)
                                }
                                
                                Text("\(patient.age) years")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        // Contact
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Contact")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "phone")
                                    .foregroundColor(.teal)
                            }
                            
                            Text(patient.phone)
                                .font(.body)
                        }
                        
                        Divider()
                        
                        // Email
                        VStack(alignment: .leading, spacing: 5) {
                            Label {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "envelope")
                                    .foregroundColor(.teal)
                            }
                            
                            Text(patient.email)
                                .font(.body)
                        }
                        
                        if !patient.medicalHistory.isEmpty {
                            Divider()
                            
                            // Medical History
                            VStack(alignment: .leading, spacing: 5) {
                                Label {
                                    Text("Medical History")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } icon: {
                                    Image(systemName: "heart.text.square")
                                        .foregroundColor(.teal)
                                }
                                
                                Text(patient.medicalHistory)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.gray.opacity(0.1), radius: 5)
                .padding(.horizontal)
                
                // Action Buttons (based on appointment status)
                if appointment.status == .upcoming {
                    VStack(spacing: 12) {
                        Button(action: {
                            showPrescriptionSheet = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "prescription")
                                Text("Write Prescription")
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showCompletionConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                if isUpdatingStatus {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text("Mark as Completed")
                                Spacer()
                            }
                            .padding()
                            .background(isUpdatingStatus ? Color.gray : Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isUpdatingStatus)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                Button(action: {
                    fetchPrescriptions()
                    showPrescriptionList = true
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "list.bullet.clipboard")
                        Text("View Prescriptions")
                        Spacer()
                    }
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Spacer()
                    .frame(height: 30)
            }
        }
        .background(Color(.systemGray6).opacity(0.5).ignoresSafeArea())
        .onAppear {
            fetchPatientDetails()
        }
        .alert("Appointment Completed", isPresented: $showCompletionSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The appointment with \(appointment.patientName) has been marked as completed successfully.")
        }
        .alert("Confirm Completion", isPresented: $showCompletionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete", role: .destructive) {
                markAsCompleted()
            }
        } message: {
            Text("Are you sure you want to mark this appointment with \(appointment.patientName) as completed?")
        }
        .sheet(isPresented: $showPrescriptionSheet) {
            DoctorPrescriptionSheet(
                prescriptionData: $prescriptionData,
                isSavingPrescription: $isSavingPrescription,
                onSave: {
                    Task {
                        do {
                            try await savePrescription()
                        } catch {
                            prescriptionError = error.localizedDescription
                        }
                    }
                }
            )
        }
        .alert("Prescription Error", isPresented: .init(
            get: { prescriptionError != nil },
            set: { if !$0 { prescriptionError = nil } }
        )) {
            Button("OK", role: .cancel) {
                prescriptionError = nil
            }
        } message: {
            if let error = prescriptionError {
                Text(error)
            }
        }
        .alert("Prescription Added", isPresented: $showPrescriptionSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Prescription has been successfully added for \(appointment.patientName).")
        }
        .sheet(isPresented: $showPrescriptionList) {
            DoctorPrescriptionListView(
                patientName: appointment.patientName,
                appointmentId: appointment.id,
                prescriptions: prescriptionsList
            )
        }
    }
    
    private func fetchPatientDetails() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let supabase = SupabaseController.shared
                
                // Fetch patient details from the patients table
                let result = try await supabase.select(
                    from: "patients",
                    where: "patient_id",
                    equals: appointment.patientId
                )
                
                if let patientData = result.first {
                    // Parse patient data
                    let name = patientData["name"] as? String ?? "Unknown"
                    let email = patientData["email"] as? String ?? "Not provided"
                    let phone = patientData["phone"] as? String ?? "Not provided"
                    let gender = patientData["gender"] as? String ?? "Not specified"
                    let age = patientData["age"] as? Int ?? 0
                    let medicalHistory = patientData["medical_history"] as? String ?? ""
                    let bloodGroup = patientData["blood_group"] as? String ?? "Not specified"
                    
                    // Create patient details model
                    let patient = PatientDetailModel(
                        id: appointment.patientId,
                        name: name,
                        email: email,
                        phone: phone,
                        gender: gender,
                        age: age,
                        medicalHistory: medicalHistory,
                        bloodGroup: bloodGroup
                    )
                    
                    await MainActor.run {
                        self.patientDetails = patient
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Patient details not found"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load patient details: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func markAsCompleted() {
        isUpdatingStatus = true
        
        Task {
            do {
                let supabase = SupabaseController.shared
                
                // Use the appropriate method in SupabaseController to update the appointment
                let updates: [String: String] = [
                    "status": "completed",
                    "isdone": "true"
                ]
                
                // Update the appointment
                try await supabase.update(
                    table: "appointments",
                    data: updates,
                    where: "id",
                    equals: appointment.id
                )
                
                // If we get here, the update was successful
                await MainActor.run {
                    isUpdatingStatus = false
                    showCompletionSuccess = true
                }
            } catch {
                await MainActor.run {
                    isUpdatingStatus = false
                    errorMessage = "Failed to mark appointment as completed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func savePrescription() async throws {
        isSavingPrescription = true
        
        do {
            let supabase = SupabaseController.shared
            
            // Validate required data
            guard let doctorId = UserDefaults.standard.string(forKey: "current_doctor_id"),
                  !doctorId.isEmpty else {
                throw NSError(domain: "MediOps", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: "Doctor ID not found. Please log in again."
                ])
            }
            
            print("DEBUG: Doctor ID: \(doctorId)")
            print("DEBUG: Appointment ID: \(appointment.id)")
            print("DEBUG: Patient ID: \(appointment.patientId)")
            
            // Generate a unique prescription ID (PRSR + 3 digits + 1 letter)
            let randomNum = String(format: "%03d", Int.random(in: 0...999))
            let randomLetter = String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25))))
            let prescriptionId = "PRSR\(randomNum)\(randomLetter)"
            
            print("DEBUG: Generated Prescription ID: \(prescriptionId)")
            
            // Validate medications
            guard !prescriptionData.medications.isEmpty else {
                throw NSError(domain: "MediOps", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: "Please add at least one medication."
                ])
            }
            
            // Convert medications to JSON format
            let medicationsJson = prescriptionData.medications.map { med in
                [
                    "medicine_name": med.medicineName,
                    "dosage": med.dosage,
                    "frequency": med.frequency,
                    "timing": med.timing,
                    "brand_name": med.brandName
                ]
            }
            
            print("DEBUG: Medications JSON: \(medicationsJson)")
            
            // Convert lab tests to JSON format if present
            let labTestsJson = prescriptionData.labTests.map { test in
                [
                    "test_name": test.testName,
                    "instructions": test.instructions
                ]
            }
            
            print("DEBUG: Lab Tests JSON: \(labTestsJson)")
            
            // Format the current date in ISO8601 format
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            let currentDateString = isoFormatter.string(from: Date())
            
            // Create prescription payload using the struct
            let payload = PrescriptionPayload(
                id: prescriptionId,
                appointment_id: appointment.id,
                doctor_id: doctorId,
                patient_id: appointment.patientId,
                prescription_date: currentDateString,
                medications: medicationsJson,
                lab_tests: labTestsJson.isEmpty ? nil : labTestsJson,
                precautions: prescriptionData.precautions.isEmpty ? nil : prescriptionData.precautions,
                previous_prescription_url: nil,
                lab_reports_url: nil,
                additional_notes: prescriptionData.additionalNotes.isEmpty ? nil : prescriptionData.additionalNotes
            )
            
            print("DEBUG: Final Payload: \(payload)")
            
            // Insert prescription into database
            print("DEBUG: Attempting to insert prescription...")
            try await supabase.insert(
                into: "prescriptions",
                data: payload
            )
            
            print("DEBUG: Prescription saved successfully!")
            
            // Clear the prescription data after successful save
            await MainActor.run {
                prescriptionData = DoctorPrescriptionData()
                isSavingPrescription = false
                showPrescriptionSheet = false
                showPrescriptionSuccess = true
            }
        } catch {
            print("DEBUG: Error saving prescription - Full Error: \(error)")
            if let supabaseError = error as? SupabaseError {
                print("DEBUG: Supabase Error Details: \(supabaseError)")
            }
            
            await MainActor.run {
                isSavingPrescription = false
                prescriptionError = "Failed to save prescription. Please try again."
            }
            throw error
        }
    }
    
    private func fetchPrescriptions() {
        Task {
            do {
                let supabase = SupabaseController.shared
                
                let result = try await supabase.select(
                    from: "prescriptions",
                    columns: "*",
                    where: "appointment_id",
                    equals: appointment.id
                )
                
                // Parse prescriptions
                var prescriptions: [PrescriptionViewModel] = []
                
                for data in result {
                    guard let id = data["id"] as? String,
                          let prescriptionDate = data["prescription_date"] as? String else {
                        continue
                    }
                    
                    // Format date
                    let dateFormatter = ISO8601DateFormatter()
                    let date = dateFormatter.date(from: prescriptionDate) ?? Date()
                    let displayDateFormatter = DateFormatter()
                    displayDateFormatter.dateStyle = .medium
                    displayDateFormatter.timeStyle = .short
                    
                    // Parse medications
                    var medicationsList: [String] = []
                    if let medications = data["medications"] as? [[String: Any]] {
                        for med in medications {
                            if let name = med["medicine_name"] as? String {
                                medicationsList.append(name)
                            }
                        }
                    }
                    
                    let prescription = PrescriptionViewModel(
                        id: id,
                        date: displayDateFormatter.string(from: date),
                        medicationCount: medicationsList.count,
                        medications: medicationsList
                    )
                    
                    prescriptions.append(prescription)
                }
                
                await MainActor.run {
                    self.prescriptionsList = prescriptions
                }
            } catch {
                print("ERROR: Failed to fetch prescriptions: \(error)")
            }
        }
    }
}

// Patient Detail Model
struct PatientDetailModel {
    let id: String
    let name: String
    let email: String
    let phone: String
    let gender: String
    let age: Int
    let medicalHistory: String
    let bloodGroup: String
}

// Add these models at the top of the file, after the imports
struct DoctorPrescriptionMedication: Identifiable, Hashable {
    let id = UUID()
    var medicineName: String
    var dosage: String
    var frequency: String
    var timing: String
    var brandName: String = ""
}

struct DoctorPrescriptionLabTest: Identifiable, Hashable {
    let id = UUID()
    var testName: String
    var instructions: String = ""
}

struct DoctorPrescriptionData {
    var medications: [DoctorPrescriptionMedication] = []
    var labTests: [DoctorPrescriptionLabTest] = []
    var precautions: String = ""
    var additionalNotes: String = ""
}

// Add this view for the prescription sheet
struct DoctorPrescriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var prescriptionData: DoctorPrescriptionData
    @Binding var isSavingPrescription: Bool
    let onSave: () -> Void
    
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    private var isValid: Bool {
        // Check if there are any medications
        if prescriptionData.medications.isEmpty {
            validationMessage = "Please add at least one medication"
            return false
        }
        
        // Check if all medications have required fields
        for medication in prescriptionData.medications {
            if medication.medicineName.isEmpty {
                validationMessage = "Please enter medicine name for all medications"
                return false
            }
            if medication.dosage.isEmpty {
                validationMessage = "Please enter dosage for all medications"
                return false
            }
            if medication.frequency.isEmpty {
                validationMessage = "Please enter frequency for all medications"
                return false
            }
            if medication.timing.isEmpty {
                validationMessage = "Please enter timing for all medications"
                return false
            }
        }
        
        // Check if all lab tests have names
        for test in prescriptionData.labTests {
            if test.testName.isEmpty {
                validationMessage = "Please enter test name for all lab tests"
                return false
            }
        }
        
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medications")) {
                    ForEach($prescriptionData.medications) { $medication in
                        NavigationLink(destination: DoctorMedicationEditView(medication: $medication)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(medication.medicineName.isEmpty ? "New Medication" : medication.medicineName)
                                    .font(.headline)
                                if !medication.dosage.isEmpty || !medication.frequency.isEmpty {
                                    Text("\(medication.dosage) - \(medication.frequency)")
                                        .font(.subheadline)
                                }
                                if !medication.timing.isEmpty {
                                    Text(medication.timing)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                if !medication.brandName.isEmpty {
                                    Text("Brand: \(medication.brandName)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        prescriptionData.medications.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        prescriptionData.medications.append(
                            DoctorPrescriptionMedication(
                                medicineName: "",
                                dosage: "",
                                frequency: "",
                                timing: ""
                            )
                        )
                    }) {
                        Label("Add Medication", systemImage: "plus.circle")
                    }
                }
                
                Section(header: Text("Lab Tests")) {
                    ForEach($prescriptionData.labTests) { $test in
                        NavigationLink(destination: DoctorLabTestEditView(labTest: $test)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(test.testName.isEmpty ? "New Lab Test" : test.testName)
                                    .font(.headline)
                                if !test.instructions.isEmpty {
                                    Text(test.instructions)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        prescriptionData.labTests.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        prescriptionData.labTests.append(
                            DoctorPrescriptionLabTest(testName: "")
                        )
                    }) {
                        Label("Add Lab Test", systemImage: "plus.circle")
                    }
                }
                
                Section(header: Text("Precautions")) {
                    TextEditor(text: $prescriptionData.precautions)
                        .frame(height: 100)
                }
                
                Section(header: Text("Additional Notes")) {
                    TextEditor(text: $prescriptionData.additionalNotes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Write Prescription")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .disabled(isSavingPrescription),
                trailing: Button(action: {
                    if isValid {
                        onSave()
                    } else {
                        showValidationAlert = true
                    }
                }) {
                    if isSavingPrescription {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save")
                    }
                }
                .disabled(isSavingPrescription)
            )
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .interactiveDismissDisabled(isSavingPrescription)
        }
    }
}

// Add these views after the DoctorPrescriptionSheet
struct DoctorMedicationEditView: View {
    @Binding var medication: DoctorPrescriptionMedication
    @Environment(\.dismiss) private var dismiss
    @State private var showValidationAlert = false
    
    private var isValid: Bool {
        !medication.medicineName.isEmpty &&
        !medication.dosage.isEmpty &&
        !medication.frequency.isEmpty &&
        !medication.timing.isEmpty
    }
    
    var body: some View {
        Form {
            Section(header: Text("Medicine Details")) {
                TextField("Medicine Name *", text: $medication.medicineName)
                    .textInputAutocapitalization(.words)
                
                TextField("Brand Name (Optional)", text: $medication.brandName)
                    .textInputAutocapitalization(.words)
                
                TextField("Dosage (e.g. 500 mg) *", text: $medication.dosage)
                    .keyboardType(.default)
                    .textInputAutocapitalization(.none)
                
                Picker("Frequency *", selection: $medication.frequency) {
                    Text("Select").tag("")
                    Text("Once daily").tag("Once daily")
                    Text("Twice daily").tag("Twice daily")
                    Text("Thrice daily").tag("Thrice daily")
                    Text("Four times daily").tag("Four times daily")
                    Text("Every 6 hours").tag("Every 6 hours")
                    Text("Every 8 hours").tag("Every 8 hours")
                    Text("Every 12 hours").tag("Every 12 hours")
                    Text("As needed").tag("As needed")
                }
                
                Picker("Timing *", selection: $medication.timing) {
                    Text("Select").tag("")
                    Text("Before food").tag("Before food")
                    Text("After food").tag("After food")
                    Text("With food").tag("With food")
                    Text("Empty stomach").tag("Empty stomach")
                    Text("Before breakfast").tag("Before breakfast")
                    Text("After breakfast").tag("After breakfast")
                    Text("Before dinner").tag("Before dinner")
                    Text("After dinner").tag("After dinner")
                    Text("Bedtime").tag("Bedtime")
                }
            }
            
            Section(footer: Text("* Required fields")) {
                EmptyView()
            }
        }
        .navigationTitle("Edit Medicine")
        .navigationBarItems(
            trailing: Button("Done") {
                if isValid {
                    dismiss()
                } else {
                    showValidationAlert = true
                }
            }
        )
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please fill in all required fields marked with *")
        }
    }
}

struct DoctorLabTestEditView: View {
    @Binding var labTest: DoctorPrescriptionLabTest
    @Environment(\.dismiss) private var dismiss
    @State private var showValidationAlert = false
    
    private var isValid: Bool {
        !labTest.testName.isEmpty
    }
    
    var body: some View {
        Form {
            Section(header: Text("Lab Test Details")) {
                Picker("Test Name *", selection: $labTest.testName) {
                    Text("Select").tag("")
                    Text("Complete Blood Count (CBC)").tag("Complete Blood Count (CBC)")
                    Text("Blood Sugar (Fasting & PP)").tag("Blood Sugar (Fasting & PP)")
                    Text("Lipid Profile").tag("Lipid Profile")
                    Text("Liver Function Test").tag("Liver Function Test")
                    Text("Kidney Function Test").tag("Kidney Function Test")
                    Text("Thyroid Profile").tag("Thyroid Profile")
                    Text("Urine Analysis").tag("Urine Analysis")
                    Text("ECG").tag("ECG")
                    Text("X-Ray").tag("X-Ray")
                    Text("Ultrasound").tag("Ultrasound")
                    Text("CT Scan").tag("CT Scan")
                    Text("MRI").tag("MRI")
                }
                
                TextField("Special Instructions (Optional)", text: $labTest.instructions)
                    .textInputAutocapitalization(.sentences)
            }
            
            Section(footer: Text("* Required fields")) {
                EmptyView()
            }
        }
        .navigationTitle("Edit Lab Test")
        .navigationBarItems(
            trailing: Button("Done") {
                if isValid {
                    dismiss()
                } else {
                    showValidationAlert = true
                }
            }
        )
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a test name")
        }
    }
}

// Add this struct before the DoctorAppointmentDetailsView
struct PrescriptionPayload: Encodable {
    let id: String
    let appointment_id: String
    let doctor_id: String
    let patient_id: String
    let prescription_date: String
    let medications: [[String: String]]
    let lab_tests: [[String: String]]?
    let precautions: String?
    let previous_prescription_url: String?
    let lab_reports_url: String?
    let additional_notes: String?
}

// Add this model at the end of the file
struct PrescriptionViewModel: Identifiable {
    let id: String
    let date: String
    let medicationCount: Int
    let medications: [String]
}

// Add this view at the end of the file
struct DoctorPrescriptionListView: View {
    let patientName: String
    let appointmentId: String
    let prescriptions: [PrescriptionViewModel]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if prescriptions.isEmpty {
                    ContentUnavailableView(
                        "No Prescriptions",
                        systemImage: "clipboard",
                        description: Text("No prescriptions have been added for this appointment yet.")
                    )
                } else {
                    List {
                        ForEach(prescriptions) { prescription in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(prescription.date)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("ID: \(prescription.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Medications (\(prescription.medicationCount))")
                                    .font(.headline)
                                
                                ForEach(prescription.medications, id: \.self) { medication in
                                    Text("• \(medication)")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Prescriptions")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    // Create a sample appointment for preview
    let sampleAppointment = DoctorAppointmentModel(
        id: "1",
        patientId: "patient1",
        patientName: "John Doe",
        hospitalId: "hospital1",
        hospitalName: "General Hospital",
        appointmentDate: Date(),
        bookingTime: Date().addingTimeInterval(-86400),
        status: .upcoming,
        reason: "Regular checkup",
        isDone: false,
        isPremium: true,
        slotId: 1,
        slotTime: "10:00 AM",
        slotEndTime: "11:00 AM"
    )
    
    DoctorAppointmentDetailsView(appointment: sampleAppointment)
} 