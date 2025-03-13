import SwiftUI

struct DoctorHomeView: View {
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
                                Text("Welcome, Dr.")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Your Practice Dashboard")
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
                        
                        // Today's Summary
                        HStack(spacing: 20) {
                            StatCard(title: "Appointments", value: "0", icon: "calendar")
                            StatCard(title: "Patients", value: "0", icon: "person.2")
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            // Schedule
                            DoctorDashboardCard(
                                title: "Schedule",
                                icon: "calendar.badge.clock",
                                color: .blue
                            )
                            
                            // Patient Records
                            DoctorDashboardCard(
                                title: "Patient Records",
                                icon: "folder.fill",
                                color: .green
                            )
                            
                            // Prescriptions
                            DoctorDashboardCard(
                                title: "Prescriptions",
                                icon: "doc.text.fill",
                                color: .purple
                            )
                            
                            // Lab Orders
                            DoctorDashboardCard(
                                title: "Lab Orders",
                                icon: "cross.case.fill",
                                color: .orange
                            )
                        }
                        .padding()
                        
                        // Upcoming Appointments
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Today's Appointments")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Placeholder for appointments list
                            Text("No appointments scheduled")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.teal)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct DoctorDashboardCard: View {
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
    DoctorHomeView()
} 