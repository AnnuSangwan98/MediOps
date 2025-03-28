import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    @StateObject private var appointmentManager = AppointmentManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelConfirmation = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Appointment Status Banner
                statusBanner
                
                // Appointment Details Card
                detailsCard
                
                // Doctor Information Card
                doctorInfoCard
                
                // Appointment Actions
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Appointment", isPresented: $showCancelConfirmation) {
            Button("No", role: .cancel) { }
            Button("Yes, Cancel", role: .destructive) {
                appointmentManager.cancelAppointment(appointment.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to cancel this appointment?")
        }
    }
    
    // Status Banner
    private var statusBanner: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(.white)
            Text(statusText)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(statusColor)
        .cornerRadius(10)
    }
    
    // Appointment Details
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Appointment Information")
                .font(.headline)
            
            Divider()
            
            infoRow(icon: "calendar", title: "Date", value: dateFormatter.string(from: appointment.date))
            infoRow(icon: "clock", title: "Time", value: timeFormatter.string(from: appointment.time))
            infoRow(icon: "number", title: "Appointment ID", value: appointment.id)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
    }
    
    // Doctor Information
    private var doctorInfoCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Doctor Information")
                .font(.headline)
            
            Divider()
            
            infoRow(icon: "person", title: "Doctor", value: appointment.doctor.name)
            infoRow(icon: "stethoscope", title: "Specialization", value: appointment.doctor.specialization)
            if let contact = appointment.doctor.contactNumber {
                infoRow(icon: "phone", title: "Contact", value: contact)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 5)
    }
    
    // Action Buttons
    private var actionButtons: some View {
        HStack {
            // Only show cancel button for upcoming appointments
            if appointment.status == .upcoming {
                Button(action: {
                    showCancelConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel Appointment")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Button(action: {
                // Navigate to messaging or telemedicine feature
            }) {
                HStack {
                    Image(systemName: "message")
                    Text("Contact Doctor")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    // Helper View
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 25, height: 25)
                .foregroundColor(.teal)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
    }
    
    // Status color
    private var statusColor: Color {
        switch appointment.status {
        case .upcoming:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
    
    // Status icon
    private var statusIcon: String {
        switch appointment.status {
        case .upcoming:
            return "calendar.badge.clock"
        case .completed:
            return "checkmark.circle"
        case .cancelled:
            return "xmark.circle"
        }
    }
    
    // Status text
    private var statusText: String {
        switch appointment.status {
        case .upcoming:
            return "Upcoming Appointment"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
} 