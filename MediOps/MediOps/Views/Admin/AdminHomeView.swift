import SwiftUI

// MARK: - Models
struct Doctor: Identifiable {
    var id: String = UUID().uuidString
    var fullName: String
    var specialization: String
    var email: String
    var phone: String // This will store the full phone number including +91
    var gender: Gender
    var dateOfBirth: Date
    var experience: Int
    var qualification: String
    var license: String
    var address: String // Added address field
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        
        var id: String { self.rawValue }
    }
}

struct LabAdmin: Identifiable {
    var id = UUID()
    var fullName: String
    var email: String
    var phone: String // This will store the full phone number including +91
    var gender: Gender
    var dateOfBirth: Date
    var experience: Int
    var qualification: String
    var address: String // Added address field
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        
        var id: String { self.rawValue }
    }
}

struct Activity: Identifiable {
    var id = UUID()
    var type: ActivityType
    var title: String
    var timestamp: Date
    var status: ActivityStatus
    var doctorDetails: Doctor?  // Added to store doctor details
    var labAdminDetails: LabAdmin?  // Added to store lab admin details
    
    enum ActivityType {
        case doctorAdded
        case labAdminAdded
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

// MARK: - Modified Admin Home View
struct AdminHomeView: View {
    @State private var showAddDoctor = false
    @State private var showAddLabAdmin = false
    @State private var showProfile = false
    @State private var recentActivities: [Activity] = []
    @State private var doctorCount = 0
    @State private var labAdminCount = 0
    
    private func updateStatistics() {
        // Update counts based on activities
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
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // Add Doctor
                        AdminDashboardCard(
                            title: "Add Doctor",
                            icon: "person.badge.plus",
                            color: .blue,
                            action: { showAddDoctor = true }
                        )
                        
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
                                    // Handle edit
                                    if let index = recentActivities.firstIndex(where: { $0.id == activity.id }) {
                                        recentActivities[index] = updatedActivity
                                    }
                                } onDelete: { deletedActivity in
                                    // Handle delete
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
            .sheet(isPresented: $showAddDoctor) {
                AddDoctorView { activity in
                    recentActivities.insert(activity, at: 0)
                    updateStatistics()
                }
            }
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

struct ActivityRow: View {
    let activity: Activity
    let onEdit: (Activity) -> Void
    let onDelete: (Activity) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.title)
                    .font(.system(size: 16, weight: .medium))
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Status indicator
            Text(activity.status == .pending ? "Pending" : "")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            
            // Three dots menu
            Menu {
                Button(action: { onEdit(activity) }) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: { onDelete(activity) }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

#Preview {
    AdminHomeView()
}
