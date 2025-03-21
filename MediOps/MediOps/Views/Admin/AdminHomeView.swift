import SwiftUI

// MARK: - Models
struct DoctorView: Identifiable {
    var id = UUID()
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

struct LabAdminView: Identifiable {
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
    var doctorDetails: DoctorView?  // Added to store doctor details
    var labAdminDetails: LabAdmin?  // Added to store lab admin details
    
    enum ActivityType {
        case doctorAdded
        case labAdminAdded
    }
    
    enum ActivityStatus {
        case pending
        case approved
        case rejected
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

// MARK: - Add Doctor View
struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var specialization = ""
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: Doctor.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var qualification = ""
    @State private var license = ""
    @State private var address = "" // Added address state
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onSave: (Activity) -> Void
    
    // Calculate maximum experience based on age
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25) // Experience should be 19 years less than doctor's age
    }
    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !specialization.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !qualification.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(Doctor.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              displayedComponents: .date)
                    .onChange(of: dateOfBirth) { _, _ in
                        // Adjust experience if it exceeds the maximum allowed
                        if experience > maximumExperience {
                            experience = maximumExperience
                        }
                    }
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Specialization", text: $specialization)
                    TextField("Qualification", text: $qualification)
                    
                    // Updated license field with more general format hint
                    TextField("License (XX12345)", text: $license)
                        .onChange(of: license) { _, newValue in
                            // Format license to uppercase
                            license = newValue.uppercased()
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                        .onChange(of: experience) { _, newValue in
                            // Enforce the maximum experience constraint
                            if newValue > maximumExperience {
                                experience = maximumExperience
                            }
                        }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Updated phone field with prefix
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                // Keep only digits and limit to 10
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    // Changed to TextField for address
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDoctor()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func saveDoctor() {
        // Basic input validation
        if fullName.isEmpty {
            alertMessage = "Please enter the doctor's full name"
            showAlert = true
            return
        }
        
        if specialization.isEmpty {
            alertMessage = "Please enter the doctor's specialization"
            showAlert = true
            return
        }
        
        if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        // Updated phone validation
        if phoneNumber.count != 10 {
            alertMessage = "Please enter a valid 10-digit phone number"
            showAlert = true
            return
        }
        
        if qualification.isEmpty {
            alertMessage = "Please enter the doctor's qualification"
            showAlert = true
            return
        }
        
        // Updated license validation
        if !isValidLicense(license) {
            alertMessage = "Please enter a valid license in the format XX12345 (2 letters followed by 5 digits)"
            showAlert = true
            return
        }
        
        // Added address validation
        if address.isEmpty {
            alertMessage = "Please enter the doctor's address"
            showAlert = true
            return
        }
        
        // Create a new doctor with full formatted phone number
        let doctor = Doctor(
            fullName: fullName,
            specialization: specialization,
            email: email,
            phone: "+91\(phoneNumber)", // Combine the prefix and number
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            license: license,
            address: address
        )
        
        // Create a new activity with the doctor details
        let activity = Activity(
            type: .doctorAdded,
            title: "New Doctor: \(doctor.fullName)",
            timestamp: Date(),
            status: .pending,
            doctorDetails: doctor,
            labAdminDetails: nil
        )
        
        // Call onSave callback with the new activity
        onSave(activity)
        
        // Dismiss the view immediately
        dismiss()
    }
    
    private func resetForm() {
        fullName = ""
        specialization = ""
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        qualification = ""
        license = ""
        address = "" // Reset address
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // Updated license validation function to accept any 2 letters followed by 5 digits
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
}

// MARK: - Add Lab Admin View
struct AddLabAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: LabAdmin.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var qualification = ""
    @State private var license = ""
    @State private var address = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onSave: (Activity) -> Void
    
    // Calculate maximum experience based on age
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25) // Experience should be 25 years less than admin's age
    }
    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !qualification.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(LabAdmin.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              displayedComponents: .date)
                    .onChange(of: dateOfBirth) { _, _ in
                        // Adjust experience if it exceeds the maximum allowed
                        if experience > maximumExperience {
                            experience = maximumExperience
                        }
                    }
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    TextField("License (XX12345)", text: $license)
                        .onChange(of: license) { _, newValue in
                            // Format license to uppercase
                            license = newValue.uppercased()
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                        .onChange(of: experience) { _, newValue in
                            // Enforce the maximum experience constraint
                            if newValue > maximumExperience {
                                experience = maximumExperience
                            }
                        }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                // Keep only digits and limit to 10
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Add Lab Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLabAdmin()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func saveLabAdmin() {
        // Basic input validation
        if fullName.isEmpty {
            alertMessage = "Please enter the lab admin's full name"
            showAlert = true
            return
        }
        
        if !isValidEmail(email) {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        if phoneNumber.count != 10 {
            alertMessage = "Please enter a valid 10-digit phone number"
            showAlert = true
            return
        }
        
        if qualification.isEmpty {
            alertMessage = "Please enter the lab admin's qualification"
            showAlert = true
            return
        }
        
        if !isValidLicense(license) {
            alertMessage = "Please enter a valid license in the format XX12345 (2 letters followed by 5 digits)"
            showAlert = true
            return
        }
        
        if address.isEmpty {
            alertMessage = "Please enter the lab admin's address"
            showAlert = true
            return
        }
        
        // Create a new lab admin with full formatted phone number
        let labAdmin = LabAdmin(
            fullName: fullName,
            email: email,
            phone: "+91\(phoneNumber)",
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            address: address
        )
        
        // Create a new activity with the lab admin details
        let activity = Activity(
            type: .labAdminAdded,
            title: "New Lab Admin: \(labAdmin.fullName)",
            timestamp: Date(),
            status: .pending,
            doctorDetails: nil,
            labAdminDetails: labAdmin
        )
        
        // Call onSave callback with the new activity
        onSave(activity)
        
        // Dismiss the view immediately
        dismiss()
    }
    
    private func resetForm() {
        fullName = ""
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        qualification = ""
        license = ""
        address = ""
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
}

// MARK: - Modified Admin Home View
struct AdminHomeView: View {
    @State private var showAddDoctor = false
    @State private var showAddLabAdmin = false
    @State private var recentActivities: [Activity] = []
    
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
                        GridItem(.flexible())
                    ], spacing: 15) {
                        AdminStatCard(title: "Doctors", value: "0", icon: "stethoscope")
                        AdminStatCard(title: "Lab Admins", value: "0", icon: "flask.fill")
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
                }
            }
            .sheet(isPresented: $showAddLabAdmin) {
                AddLabAdminView { activity in
                    recentActivities.insert(activity, at: 0)
                }
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
