import SwiftUI
import class MediOps.SupabaseController

struct DoctorAppointmentDetailsView: View {
    let appointment: DoctorAppointmentModel
    
    @State private var patientDetails: PatientDetailModel? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isUpdatingStatus = false
    @State private var showCompletionSuccess = false
    @State private var showCompletionConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
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