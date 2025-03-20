import SwiftUI

struct SuperAdminDashboardView: View {
    var body: some View {
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
                            Text("Welcome, Super Admin")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Hospital Management Dashboard")
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
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // Hospital Management
                        DashboardCard(
                            title: "Hospitals",
                            icon: "building.2",
                            color: .blue
                        )
                        
                        // Admin Management
                        DashboardCard(
                            title: "Admins",
                            icon: "person.badge.key",
                            color: .green
                        )
                        
                        // Analytics
                        DashboardCard(
                            title: "Analytics",
                            icon: "chart.bar",
                            color: .purple
                        )
                        
                        // Settings
                        DashboardCard(
                            title: "Settings",
                            icon: "gear",
                            color: .orange
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

struct DashboardCards: View {
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
    SuperAdminDashboardView()
} 
