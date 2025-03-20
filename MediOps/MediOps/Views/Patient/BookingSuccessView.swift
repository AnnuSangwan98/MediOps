import SwiftUI

struct BookingSuccessView: View {
    let doctor: DoctorDetail
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appointmentManager = AppointmentManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Success animation
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                    
                    Text("Thanks, your booking has been confirmed.")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Please check your email for receipt and booking details.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Appointment details
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
                            Text(doctor.name)
                                .font(.headline)
                            Text(doctor.specialization)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
//                    HStack {
//                        Image(systemName: "video.fill")
//                        Text("Online Consultation")
//                    }
//                    .foregroundColor(.teal)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(appointmentDate.formatted(date: .long, time: .omitted))
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                        Text(appointmentTime.formatted(date: .omitted, time: .shortened))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add to calendar")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // Create and add new appointment
                    let appointment = Appointment(
                        doctor: doctor,
                        date: appointmentDate,
                        time: appointmentTime,
                        status: .upcoming
                    )
                    appointmentManager.addAppointment(appointment)
                    
                    // Set root view to PatientHomeView
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(rootView: PatientHomeView())
                    }
                }) {
                    Text("Done")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
    }
}
