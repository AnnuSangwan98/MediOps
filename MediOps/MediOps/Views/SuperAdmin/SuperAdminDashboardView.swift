import SwiftUI

enum HospitalStatus: String {
    case pending = "Pending"
    case active = "Active"
    case inactive = "Inactive"
}

struct Hospital: Identifiable {
    let id: String
    var name: String
    var adminName: String
    var licenseNumber: String
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var phone: String
    var email: String
    var status: HospitalStatus
    var registrationDate: Date
    var lastModified: Date
    var lastModifiedBy: String
    
    static private var lastUsedNumber = 0
    
    static func generateUniqueID() -> String {
        lastUsedNumber += 1
        return String(format: "HOS%03d", lastUsedNumber)
    }
    
    // Helper function to reset counter (for testing purposes)
    static func resetIDCounter() {
        lastUsedNumber = 0
    }
}

struct SuperAdminDashboardView: View {
    @State private var showHospitalForm = false
    @State private var hospitalName = ""
    @State private var adminName = ""
    @State private var licenseNumber = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var showSuccessAlert = false
    @State private var showDeleteConfirmation = false
    @State private var hospitalToDelete: Hospital?
    @State private var showEditForm = false
    @State private var selectedHospital: Hospital?
    @State private var errorMessage = ""
    @State private var showError = false
    
    // Sample data - Replace with actual data source
    @State private var hospitals: [Hospital] = []
    
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
                        DashboardCards(
                            title: "Add Hospital",
                            icon: "building.2.fill",
                            color: .blue
                        ) {
                            showHospitalForm = true
                        }
                        
                        // Admin Management
                        DashboardCards(
                            title: "Admins",
                            icon: "person.badge.key",
                            color: .green
                        ) {
                            // Admin action
                        }
                        
                        // Analytics
                        DashboardCards(
                            title: "Analytics",
                            icon: "chart.bar",
                            color: .purple
                        ) {
                            // Analytics action
                        }
                        
                        // Settings
                        DashboardCards(
                            title: "Settings",
                            icon: "gear",
                            color: .orange
                        ) {
                            // Settings action
                        }
                    }
                    .padding()
                    
                    // Hospital List
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Hospitals")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if hospitals.isEmpty {
                            Text("No hospitals registered yet")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                        } else {
                            ForEach(hospitals) { hospital in
                                HospitalListItem(hospital: hospital,
                                               onEdit: { selectedHospital = hospital; showEditForm = true },
                                               onDelete: { hospitalToDelete = hospital; showDeleteConfirmation = true })
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showHospitalForm) {
            NavigationView {
                AddHospitalForm(
                    hospitalName: $hospitalName,
                    adminName: $adminName,
                    licenseNumber: $licenseNumber,
                    street: $street,
                    city: $city,
                    state: $state,
                    zipCode: $zipCode,
                    phone: $phone,
                    email: $email,
                    onSubmit: addHospital
                )
                .navigationTitle("Add Hospital")
                .navigationBarItems(trailing: Button("Cancel") {
                    showHospitalForm = false
                })
            }
        }
        .sheet(isPresented: $showEditForm) {
            if let hospital = selectedHospital {
                NavigationView {
                    EditHospitalForm(hospital: hospital, onSave: updateHospital)
                        .navigationTitle("Edit Hospital")
                        .navigationBarItems(trailing: Button("Cancel") {
                            showEditForm = false
                        })
                }
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { clearForm() }
        } message: {
            Text("Hospital added successfully!")
        }
        .alert("Delete Hospital", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let hospital = hospitalToDelete {
                    deleteHospital(hospital)
                }
            }
        } message: {
            Text("Are you sure you want to delete this hospital? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addHospital() {
        // Validate form
        guard !hospitalName.isEmpty && !adminName.isEmpty && !licenseNumber.isEmpty && !street.isEmpty &&
              !city.isEmpty && !state.isEmpty && !zipCode.isEmpty &&
              !phone.isEmpty && !email.isEmpty else {
            errorMessage = "Please fill all required fields before submitting."
            showError = true
            return
        }
        
        // Check for duplicate hospital
        if hospitals.contains(where: { $0.name.lowercased() == hospitalName.lowercased() &&
                                     $0.street.lowercased() == street.lowercased() &&
                                     $0.city.lowercased() == city.lowercased() }) {
            errorMessage = "This hospital is already registered."
            showError = true
            return
        }
        
        // Create new hospital
        let newHospital = Hospital(
            id: Hospital.generateUniqueID(),
            name: hospitalName,
            adminName: adminName,
            licenseNumber: licenseNumber,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            phone: phone,
            email: email,
            status: .pending,  // Set initial status as pending
            registrationDate: Date(),
            lastModified: Date(),
            lastModifiedBy: "Super Admin"
        )
        
        hospitals.append(newHospital)
        showSuccessAlert = true
        showHospitalForm = false
        
        // TODO: Send email with credentials to admin
        // TODO: Save to database
    }
    
    private func updateHospital(_ hospital: Hospital) {
        if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
            hospitals[index] = hospital
            showEditForm = false
            showSuccessAlert = true
        }
    }
    
    private func deleteHospital(_ hospital: Hospital) {
        if let index = hospitals.firstIndex(where: { $0.id == hospital.id }) {
            // Remove the hospital from the list
            hospitals.remove(at: index)
            
            // Clear the hospital to delete
            hospitalToDelete = nil
            
            // Show success message
            errorMessage = "Hospital deleted successfully"
            showError = true
        }
    }
    
    private func clearForm() {
        hospitalName = ""
        adminName = ""
        licenseNumber = ""
        street = ""
        city = ""
        state = ""
        zipCode = ""
        phone = ""
        email = ""
    }
}

