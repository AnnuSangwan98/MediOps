import SwiftUI

struct AppointmentView: View {
    let doctor: Doctor
    var existingAppointment: Appointment? = nil
    var onUpdateAppointment: ((Appointment) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime: Date? = nil
    @State private var showReviewAndPay = false
    
    private let timeSlots: [Date] = {
        var slots: [Date] = []
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        
        for hour in 0..<8 {
            for minute in stride(from: 0, to: 60, by: 30) {
                if let time = calendar.date(byAdding: .minute, value: hour * 60 + minute, to: startTime) {
                    slots.append(time)
                }
            }
        }
        return slots
    }()
    
    var body: some View {
        NavigationStack {
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
                    
                    // Doctor stats
                    HStack(spacing: 30) {
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                Text("Experience")
                            }
                            Text("\(doctor.experience)+ Years")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "stethoscope")
                                Text("Specialization")
                            }
                            Text(doctor.specialization)
                                .font(.headline)
                        }
                        
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("License")
                            }
                            Text(doctor.licenseNo)
                                .font(.headline)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    
                    // Available Time
                    Text("Available Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Date Picker
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    // Time slots grid
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 10) {
                        ForEach(timeSlots, id: \.self) { time in
                            TimeSlotButton(time: time, isSelected: time == selectedTime) {
                                selectedTime = time
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(existingAppointment != nil ? "Reschedule Appointment" : "Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            
            // Book / Update button
            Button(action: {
                if let existingAppointment = existingAppointment, let selectedTime = selectedTime {
                    // Directly update without opening ReviewAndPayView
                    var updatedAppointment = existingAppointment
                    updatedAppointment.date = selectedDate
                    updatedAppointment.time = selectedTime
                    onUpdateAppointment?(updatedAppointment)
                    dismiss()
                } else {
                    // New appointment — open ReviewAndPayView
                    showReviewAndPay.toggle()
                }
            }) {
                Text(existingAppointment != nil ? "Update Appointment" : "Book Appointment")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTime != nil ? Color.teal : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(selectedTime == nil)
            .padding()
            .sheet(isPresented: $showReviewAndPay) {
                if let time = selectedTime {
                    ReviewAndPayView(doctor: doctor, appointmentDate: selectedDate, appointmentTime: time)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissAllModals"))) { _ in
            dismiss()
        }
    }
}

struct TimeSlotButton: View {
    let time: Date
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(time.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.teal : Color.white)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.teal, lineWidth: 1)
                )
        }
    }
}
