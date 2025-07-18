import SwiftUI

// View to display appointment history
struct AppointmentHistoryView: View {
    @StateObject private var appointmentManager = AppointmentManager.shared
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var translationManager = TranslationManager.shared
    
    var body: some View {
        List {
            // Filter appointments by status
            let completedAppointments = appointmentManager.appointments.filter { $0.status == .completed }
            let cancelledAppointments = appointmentManager.appointments.filter { $0.status == .cancelled }
            let missedAppointments = appointmentManager.appointments.filter { $0.status == .missed }
            
            if completedAppointments.isEmpty && cancelledAppointments.isEmpty && missedAppointments.isEmpty {
                Text("no_appointment_history".localized)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                if !completedAppointments.isEmpty {
                    Section(header: Text("completed_appointments".localized).foregroundColor(.teal)) {
                        ForEach(completedAppointments) { appointment in
                            NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                AppointmentHistoryCard(appointment: appointment)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .listRowBackground(Color.green.opacity(0.1))
                        }
                    }
                }
                
                if !missedAppointments.isEmpty {
                    Section(header: Text("missed_appointments".localized).foregroundColor(.teal)) {
                        ForEach(missedAppointments) { appointment in
                            AppointmentHistoryCard(appointment: appointment, isMissed: true)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.orange.opacity(0.1))
                        }
                    }
                }
                
                if !cancelledAppointments.isEmpty {
                    Section(header: Text("cancelled_appointments".localized).foregroundColor(.teal)) {
                        ForEach(cancelledAppointments) { appointment in
                            AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.red.opacity(0.1))
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden) // Hide default list background
        .refreshable {
            print("🔄 Manually refreshing appointments history")
            appointmentManager.refreshAppointments()
        }
        .navigationTitle("appointment_history".localized)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Color.teal.opacity(0.1), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            print("📱 AppointmentHistoryView appeared - refreshing appointments")
            appointmentManager.refreshAppointments()
        }
        .localizedLayout()
    }
} 