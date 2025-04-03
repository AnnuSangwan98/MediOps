import SwiftUI

// View to display appointment history
struct AppointmentHistoryView: View {
    @StateObject private var appointmentManager = AppointmentManager.shared
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var refreshID = UUID() // For UI refresh on theme change
    
    var body: some View {
        ZStack {
            // Apply themed background
            if themeManager.isPatient {
                themeManager.currentTheme.background
                    .ignoresSafeArea()
            }
            
            List {
                // Filter appointments by status
                let completedAppointments = appointmentManager.appointments.filter { $0.status == .completed }
                let cancelledAppointments = appointmentManager.appointments.filter { $0.status == .cancelled }
                let missedAppointments = appointmentManager.appointments.filter { $0.status == .missed }
                
                if completedAppointments.isEmpty && cancelledAppointments.isEmpty && missedAppointments.isEmpty {
                    Text("No Appointment History")
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(Color.clear)
                } else {
                    if !completedAppointments.isEmpty {
                        Section(header: Text("Completed Appointments").foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                            ForEach(completedAppointments) { appointment in
                                NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                    AppointmentHistoryCard(appointment: appointment)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                                .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.green.opacity(0.1))
                            }
                        }
                    }
                    
                    if !missedAppointments.isEmpty {
                        Section(header: Text("Missed Appointments").foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                            ForEach(missedAppointments) { appointment in
                                AppointmentHistoryCard(appointment: appointment, isMissed: true)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.orange.opacity(0.1))
                            }
                        }
                    }
                    
                    if !cancelledAppointments.isEmpty {
                        Section(header: Text("Cancelled Appointments").foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)) {
                            ForEach(cancelledAppointments) { appointment in
                                AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.red.opacity(0.1))
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
        }
        .navigationTitle("Appointment History")
        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(themeManager.isPatient ? themeManager.currentTheme.background : Color.teal.opacity(0.1), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Setup theme change listener
            setupThemeChangeListener()
            
            print("📱 AppointmentHistoryView appeared - refreshing appointments")
            appointmentManager.refreshAppointments()
        }
        .id(refreshID) // Force refresh when ID changes
    }
    
    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Generate new ID to force view refresh
            refreshID = UUID()
        }
    }
} 