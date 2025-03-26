import SwiftUI

struct SuperAdminDashboardView: View {
    @StateObject private var viewModel = SuperAdminDashboardViewModel()
    
    // Form States
    @State private var showHospitalForm = false
    @State private var hospitalName = ""
    @State private var adminName = ""
    @State private var hospitalID = ""
    @State private var licenseNumber = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var emergencyContact = ""
    
    // Alert States
    @State private var showSuccessAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Selected Hospital States
    @State private var hospitalToDelete: Hospital?
    @State private var showEditForm = false
    @State private var selectedHospital: Hospital?
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        return phone.count == 10 && phone.allSatisfy { $0.isNumber }
    }
    
    private func isValidPinCode(_ pinCode: String) -> Bool {
        return pinCode.count == 6 && pinCode.allSatisfy { $0.isNumber }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.bold)
               
            }
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(viewModel.totalHospitals)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
                Text("Total Hospitals")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    @ViewBuilder
    private var searchAndFilterView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search hospitals...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: "All Cities", 
                             isSelected: viewModel.selectedCity == nil) {
                        viewModel.selectedCity = nil
                    }
                    
                    ForEach(viewModel.uniqueCities, id: \.self) { city in
                        FilterChip(title: city, 
                                 isSelected: viewModel.selectedCity == city) {
                            viewModel.selectedCity = city
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                searchAndFilterView
                
                // Hospitals section with title outside scroll view
                VStack(alignment: .leading, spacing: 15) {
                    Text("Hospitals")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Only the hospital list is scrollable
                    ScrollView {
                        VStack(spacing: 15) {
                            if viewModel.filteredHospitals.isEmpty {
                                Text("No hospitals found")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.1), radius: 5)
                            } else {
                                ForEach(viewModel.filteredHospitals) { hospital in
                                    HospitalListItem(
                                        hospital: hospital,
                                        onEdit: {
                                            selectedHospital = hospital
                                            showEditForm = true
                                        },
                                        onDelete: {
                                            hospitalToDelete = hospital
                                            showDeleteConfirmation = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showHospitalForm = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.teal)
                            .clipShape(Circle())
                            .shadow(color: .gray.opacity(0.3), radius: 5)
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
                    hospitalID: $hospitalID,
                    licenseNumber: $licenseNumber,
                    emergencyContact: $emergencyContact,
                    street: $street,
                    city: $city,
                    state: $state,
                    zipCode: $zipCode,
                    adminName: $adminName,
                    phone: $phone,
                    email: $email,
                    onSubmit: addHospital
                )
                .navigationTitle("Add Hospital")
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
    
    // MARK: - Actions
    private func addHospital() {
        let newHospital = Hospital(
            id: hospitalID,
            name: hospitalName,
            adminName: adminName,
            licenseNumber: licenseNumber,
            hospitalPhone: emergencyContact,
            street: street,
            city: city,
            state: state,
            zipCode: zipCode,
            phone: phone,
            email: email,
            status: .pending,
            registrationDate: Date(),
            lastModified: Date(),
            lastModifiedBy: "Super Admin",
            imageData: nil
        )
        
        viewModel.addHospital(newHospital)
        showSuccessAlert = true
        showHospitalForm = false
        clearForm()
    }
    
    private func updateHospital(_ hospital: Hospital) {
        viewModel.updateHospital(hospital)
        showEditForm = false
        showSuccessAlert = true
    }
    
    private func deleteHospital(_ hospital: Hospital) {
        viewModel.deleteHospital(hospital)
        hospitalToDelete = nil
        errorMessage = "Hospital deleted successfully"
        showError = true
    }
    
    private func clearForm() {
        hospitalName = ""
        adminName = ""
        hospitalID = ""
        licenseNumber = ""
        phone = ""
        email = ""
        street = ""
        city = ""
        state = ""
        zipCode = ""
        emergencyContact = ""
    }
}

struct HospitalListItem: View {
    let hospital: Hospital
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Hospital Image
                if let imageData = hospital.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Hospital Name and Status
                    HStack {
                        Text(hospital.name)
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
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
                    }
                    
                    // IDs
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hospital ID")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(hospital.id)
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("License")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(hospital.licenseNumber)
                                .font(.caption)
                                .foregroundColor(.teal)
                        }
                    }
                    
                    // Address
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Address")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(hospital.street), \(hospital.city), \(hospital.state) - \(hospital.zipCode)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Contact Information (Hospital Emergency Contact)
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.teal)
                        Text(hospital.hospitalPhone)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// New FilterChip View
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teal : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(20)
        }
    }
}

#Preview {
    SuperAdminDashboardView()
}
