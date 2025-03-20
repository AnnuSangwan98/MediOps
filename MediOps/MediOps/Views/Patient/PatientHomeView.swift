import SwiftUI

struct PatientHomeView: View {
    
    @StateObject private var hospitalVM = HospitalViewModel()
    @StateObject private var appointmentManager = AppointmentManager.shared
    
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
                // TODO: Implement profile action
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.teal)
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
            ForEach(hospitalVM.availableCities, id: \.self) { city in
                Button(action: {
                    if hospitalVM.selectedCity == city {
                        hospitalVM.selectedCity = nil
                    } else {
                        hospitalVM.selectedCity = city
                    }
                }) {
                    HStack {
                        Text(city)
                        if hospitalVM.selectedCity == city {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Button("Clear Filter", action: {
                hospitalVM.selectedCity = nil
            })
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
            Text("Upcoming Appointments")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if appointmentManager.appointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.1), radius: 5)
            } else {
                ForEach(appointmentManager.appointments) { appointment in
                    AppointmentCard(appointment: appointment)
                }
            }
        }
        .padding()
    }
    
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            DashboardCard(
                title: "Appointments",
                icon: "calendar",
                color: .blue
            )
            
            DashboardCard(
                title: "Medical Records",
                icon: "doc.text",
                color: .green
            )
            
            DashboardCard(
                title: "Prescriptions",
                icon: "pills",
                color: .purple
            )
            
            DashboardCard(
                title: "Lab Reports",
                icon: "cross.case",
                color: .orange
            )
        }
        .padding()
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // TODO: Implement action
        }) {
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

struct AppointmentCard: View {
    let appointment: Appointment
    
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
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

#Preview {
    PatientHomeView()
}
