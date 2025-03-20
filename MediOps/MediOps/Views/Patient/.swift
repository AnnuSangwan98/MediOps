import SwiftUI

struct PatientHomeView: View {
    @StateObject private var hospitalVM = HospitalViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
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
                        
                        // Search and Filter Section
                        VStack(spacing: 10) {
                            HStack {
                                HospitalSearchBar(searchText: $hospitalVM.searchText)
                                
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
                        }
                        .padding(.horizontal)
                        
                        // Hospitals List - Only show when searching
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
                                            NavigationLink(destination: DoctorListView(hospitalName: hospital.name)) {
                                                HospitalCard(hospital: hospital)
                                                    .padding(.horizontal)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Upcoming Appointments
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Upcoming Appointments")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Placeholder for appointments list
                            Text("No upcoming appointments")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                        .padding()
                        
                        // Quick Actions Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            // Appointments
                            DashboardCard(
                                title: "Appointments",
                                icon: "calendar",
                                color: .blue
                            )
                            
                            // Medical Records
                            DashboardCard(
                                title: "Medical Records",
                                icon: "doc.text",
                                color: .green
                            )
                            
                            // Prescriptions
                            DashboardCard(
                                title: "Prescriptions",
                                icon: "pills",
                                color: .purple
                            )
                            
                            // Lab Reports
                            DashboardCard(
                                title: "Lab Reports",
                                icon: "cross.case",
                                color: .orange
                            )
                        }
                        .padding()
                        
                    }
                }
            }
            .navigationBarHidden(true)
        }
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

#Preview {
    PatientHomeView()
}
