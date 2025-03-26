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
        let startTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
        
        for hour in 0..<11 {
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
            VStack(spacing: 0) {
                // Calendar
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color.white)
                
                // Time slots
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 10), count: 4), spacing: 15) {
                        ForEach(timeSlots, id: \.self) { time in
                            let isSelected = selectedTime?.formatted(date: .omitted, time: .shortened) == time.formatted(date: .omitted, time: .shortened)
                            
                            Button(action: {
                                selectedTime = time
                            }) {
                                Text(time.formatted(date: .omitted, time: .shortened))
                                    .font(.subheadline)
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
                    .padding()
                }
                
                // Book button
                Button(action: {
                    showReviewAndPay = true
                }) {
                    Text("Book Appointment")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTime != nil ? Color.teal : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedTime == nil)
                .padding()
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .sheet(isPresented: $showReviewAndPay) {
                if let time = selectedTime {
                    ReviewAndPayView(doctor: doctor, appointmentDate: selectedDate, appointmentTime: time)
                }
            }
        }
    }
}
