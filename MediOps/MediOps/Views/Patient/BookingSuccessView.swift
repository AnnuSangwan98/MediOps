import SwiftUI
import EventKit

struct BookingSuccessView: View {
    let doctor: Doctor
    let appointmentDate: Date
    let appointmentTime: Date
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appointmentManager = AppointmentManager.shared
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAddingToCalendar = false
    @State private var isLoading = false
    
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    private func addToCalendar() {
        isAddingToCalendar = true
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted && error == nil {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = "Appointment with Dr. \(doctor.name)"
                    event.notes = "Medical consultation with \(doctor.name) (\(doctor.specialization))"
                    
                    // Combine date and time
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: appointmentDate)
                    let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: appointmentTime)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    
                    if let startDate = Calendar.current.date(from: components) {
                        event.startDate = startDate
                        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
                        event.calendar = eventStore.defaultCalendarForNewEvents
                        
                        do {
                            try eventStore.save(event, span: .thisEvent)
                            errorMessage = "Appointment added to calendar"
                            showError = true
                        } catch {
                            errorMessage = "Failed to add to calendar"
                            showError = true
                        }
                    }
                } else {
                    errorMessage = "Calendar access denied"
                    showError = true
                }
                isAddingToCalendar = false
            }
        }
    }
    
    private func saveAndNavigate() {
        isLoading = true
        
        // Create and add new appointment
        let appointment = Appointment(
            id: UUID().uuidString,
            doctor: doctor,
            date: appointmentDate,
            time: appointmentTime,
            status: AppointmentStatus.upcoming
        )
        
        // Store in Supabase and navigate to HomeTabView
        Task {
            do {
                // Add to local state
                appointmentManager.addAppointment(appointment)
                
                // Post notification to dismiss all modals
                NotificationCenter.default.post(name: NSNotification.Name("DismissAllModals"), object: nil)
                
                await MainActor.run {
                    isLoading = false
                    
                    // Navigate to HomeTabView
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let homeView = HomeTabView()
                            .environmentObject(hospitalVM)
                            .environmentObject(appointmentManager)
                        
                        window.rootViewController = UIHostingController(rootView: homeView)
                        window.makeKeyAndVisible()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error booking appointment: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    var body: some View {
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
                    Image(systemName: "calendar")
                    Text(appointmentDate.formatted(date: .long, time: .omitted))
                }
                
                HStack {
                    Image(systemName: "clock")
                    Text(formatTime(appointmentTime))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            
            Button(action: addToCalendar) {
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
            .disabled(isAddingToCalendar)
            
            Button(action: saveAndNavigate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    Text("Done")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $showError) {
            Alert(
                title: Text(errorMessage.contains("Error") ? "Error" : "Success"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