struct HospitalListItem: View {
    let hospital: Hospital
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital.name)
                        .font(.headline)
                    Text(hospital.id)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                // Status indicator
                Text(hospital.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                            .opacity(0.2)
                    )
                    .foregroundColor(statusColor)
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            Text("\(hospital.street), \(hospital.city)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "phone.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(hospital.phone)
                    .font(.caption)
                Spacer()
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(hospital.email)
                    .font(.caption)
            }
            
            Text("License: \(hospital.licenseNumber)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
    
    private var statusColor: Color {
        switch hospital.status {
        case .active:
            return .green
        case .pending:
            return .orange
        case .inactive:
            return .red
        }
    }
}

struct AddHospitalForm: View {
    @Binding var hospitalName: String
    @Binding var adminName: String
    @Binding var licenseNumber: String
    @Binding var street: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var phone: String
    @Binding var email: String
    let onSubmit: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Hospital Information")) {
                TextField("Hospital Name", text: $hospitalName)
                TextField("Admin Name", text: $adminName)
                TextField("License Number", text: $licenseNumber)
            }
            
            Section(header: Text("Address")) {
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip Code", text: $zipCode)
            }
            
            Section(header: Text("Contact Information")) {
                TextField("Phone", text: $phone)
                TextField("Email", text: $email)
            }
            
            if !hospitalName.isEmpty && !adminName.isEmpty && !licenseNumber.isEmpty && !street.isEmpty &&
               !city.isEmpty && !state.isEmpty && !zipCode.isEmpty &&
               !phone.isEmpty && !email.isEmpty {
                Section {
                    Button("Submit") {
                        onSubmit()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct EditHospitalForm: View {
    @State private var editedHospital: Hospital
    let onSave: (Hospital) -> Void
    
    init(hospital: Hospital, onSave: @escaping (Hospital) -> Void) {
        _editedHospital = State(initialValue: hospital)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section(header: Text("Hospital Information")) {
                TextField("Hospital Name", text: $editedHospital.name)
                TextField("Admin Name", text: $editedHospital.adminName)
                TextField("License Number", text: $editedHospital.licenseNumber)
            }
            
            Section(header: Text("Address")) {
                TextField("Street", text: $editedHospital.street)
                TextField("City", text: $editedHospital.city)
                TextField("State", text: $editedHospital.state)
                TextField("Zip Code", text: $editedHospital.zipCode)
            }
            
            Section(header: Text("Contact Information")) {
                TextField("Phone", text: $editedHospital.phone)
                TextField("Email", text: $editedHospital.email)
            }
            
            Section {
                Button("Save Changes") {
                    editedHospital.lastModified = Date()
                    editedHospital.lastModifiedBy = "Super Admin"
                    onSave(editedHospital)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
    }
}

struct DashboardCards: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
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

#Preview {
    SuperAdminDashboardView()
} 
