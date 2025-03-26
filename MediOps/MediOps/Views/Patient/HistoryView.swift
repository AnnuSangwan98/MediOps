//
//  Untitled.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var selectedSegment = "Completed"
    let segments = ["Completed", "Upcoming", "Canceled"]

    var body: some View {
        VStack {
            Text("My Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Spacer()
            
            Picker("Select", selection: $selectedSegment) {
                ForEach(segments, id: \.self) { segment in
                    Text(segment).tag(segment)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    if selectedSegment == "Completed" {
                        HistoryAppointmentCard(
                            doctorName: "Dr. Rami Ahmed",
                            specialty: "Dentist Specialist",
                            date: "15 Aug 2023",
                            time: "5:00 PM",
                            status: "Completed"
                        )

                        HistoryAppointmentCard(
                            doctorName: "Dr. Ali Ahmed",
                            specialty: "General Specialist",
                            date: "14 Aug 2023",
                            time: "6:30 PM",
                            status: "Completed"
                        )
                    } else if selectedSegment == "Upcoming" {
                        HistoryAppointmentCard(
                            doctorName: "Dr. Sara Khan",
                            specialty: "Cardiologist",
                            date: "20 Mar 2025",
                            time: "11:00 AM",
                            status: "Upcoming"
                        )
                    } else if selectedSegment == "Canceled" {
                        HistoryAppointmentCard(
                            doctorName: "Dr. Ahmed Yusuf",
                            specialty: "Orthopedic Specialist",
                            date: "10 Mar 2025",
                            time: "2:00 PM",
                            status: "Canceled"
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Appointment History")
    }
}

struct HistoryAppointmentCard: View {
    let doctorName: String
    let specialty: String
    let date: String
    let time: String
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 15) {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(doctorName)
                        .font(.headline)
                    Text(specialty)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            HStack {
                Label(date, systemImage: "calendar")
                Label(time, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.gray)

            Text(status)
                .font(.subheadline)
                .foregroundColor(status == "Canceled" ? .red : (status == "Upcoming" ? .orange : .green))

            Divider()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
