import SwiftUI

struct PatientHomeView: View {
    @StateObject private var hospitalVM = HospitalViewModel()
    @StateObject private var appointmentManager = AppointmentManager.shared
    @StateObject private var profileController = PatientProfileController()
    @State private var showProfile = false


    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent
            }
            .navigationBarHidden(true)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                searchAndFilterSection
                searchResultsSection
                upcomingAppointmentsSection
                quickActionsGrid
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome Back!")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Your Health Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            Button(action: {
                showProfile.toggle()
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.teal)
            }
            .sheet(isPresented: $showProfile) {
                PatientProfileView(profileController: profileController)
            }

        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var searchAndFilterSection: some View {
        VStack(spacing: 10) {
            HStack {
                HospitalSearchBar(searchText: $hospitalVM.searchText)
                cityFilterMenu
            }
        }
        .padding(.horizontal)
    }

    private var cityFilterMenu: some View {
        Menu {
            ForEach(hospitalVM.availableCities, id: \ .self) { city in
                Button(action: {
                    hospitalVM.selectedCity = hospitalVM.selectedCity == city ? nil : city
                }) {
                    HStack {
                        Text(city)
                        if hospitalVM.selectedCity == city {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Button("Clear Filter", action: { hospitalVM.selectedCity = nil })
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.teal)
                .font(.title2)
        }
    }

    private var searchResultsSection: some View {
        Group {
            if !hospitalVM.searchText.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Search Results")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if hospitalVM.filteredHospitals.isEmpty {
                        Text("No hospitals found")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        LazyVStack(spacing: 15) {
                            ForEach(hospitalVM.filteredHospitals) { hospital in
                                NavigationLink(destination: DoctorListView(hospitalName: hospital.name, hospital: hospital)) {
                                    HospitalCard(hospital: hospital)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Upcoming Appointments")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if appointmentManager.upcomingAppointments.count > 1 {
                    NavigationLink(destination: AllAppointmentsView()) {
                        Text("See All")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if appointmentManager.upcomingAppointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.1), radius: 5)
            } else {
                ForEach(appointmentManager.upcomingAppointments.prefix(1)) { appointment in
                    AppointmentCard(appointment: appointment)
                }
            }
        }
        .padding()
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            DashboardCard(title: "Appointments", icon: "calendar", color: .blue)
            DashboardCard(title: "Medical Records", icon: "doc.text", color: .green)
            DashboardCard(title: "Prescriptions", icon: "pills", color: .purple)
            DashboardCard(title: "Lab Reports", icon: "cross.case", color: .orange)
        }
        .padding()
    }
}

struct AppointmentCard: View {
    @State private var showCancelAlert = false
    @State private var showRescheduleSheet = false
    let appointment: Appointment
    
    private var isWithin12Hours: Bool {
        let appointmentDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: appointment.time),
                                                      minute: Calendar.current.component(.minute, from: appointment.time),
                                                      second: 0,
                                                      of: appointment.date) ?? appointment.date
        
        let timeDifference = appointmentDateTime.timeIntervalSince(Date())
        return timeDifference <= 12 * 3600 // 12 hours in seconds
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
                Text(appointment.time.formatted(date: .omitted, time: .shortened))
            }

            HStack(spacing: 12) {
                Button(action: { showCancelAlert = true }) {
                    Text("Cancel Appointment")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isWithin12Hours)
                .opacity(isWithin12Hours ? 0.5 : 1)
                .alert(isPresented: $showCancelAlert) {
                    Alert(
                        title: Text("Cancel Appointment"),
                        message: Text("Are you sure you want to cancel this appointment?"),
                        primaryButton: .destructive(Text("Yes")) {
                            AppointmentManager.shared.cancelAppointment(appointment)
                        },
                        secondaryButton: .cancel()
                    )
                }

                Button(action: { showRescheduleSheet = true }) {
                    Text("Reschedule")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isWithin12Hours)
                .opacity(isWithin12Hours ? 0.5 : 1)
                .sheet(isPresented: $showRescheduleSheet) {
                    AppointmentView(
                        doctor: appointment.doctor,
                        existingAppointment: appointment,
                        onUpdateAppointment: { updatedAppointment in
                            AppointmentManager.shared.updateAppointment(updatedAppointment)
                        }
                    )
                }
            }
            
            if isWithin12Hours {
                Text("Appointments cannot be modified within 12 hours of the scheduled time")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct AllAppointmentsView: View {
    @StateObject private var appointmentManager = AppointmentManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(appointmentManager.upcomingAppointments) { appointment in
                    AppointmentCard(appointment: appointment)
                }
            }
            .padding()
        }
        .navigationTitle("Appointments")
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

#Preview {
    PatientHomeView()
}
