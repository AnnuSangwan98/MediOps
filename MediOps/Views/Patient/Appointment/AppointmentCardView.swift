struct AppointmentCard: View {
    @State private var showCancelAlert = false
    let appointment: Appointment
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private func formatTimeRange(_ time: Date) -> String {
        // ... existing code ...
    }
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(appointment.doctor.name)
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        Text(appointment.doctor.specialization)
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.subtext)
                    }
                    
                    Spacer()
                    
                    Text(appointment.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(statusTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusBackgroundColor)
                        .cornerRadius(8)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.colors.secondary)
                    Text(appointment.date.formatted(date: .long, time: .omitted))
                    
                    Image(systemName: "clock")
                        .foregroundColor(themeManager.colors.secondary)
                    let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.time)!
                    Text("\(appointment.time.formatted(date: .omitted, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))")
                }
                .font(.subheadline)
                .foregroundColor(themeManager.colors.subtext)
                
                if appointment.status == .upcoming {
                    Button(action: {
                        showCancelAlert = true
                    }) {
                        Text("Cancel Appointment")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(themeManager.colors.error.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                if appointment.status == .completed {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(themeManager.colors.primary)
                        Text("View Prescription")
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(themeManager.colors.subtext)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(themeManager.colors.background)
            .cornerRadius(12)
            .shadow(color: themeManager.colors.primary.opacity(0.1), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper computed properties for status colors
    private var statusBackgroundColor: Color {
        switch appointment.status {
        case .upcoming:
            return themeManager.colors.primary.opacity(0.1)
        case .completed:
            return Color.green.opacity(0.1)
        case .cancelled:
            return themeManager.colors.error.opacity(0.1)
        case .missed:
            return themeManager.colors.secondary.opacity(0.1)
        }
    }
    
    private var statusTextColor: Color {
        switch appointment.status {
        case .upcoming:
            return themeManager.colors.primary
        case .completed:
            return .green
        case .cancelled:
            return themeManager.colors.error
        case .missed:
            return themeManager.colors.secondary
        }
    }
} 