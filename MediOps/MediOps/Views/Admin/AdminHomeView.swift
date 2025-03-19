import SwiftUI

struct AdminHomeView: View {
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
                                Text("Admin Dashboard")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("Hospital Management System")
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
                        
                        // Statistics Summary
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            AdminStatCard(title: "Doctors", value: "0", icon: "stethoscope")
                            AdminStatCard(title: "Patients", value: "0", icon: "person.2")
                            AdminStatCard(title: "Staff", value: "0", icon: "person.3")
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            // Manage Doctors
                            AdminDashboardCard(
                                title: "Manage Doctors",
                                icon: "person.badge.plus",
                                color: .blue
                            )
                            
                            // Manage Patients
                            AdminDashboardCard(
                                title: "Manage Patients",
                                icon: "person.2.fill",
                                color: .green
                            )
                            
                            // Departments
                            AdminDashboardCard(
                                title: "Departments",
                                icon: "building.2.fill",
                                color: .purple
                            )
                            
                            // Reports
                            AdminDashboardCard(
                                title: "Reports",
                                icon: "chart.bar.fill",
                                color: .orange
                            )
                            
                            // Settings
                            AdminDashboardCard(
                                title: "Settings",
                                icon: "gear",
                                color: .gray
                            )
                            
                            // Notifications
                            AdminDashboardCard(
                                title: "Notifications",
                                icon: "bell.fill",
                                color: .red
                            )
                        }
                        .padding()
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Activity")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            // Placeholder for activity list
                            Text("No recent activity")
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

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.teal)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

struct AdminDashboardCard: View {
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
    AdminHomeView()
} 