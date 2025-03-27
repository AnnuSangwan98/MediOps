import SwiftUI

struct HomeView: View {
    @StateObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
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
                        }
                        .padding()
                        .background(Color.white)
                        
                        // Search Section
                        VStack(spacing: 10) {
                            TextField("Search hospitals...", text: $hospitalVM.searchText)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 5)
                            
                            if !hospitalVM.availableCities.isEmpty {
                                Menu {
                                    ForEach(hospitalVM.availableCities, id: \.self) { city in
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
                                    HStack {
                                        Image(systemName: "location.circle.fill")
                                        Text(hospitalVM.selectedCity ?? "Select City")
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 5)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Upcoming Appointments Section
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
                                    .padding(.horizontal)
                            } else {
                                ForEach(appointmentManager.appointments.filter { $0.status == .upcoming }) { appointment in
                                    AppointmentCard(appointment: appointment)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Hospitals List
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Hospitals")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            if hospitalVM.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if let error = hospitalVM.error {
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                ForEach(hospitalVM.filteredHospitals) { hospital in
                                    NavigationLink(destination: DoctorListView(hospital: hospital)) {
                                        HospitalCard(hospital: hospital)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await hospitalVM.fetchHospitals()
                await hospitalVM.fetchAvailableCities()
                
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    try? await hospitalVM.fetchAppointments(for: userId)
                }
            }
        }
    }
}