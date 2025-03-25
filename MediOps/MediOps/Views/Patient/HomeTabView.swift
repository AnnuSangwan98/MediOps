//
//  HomeTabView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct HomeTabView: View {
    @StateObject private var hospitalVM = HospitalViewModel()
    @StateObject private var appointmentManager = AppointmentManager.shared
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        headerSection
                        searchAndFilterSection

                        if !hospitalVM.searchText.isEmpty {
                            if hospitalVM.filteredHospitals.isEmpty {
                                Text("No hospitals found")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Search Results")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)

                                    ForEach(hospitalVM.filteredHospitals) { hospital in
                                        NavigationLink(destination: DoctorListView(hospitalName: hospital.name, hospital: hospital)) {
                                            HospitalCard(hospital: hospital)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .padding()
                            }
                        } else {
                            upcomingAppointmentsSection
                        }
                    }
                }
            }
            .navigationBarHidden(true)
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
            HStack {
                Text("Upcoming Appointments")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading, 5)

                Spacer()

                if appointmentManager.appointments.count > 1 {
                    NavigationLink(destination: AllAppointmentsView(appointments: appointmentManager.appointments)) {
                        Text("See All")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
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
                ForEach(appointmentManager.appointments.prefix(1)) { appointment in
                    AppointmentCard(appointment: appointment)
                }
            }
        }
        .padding()
    }
}
