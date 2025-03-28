import SwiftUI

struct PatientHomeView: View {
    @EnvironmentObject private var navigationState: AppNavigationState
    
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
                                // TODO: Navigate to profile
                            }) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.teal)
                                    .background(Circle().fill(Color.white))
                                    .shadow(color: .gray.opacity(0.2), radius: 3)
                            }
                            .padding(.trailing)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
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
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
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
