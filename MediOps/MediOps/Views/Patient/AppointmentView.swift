import SwiftUI

struct AppointmentView: View {
    let doctor: DoctorDetail
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime: Date?
    @State private var showReviewAndPay = false
    
    private let timeSlots = stride(from: 6, through: 22, by: 0.5).map { hour in
        Calendar.current.date(bySettingHour: Int(hour), minute: Int((hour.truncatingRemainder(dividingBy: 1) * 60)), second: 0, of: Date())!
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Doctor Info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(doctor.name)
                                .font(.title2)
                            Text(doctor.specialization)
                                .foregroundColor(.gray)
                            Text(doctor.qualification)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // Stats
                    HStack(spacing: 30) {
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                Text("Total Experience")
                            }
                            Text("\(doctor.experience)+ Years")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Rating")
                            }
                            Text("\(doctor.rating) (\(doctor.numberOfRatings))")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                Text("Fee")
                            }
                            Text("$\(Int(doctor.consultationFee))")
                                .font(.headline)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    
                    // Calendar
                    Text("Available Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Date selection
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    // Time slots
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
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            
            // Book appointment button
            Button(action: { showReviewAndPay.toggle() }) {
                Text("Book Appointment")
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
