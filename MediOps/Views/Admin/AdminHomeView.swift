import SwiftUI

// MARK: - Models
struct UIDoctor: Identifiable {
    var id: String = UUID().uuidString
    var fullName: String
    var specialization: String
    var email: String
    var phone: String
    var gender: Gender
    var dateOfBirth: Date
    var experience: Int
    var qualification: String
    var license: String
    var address: String
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        
        var id: String { self.rawValue }
    }
}

struct UILabAdmin: Identifiable {
    var id = UUID()
    var fullName: String
    var email: String
    var phone: String
    var gender: Gender
    var dateOfBirth: Date
    var experience: Int
    var qualification: String
    var address: String
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        
        var id: String { self.rawValue }
    }
}

struct UIActivity: Identifiable {
    var id = UUID()
    var type: ActivityType
    var title: String
    var timestamp: Date
    var status: ActivityStatus
    var doctorDetails: UIDoctor?
    var labAdminDetails: UILabAdmin?
    var hospitalDetails: UIHospital?
    
    enum ActivityType {
        case doctorAdded
        case labAdminAdded
        case hospitalAdded
    }
    
    enum ActivityStatus {
        case pending
        case approved
        case rejected
        case completed
    }
}

// MARK: - Modified Admin Dashboard Card
struct AdminDashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

// MARK: - Admin Stat Card
struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.teal)
                    Spacer()
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var destinationView: some View {
        switch title {
        case "Doctors":
            DoctorsListView()
        case "Lab Admins":
            Text("Lab Admins List") // Replace with actual view when created
        default:
            EmptyView()
        }
    }
}

// MARK: - Modified Admin Home View
struct AdminHomeView: View {
    @State private var showAddLabAdmin = false
    @State private var showProfile = false
    @State private var recentActivities: [UIActivity] = []
    @State private var doctorCount = 0
    @State private var labAdminCount = 0
    
    private func updateStatistics() {
        doctorCount = recentActivities.filter { $0.type == .doctorAdded && $0.status != .rejected }.count
        labAdminCount = recentActivities.filter { $0.type == .labAdminAdded && $0.status != .rejected }.count
    }
    
    var body: some View {
        NavigationStack {
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
                            showProfile = true
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
                        GridItem(.flexible())
                    ], spacing: 15) {
                        AdminStatCard(title: "Doctors", value: "\(doctorCount)", icon: "stethoscope")
                        AdminStatCard(title: "Lab Admins", value: "\(labAdminCount)", icon: "flask.fill")
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // Add Lab Admin
                        AdminDashboardCard(
                            title: "Add Lab Admin",
                            icon: "flask.fill",
                            color: .green,
                            action: { showAddLabAdmin = true }
                        )
                    }
                    .padding()
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if recentActivities.isEmpty {
                            Text("No recent activity")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                        } else {
                            ForEach(recentActivities) { activity in
                                ActivityRow(activity: activity) { updatedActivity in
                                    if let index = recentActivities.firstIndex(where: { $0.id == activity.id }) {
                                        recentActivities[index] = updatedActivity
                                    }
                                } onDelete: { deletedActivity in
                                    if let index = recentActivities.firstIndex(where: { $0.id == deletedActivity.id }) {
                                        recentActivities.remove(at: index)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddLabAdmin) {
                AddLabAdminView { activity in
                    recentActivities.insert(activity, at: 0)
                    updateStatistics()
                }
            }
            .sheet(isPresented: $showProfile) {
                AdminProfileView()
            }
        }
    }
} 