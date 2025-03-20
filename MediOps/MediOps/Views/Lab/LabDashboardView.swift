import SwiftUI

struct LabDashboardView: View {
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
                            Text("Welcome, Lab")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Laboratory Dashboard")
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
                        // Test Reports
                        DashboardCard(
                            title: "Test Reports",
                            icon: "doc.text",
                            color: .blue
                        )
                        
                        // Sample Collection
                        DashboardCard(
                            title: "Sample Collection",
                            icon: "cross.case",
                            color: .green
                        )
                        
                        // Test Results
                        DashboardCard(
                            title: "Test Results",
                            icon: "checkmark.circle",
                            color: .purple
                        )
                        
                        // Analytics
                        DashboardCard(
                            title: "Analytics",
                            icon: "chart.bar",
                            color: .orange
                        )
                    }
                    .padding()
                    
                    // Recent Tests
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Tests")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Placeholder for tests list
                        Text("No recent tests")
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


#Preview {
    LabDashboardView()
} 
