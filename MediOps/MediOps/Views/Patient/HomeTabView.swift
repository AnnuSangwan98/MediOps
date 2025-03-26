//
//  HomeTabView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct HomeTabView: View {
    @ObservedObject private var hospitalVM = HospitalViewModel.shared
    @StateObject private var appointmentManager = AppointmentManager.shared
    @State private var showProfile = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            historyTab
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                    Text("History")
                }
                .tag(1)
            
            bloodDonateTab
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "drop.fill" : "drop")
                    Text("Blood Donate")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
    
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGray6)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        searchAndFilterSection
                        
                        if !hospitalVM.searchText.isEmpty {
                            searchResultsSection
                        } else {
                            upcomingAppointmentsSection
                            
                            // Show all hospitals when not searching
                            VStack(alignment: .leading, spacing: 15) {
                                Text("All Hospitals")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                if hospitalVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else if let error = hospitalVM.error {
                                    Text("Error: \(error.localizedDescription)")
                                        .foregroundColor(.red)
                                        .padding()
                                } else if !hospitalVM.hospitals.isEmpty {
                                    ForEach(hospitalVM.hospitals) { hospital in
                                        NavigationLink {
                                            DoctorListView(hospital: hospital)
                                        } label: {
                                            HospitalCard(hospital: hospital)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal)
                                    }
                                } else {
                                    Text("No hospitals found")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
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
    
    private var historyTab: some View {
        NavigationStack {
            List {
                ForEach(appointmentManager.appointments.filter { $0.status == .completed }, id: \.id) { appointment in
                    AppointmentHistoryCard(appointment: appointment)
                }
            }
            .navigationTitle("Appointment History")
        }
    }
    
    private var bloodDonateTab: some View {
        Text("Blood Donation")
            .navigationTitle("Blood Donation")
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Search Results")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ForEach(hospitalVM.filteredHospitals) { hospital in
                NavigationLink {
                    DoctorListView(hospital: hospital)
                } label: {
                    HospitalCard(hospital: hospital)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
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
                PatientProfileView(profileController: PatientProfileController())
            }
        }
        .padding()
        .background(Color.white)
    }

    private var searchAndFilterSection: some View {
        HStack {
            HospitalSearchBar(searchText: $hospitalVM.searchText)
            cityFilterMenu
        }
        .padding(.horizontal)
    }

    private var cityFilterMenu: some View {
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
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.teal)
                .font(.title2)
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
                    .padding(.horizontal)
            } else {
                ForEach(appointmentManager.appointments.filter { $0.status == .upcoming }) { appointment in
                    AppointmentCard(appointment: appointment)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

struct AppointmentHistoryCard: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                    Text(appointment.doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "calendar")
                Text(appointment.date.formatted(date: .long, time: .omitted))
                Spacer()
                Image(systemName: "clock")
                Text(appointment.time.formatted(date: .omitted, time: .shortened))
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}
