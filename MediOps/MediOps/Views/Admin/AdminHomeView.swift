import SwiftUI

// MARK: - Models
struct UIDoctor: Identifiable {
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
    var maxAppointments: Int = 8 // Default value for max appointments
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Male"
        case female = "Female"
        
        var id: String { self.rawValue }
    }
}

struct UILabAdmin: Identifiable {
    var id = UUID()
    var originalId: String? // Store the original Supabase ID (e.g., LAB001)
    var fullName: String
    var email: String
    var phone: String // This will store the full phone number including +91
    var gender: Gender
    var dateOfBirth: Date
    var experience: Int
    var qualification: String
    var license: String? // License number field
    var address: String // Added address field
    
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
    var doctorDetails: UIDoctor?  // Updated to use UIDoctor
    var labAdminDetails: UILabAdmin?  // Updated to use UILabAdmin
    var hospitalDetails: UIHospital? // Added hospital details
    
    enum ActivityType {
        case doctorAdded
        case labAdminAdded
        case hospitalAdded // Added new activity type
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

// MARK: - Blood Donation Card
struct BloodDonationCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Blood Donation Request")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Send requests to registered donors")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

// MARK: - Blood Donors List Card
struct BloodDonorsListCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Blood Donors")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("View all registered blood donors")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

// MARK: - Analytics Card
struct AnalyticsCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hospital Revenue")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("View appointment revenue analytics")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

// MARK: - Modified Admin Home View
struct AdminHomeView: View {
    @State private var showAddDoctor = false
    @State private var showAddLabAdmin = false
    @State private var showProfile = false
    @State private var showBloodDonationRequest = false
    @State private var showAllBloodDonors = false
    @State private var showHospitalAnalytics = false
    @State private var recentActivities: [UIActivity] = []
    @State private var doctors: [UIDoctor] = []
    @State private var labAdmins: [UILabAdmin] = []
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let adminController = AdminController.shared
    
    private var doctorCount: Int {
        doctors.count
    }
    
    private var labAdminCount: Int {
        labAdmins.count
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
                    
                    if isLoggedIn {
                        // Quick action
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            AdminStatCard(
                                title: "Doctors",
                                value: "\(doctorCount)",
                                icon: "stethoscope",
                                doctors: $doctors
                            )
                            AdminStatCard(
                                title: "Lab Admins",
                                value: "\(labAdminCount)",
                                icon: "flask.fill",
                                labAdmins: $labAdmins
                            )
                        }
                        .padding(.horizontal)
                        
                        // Add Blood Donation Card here
                        BloodDonationCard {
                            showBloodDonationRequest = true
                        }
                        .padding(.horizontal)
                        
                        // Add Blood Donors List Card
                        BloodDonorsListCard {
                            showAllBloodDonors = true
                        }
                        .padding(.horizontal)
                        
                        // Add Analytics Card
                        AnalyticsCard {
                            showHospitalAnalytics = true
                        }
                        .padding(.horizontal)
                    }
                    
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
            .task {
                await checkLoginAndFetchData()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showAddDoctor) {
                AddDoctorView { activity in
                    recentActivities.insert(activity, at: 0)
                    if let doctor = activity.doctorDetails {
                        doctors.append(doctor)
                    }
                }
            }
            .sheet(isPresented: $showAddLabAdmin) {
                AddLabAdminView { activity in
                    recentActivities.insert(activity, at: 0)
                    if let labAdmin = activity.labAdminDetails {
                        labAdmins.append(labAdmin)
                    }
                }
            }
            .sheet(isPresented: $showBloodDonationRequest) {
                BloodDonationRequestView()
            }
            .sheet(isPresented: $showAllBloodDonors) {
                AllBloodDonorsView()
            }
            .sheet(isPresented: $showHospitalAnalytics) {
                HospitalAnalyticsView()
            }
            .sheet(isPresented: $showProfile) {
                HospitalAdminProfileView()
            }
        }
    }
    
    private func checkLoginAndFetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check if user is logged in by verifying hospital_id in UserDefaults
        if let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") {
            isLoggedIn = true
            
            // Activity logging has been disabled
            
            do {
                // Fetch doctors
                let fetchedDoctors = try await adminController.getDoctorsByHospitalAdmin(hospitalAdminId: hospitalId)
                doctors = fetchedDoctors.map { doctor in
                    UIDoctor(
                        id: doctor.id,
                        fullName: doctor.name,
                        specialization: doctor.specialization,
                        email: doctor.email,
                        phone: doctor.contactNumber ?? "",
                        gender: .male, // Default value
                        dateOfBirth: Date(), // Default value
                        experience: doctor.experience,
                        qualification: doctor.qualifications.joined(separator: ", "),
                        license: doctor.licenseNo,
                        address: doctor.addressLine
                    )
                }
                
                // Fetch lab admins
                let fetchedLabAdmins = try await adminController.getLabAdmins(hospitalAdminId: hospitalId)
                labAdmins = fetchedLabAdmins.map { labAdmin in
                    UILabAdmin(
                        originalId: labAdmin.id,
                        fullName: labAdmin.name,
                        email: labAdmin.email,
                        phone: labAdmin.contactNumber ?? "",
                        gender: .male, // Default value
                        dateOfBirth: labAdmin.dateOfBirth ?? Date(), // Use actual DOB from Supabase with fallback
                        experience: labAdmin.experience, // Use actual experience from Supabase
                        qualification: labAdmin.department,
                        license: labAdmin.licenseNo,
                        address: labAdmin.address
                    )
                }
            } catch {
                errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                showError = true
            }
        } else {
            isLoggedIn = false
        }
    }
}

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    var doctors: Binding<[UIDoctor]>? = nil
    var labAdmins: Binding<[UILabAdmin]>? = nil
    
    var body: some View {
        NavigationLink(destination: destinationView) {
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
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var destinationView: some View {
        switch title {
        case "Doctors":
            if let doctorsBinding = doctors {
                DoctorsListView(doctors: doctorsBinding)
            } else {
                DoctorsListView(doctors: .constant([]))
            }
        case "Lab Admins":
            if let labAdminsBinding = labAdmins {
                LabAdminsListView(labAdmins: labAdminsBinding)
            } else {
                LabAdminsListView(labAdmins: .constant([]))
            }
        default:
            EmptyView()
        }
    }
}

struct ActivityRow: View {
    let activity: UIActivity
    let onEdit: (UIActivity) -> Void
    let onDelete: (UIActivity) -> Void
    @State private var showDetail = false
    
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
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
            
            // Three dots menu
            Menu {
                Button(action: { 
                    showDetail = true
                }) {
                    Label("View Details", systemImage: "eye")
                }
                
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
        .sheet(isPresented: $showDetail) {
            ActivityDetailView(activity: activity)
        }
    }
    
    private var statusText: String {
        switch activity.status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .completed:
            return "Completed"
        }
    }
    
    private var statusColor: Color {
        switch activity.status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .completed:
            return .blue
        }
    }
}

#Preview {
    AdminHomeView()
}
