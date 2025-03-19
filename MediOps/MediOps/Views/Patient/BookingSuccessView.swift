import SwiftUI

struct BookingSuccessView: View {
    let doctor: DoctorDetail
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @State private var shouldPopToRoot = false
    
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
                    
                    HStack {
                        Image(systemName: "video.fill")
                        Text("Online Consultation")
                    }
                    .foregroundColor(.teal)
                    
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
                    // This will dismiss all sheets and modals
                    NotificationCenter.default.post(name: NSNotification.Name("DismissAllModals"), object: nil)
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
