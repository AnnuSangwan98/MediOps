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
    @State private var labAdminToDelete: UILabAdmin?
    @State private var showDeleteConfirmation = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
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
                        if isLoading {
                            ProgressView("Loading lab admins...")
                                .padding()
                        } else if labAdmins.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "flask.fill")
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
                                    onDelete: {
                                        labAdminToDelete = labAdmin
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await fetchLabAdmins()
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
        }
        .sheet(isPresented: $showAddLabAdmin) {
            AddLabAdminView { activity in
                // Refresh the list after adding a lab admin
                Task {
                    await fetchLabAdmins()
                }
            }
        }
        .sheet(isPresented: $showEditLabAdmin) {
            if let labAdmin = labAdminToEdit {
                EditLabAdminView(labAdmin: labAdmin) { updatedLabAdmin in
                    // Refresh the list after editing a lab admin
                    Task {
                        await fetchLabAdmins()
                    }
                }
            }
        }
        // Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        // Delete confirmation alert
        .alert("Delete Lab Admin", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let labAdmin = labAdminToDelete {
                    confirmDeleteLabAdmin(labAdmin)
                }
            }
        } message: {
            Text("Are you sure you want to delete this lab admin? This action cannot be undone.")
        }
        // Success message alert
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .task {
            await fetchLabAdmins()
        }
    }
    
    private func fetchLabAdmins() async {
        isLoading = true
        do {
            // Get hospital ID from UserDefaults (saved during login)
            guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                print("FETCH LAB ADMINS ERROR: No hospital ID found in UserDefaults")
                errorMessage = "Failed to fetch lab admins: Hospital ID not found. Please login again."
                showError = true
                isLoading = false
                return
            }
            
            print("FETCH LAB ADMINS: Using hospital ID from UserDefaults: \(hospitalId)")
            
            // Fetch lab admins for the specific hospital ID from Supabase
            let fetchedLabAdmins = try await adminController.getLabAdmins(hospitalAdminId: hospitalId)
            print("FETCH LAB ADMINS: Successfully retrieved \(fetchedLabAdmins.count) lab admins")
            
            // Map to UI models
            await MainActor.run {
                labAdmins = fetchedLabAdmins.map { labAdmin in
                    print("FETCH LAB ADMINS: Processing lab admin ID: \(labAdmin.id), Name: \(labAdmin.name)")
                    return UILabAdmin(
                        id: UUID(), // Use a UUID for SwiftUI's Identifiable protocol
                        originalId: labAdmin.id, // Store the original Supabase ID
                        fullName: labAdmin.name,
                        email: labAdmin.email,
                        phone: labAdmin.contactNumber.isEmpty ? "" : "+91\(labAdmin.contactNumber)", // Add +91 prefix for UI
                        gender: .male, // Default gender
                        dateOfBirth: Date(), // Default date
                        experience: 0, // Default experience
                        qualification: labAdmin.department, // Use department instead of labName
                        address: labAdmin.address
                    )
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("FETCH LAB ADMINS ERROR: \(error.localizedDescription)")
                if let adminError = error as? AdminError {
                    errorMessage = "Failed to fetch lab admins: \(adminError.errorDescription ?? "Unknown error")"
                } else {
                    errorMessage = "Failed to fetch lab admins: \(error.localizedDescription)"
                }
                showError = true
                isLoading = false
            }
        }
    }
    
    private func addLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                // Get hospital ID from UserDefaults (saved during login)
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    print("ADD LAB ADMIN ERROR: No hospital ID found in UserDefaults")
                    errorMessage = "Failed to add lab admin: Hospital ID not found. Please login again."
                    showError = true
                    isLoading = false
                    return
                }
                
                print("ADD LAB ADMIN: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Generate a secure password that meets the constraints
                let password = generateSecurePassword()
                
                // Create the lab admin
                print("ADD LAB ADMIN: Creating lab admin for hospital: \(hospitalId)")
                let (_, _) = try await adminController.createLabAdmin(
                    email: labAdmin.email,
                    password: password,
                    name: labAdmin.fullName,
                    labName: labAdmin.qualification, // Maps to department field
                    hospitalAdminId: hospitalId,
                    contactNumber: labAdmin.phone.replacingOccurrences(of: "+91", with: ""), // Remove country code for 10-digit format
                    department: "Pathology & Laboratory" // Fixed to match the constraint
                )
                
                print("ADD LAB ADMIN: Successfully created lab admin")
                await fetchLabAdmins() // Refresh the list
            } catch {
                print("ADD LAB ADMIN ERROR: \(error.localizedDescription)")
                if let adminError = error as? AdminError {
                    errorMessage = "Failed to add lab admin: \(adminError.errorDescription ?? "Unknown error")"
                } else {
                    errorMessage = "Failed to add lab admin: \(error.localizedDescription)"
                }
                showError = true
                isLoading = false
            }
        }
    }
    
    // Generate a password that meets the constraints in the lab_admins table
    private func generateSecurePassword() -> String {
        // Generate a password that meets all requirements (at least 8 chars, with uppercase, lowercase, digit, and special char)
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "@$!%*?&"
        
        // Ensure at least one of each required character type
        let guaranteedChars = [
            String(uppercaseLetters.randomElement()!),
            String(lowercaseLetters.randomElement()!),
            String(numbers.randomElement()!),
            String(specialChars.randomElement()!)
        ]
        
        // Generate remaining characters (at least 4 more for a total of 8+)
        let remainingLength = 8
        let allChars = uppercaseLetters + lowercaseLetters + numbers + specialChars
        let remainingChars = (0..<remainingLength).map { _ in String(allChars.randomElement()!) }
        
        // Combine all characters and shuffle them
        let passwordChars = guaranteedChars + remainingChars
        return passwordChars.shuffled().joined()
    }
    
    private func updateLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                // Get hospital ID from UserDefaults (saved during login)
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    print("UPDATE LAB ADMIN ERROR: No hospital ID found in UserDefaults")
                    errorMessage = "Failed to update lab admin: Hospital ID not found. Please login again."
                    showError = true
                    isLoading = false
                    return
                }
                
                print("UPDATE LAB ADMIN: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Create the model lab admin with the correct hospital ID
                print("UPDATE LAB ADMIN: Updating lab admin ID: \(labAdmin.id)")
                let modelLabAdmin = LabAdmin(
                    id: labAdmin.id.uuidString,
                    hospitalId: hospitalId,
                    name: labAdmin.fullName,
                    email: labAdmin.email,
                    contactNumber: labAdmin.phone,
                    department: labAdmin.qualification,
                    address: labAdmin.address,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await adminController.updateLabAdmin(modelLabAdmin)
                print("UPDATE LAB ADMIN: Successfully updated lab admin")
                await fetchLabAdmins() // Refresh the list
            } catch {
                print("UPDATE LAB ADMIN ERROR: \(error.localizedDescription)")
                if let adminError = error as? AdminError {
                    errorMessage = "Failed to update lab admin: \(adminError.errorDescription ?? "Unknown error")"
                } else {
                    errorMessage = "Failed to update lab admin: \(error.localizedDescription)"
                }
                showError = true
                isLoading = false
            }
        }
    }
    
    private func deleteLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            isLoading = true
            do {
                // Get the lab admin ID to use with the API (using originalId when available)
                let labAdminId: String
                if let originalId = labAdmin.originalId, !originalId.isEmpty {
                    labAdminId = originalId
                } else {
                    labAdminId = String(describing: labAdmin.id)
                }
                
                print("DELETE LAB ADMIN: Deleting lab admin with ID: \(labAdminId)")
                try await adminController.deleteLabAdmin(id: labAdminId)
                print("DELETE LAB ADMIN: Successfully deleted lab admin")
                await fetchLabAdmins() // Refresh the list
            } catch {
                print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
                if let adminError = error as? AdminError {
                    errorMessage = "Failed to delete lab admin: \(adminError.errorDescription ?? "Unknown error")"
                } else {
                    errorMessage = "Failed to delete lab admin: \(error.localizedDescription)"
                }
                showError = true
                isLoading = false
            }
        }
    }
    
    private func editLabAdmin(_ labAdmin: UILabAdmin) {
        labAdminToEdit = labAdmin
        showEditLabAdmin = true
    }
    
    private func confirmDeleteLabAdmin(_ labAdmin: UILabAdmin) {
        isLoading = true
        
        Task {
            do {
                // Get the lab admin ID to use with the API
                let labAdminId: String
                if let originalId = labAdmin.originalId, !originalId.isEmpty {
                    labAdminId = originalId
                } else {
                    labAdminId = String(describing: labAdmin.id)
                }
                
                print("DELETE LAB ADMIN: Deleting lab admin with ID: \(labAdminId)")
                
                // Call the AdminController to delete the lab admin
                try await adminController.deleteLabAdmin(id: labAdminId)
                
                await MainActor.run {
                    // Remove from UI list
                    withAnimation {
                        if let index = labAdmins.firstIndex(where: { $0.id == labAdmin.id }) {
                            labAdmins.remove(at: index)
                        }
                    }
                    
                    // Show success message
                    successMessage = "Lab admin successfully removed"
                    showSuccessMessage = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
                    errorMessage = "Failed to delete lab admin: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
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