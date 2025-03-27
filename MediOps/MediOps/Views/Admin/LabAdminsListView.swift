import SwiftUI

struct LabAdminsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddLabAdmin = false
    @State private var showEditLabAdmin = false
    @State private var labAdminToEdit: UILabAdmin?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var labAdmins: [UILabAdmin]
    
    private let adminController = AdminController.shared
    
    init(labAdmins: Binding<[UILabAdmin]>) {
        _labAdmins = labAdmins
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Spacer()
                    
                    Text("Lab Admins")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Lab Admins List
                ScrollView {
                    VStack(spacing: 20) {
                        if labAdmins.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "flask")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No lab admins added yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Tap + to add a new lab admin")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding()
                        } else {
                            ForEach(labAdmins) { labAdmin in
                                LabAdminCard(
                                    labAdmin: labAdmin,
                                    onEdit: { editLabAdmin(labAdmin) },
                                    onDelete: { deleteLabAdmin(labAdmin) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddLabAdmin = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.teal)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
            
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showAddLabAdmin) {
            AddLabAdminView { activity in
                if let labAdmin = activity.labAdminDetails {
                    addLabAdmin(labAdmin)
                }
            }
        }
        .sheet(isPresented: $showEditLabAdmin) {
            if let labAdmin = labAdminToEdit {
                EditLabAdminView(labAdmin: labAdmin) { updatedLabAdmin in
                    updateLabAdmin(updatedLabAdmin)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await fetchLabAdmins()
        }
    }
    
    private func fetchLabAdmins() async {
        isLoading = true
        do {
            let hospitalAdminId = "YOUR_HOSPITAL_ADMIN_ID" // Replace with actual hospital admin ID
            let fetchedLabAdmins = try await adminController.getLabAdmins(hospitalAdminId: hospitalAdminId)
            labAdmins = fetchedLabAdmins.map { labAdmin in
                UILabAdmin(
                    id: UUID(uuidString: labAdmin.id) ?? UUID(),
                    fullName: labAdmin.name,
                    email: "", // Add these fields to your Models.LabAdmin if needed
                    phone: "",
                    gender: .male,
                    dateOfBirth: Date(),
                    experience: 0,
                    qualification: labAdmin.qualification,
                    address: ""
                )
            }
        } catch {
            errorMessage = "Failed to fetch lab admins: \(error.localizedDescription)"
            showError = true
        }
        isLoading = false
    }
    
    private func addLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                let hospitalAdminId = "YOUR_HOSPITAL_ADMIN_ID" // Replace with actual hospital admin ID
                let (_, _) = try await adminController.createLabAdmin(
                    email: labAdmin.email,
                    password: "tempPassword123", // You should generate a secure password
                    name: labAdmin.fullName,
                    qualification: labAdmin.qualification,
                    hospitalAdminId: hospitalAdminId
                )
                await fetchLabAdmins() // Refresh the list
            } catch {
                errorMessage = "Failed to add lab admin: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func updateLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                let modelLabAdmin = Models.LabAdmin(
                    id: labAdmin.id.uuidString,
                    userId: "", // Add this field if needed
                    name: labAdmin.fullName,
                    qualification: labAdmin.qualification,
                    hospitalAdminId: "YOUR_HOSPITAL_ADMIN_ID", // Replace with actual hospital admin ID
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await adminController.updateLabAdmin(modelLabAdmin)
                await fetchLabAdmins() // Refresh the list
            } catch {
                errorMessage = "Failed to update lab admin: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func deleteLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                try await adminController.deleteLabAdmin(id: labAdmin.id.uuidString)
                await fetchLabAdmins() // Refresh the list
            } catch {
                errorMessage = "Failed to delete lab admin: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func editLabAdmin(_ labAdmin: UILabAdmin) {
        labAdminToEdit = labAdmin
        showEditLabAdmin = true
    }
}

struct LabAdminCard: View {
    let labAdmin: UILabAdmin
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(labAdmin.fullName)
                        .font(.headline)
                    Text(labAdmin.qualification)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
            
            HStack {
                Image(systemName: "phone.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(labAdmin.phone)
                    .font(.caption)
                Spacer()
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(labAdmin.email)
                    .font(.caption)
            }
            
            Text("\(labAdmin.experience) years of experience")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

#Preview {
    LabAdminsListView(labAdmins: .constant([]))
} 