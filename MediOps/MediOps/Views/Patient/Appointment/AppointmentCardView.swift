//
//  AppointmentCardView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct AppointmentCard: View {
    @State private var showCancelAlert = false
    let appointment: Appointment
    
    private func formatTimeRange(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: time)
        
        // Calculate end time (1 hour after start time)
        if let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: time) {
            let endTimeString = formatter.string(from: endTime)
            return "\(startTime) to \(endTimeString)"
        }
        
        return startTime
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.teal)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                    Text(appointment.doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(appointment.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.1))
                    .foregroundColor(.teal)
                    .cornerRadius(8)
            }

            Divider()

            HStack {
                Image(systemName: "calendar")
                Text(appointment.date.formatted(date: .long, time: .omitted))
            }

            HStack {
                Image(systemName: "clock")
                Text(formatTimeRange(appointment.time))
            }

            // Centered Cancel Button
            Button(action: { showCancelAlert = true }) {
                Text("Cancel Appointment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .alert(isPresented: $showCancelAlert) {
                Alert(
                    title: Text("Cancel Appointment"),
                    message: Text("Are you sure you want to cancel this appointment?"),
                    primaryButton: .destructive(Text("Yes")) {
                        AppointmentManager.shared.cancelAppointment(appointment.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct AllAppointmentsView: View {
    let appointments: [Appointment]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(appointments) { appointment in
                    AppointmentCard(appointment: appointment)
                }
            }
            .padding()
        }
        .navigationTitle("Appointments")
    }
}
