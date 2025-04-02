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
    
    // Add state for debug options
    @State private var showDebugOptions = false
    @State private var currentHospitalId = ""
    @State private var showCreateTestAdminConfirmation = false
    
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
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                            Text("Back")
                                .foregroundColor(.blue)
                                .fontWeight(.regular)
                        }
                    }
                    
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
                                .padding(.top, 40)
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
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text(labAdminToDelete != nil ? "Deleting \(labAdminToDelete!.fullName)..." : "Loading...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        .padding(25)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    )
                    .allowsHitTesting(true) // Prevent interaction with underlying views
            }
        }
        .navigationBarHidden(true) // Hide the default navigation bar
        .toolbar(.hidden, for: .navigationBar) // Alternative way to hide navigation bar in newer SwiftUI
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
            Button("Cancel", role: .cancel) {
                labAdminToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let labAdmin = labAdminToDelete {
                    confirmDeleteLabAdmin(labAdmin)
                }
            }
        } message: {
            if let labAdmin = labAdminToDelete {
                Text("Are you sure you want to delete \(labAdmin.fullName)?\n\nID: \(labAdmin.originalId ?? "Unknown")\nEmail: \(labAdmin.email)\n\nThis action cannot be undone.")
            } else {
            Text("Are you sure you want to delete this lab admin? This action cannot be undone.")
            }
        }
        // Success message alert
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        // Debug options alert
        .alert("Database Connection", isPresented: $showDebugOptions) {
            Button("Create Test Admin", role: .none) {
                showCreateTestAdminConfirmation = true
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        // Confirm test admin creation
        .alert("Create Test Lab Admin?", isPresented: $showCreateTestAdminConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Create", role: .none) {
                Task {
                    await createTestLabAdmin(for: currentHospitalId)
                }
            }
        } message: {
            Text("This will create a test lab admin with random credentials for the current hospital.")
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
            
            // Validate hospital ID format
            if hospitalId.isEmpty {
                print("FETCH LAB ADMINS ERROR: Hospital ID is empty")
                errorMessage = "Invalid hospital ID format. Please login again."
                showError = true
                isLoading = false
                return
            }
            
            // Log additional debug info about the Supabase controller
            do {
                let diagnosticInfo = try await adminController.getDatabaseDiagnosticInfo()
                if let supabaseURL = diagnosticInfo["supabaseURL"] as? String {
                    print("FETCH LAB ADMINS: Supabase URL being used: \(supabaseURL)")
                }
            } catch {
                print("FETCH LAB ADMINS: Could not get Supabase diagnostic info: \(error.localizedDescription)")
            }
            
            // First try to verify the hospital exists to provide better error messages
            do {
                let hospital = try await adminController.getHospital(id: hospitalId)
                print("FETCH LAB ADMINS: Verified hospital exists with name: \(hospital.name)")
            } catch {
                print("FETCH LAB ADMINS WARNING: Could not verify hospital: \(error.localizedDescription)")
                // Continue anyway, as the getLabAdmins method will handle this
            }
            
            // Fetch lab admins for the specific hospital ID from Supabase
            print("FETCH LAB ADMINS: Calling getLabAdmins with hospital ID: \(hospitalId)")
            let fetchedLabAdmins = try await adminController.getLabAdmins(hospitalAdminId: hospitalId)
            print("FETCH LAB ADMINS: Successfully retrieved \(fetchedLabAdmins.count) lab admins")
            
            if fetchedLabAdmins.isEmpty {
                print("FETCH LAB ADMINS: No lab admins found for hospital ID: \(hospitalId)")
                // This is not an error, just an empty state
            }
            
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
    
    // This method is now handled by confirmDeleteLabAdmin
    private func editLabAdmin(_ labAdmin: UILabAdmin) {
        labAdminToEdit = labAdmin
        showEditLabAdmin = true
    }
    
    // Main method for handling lab admin deletion with confirmation and feedback
    private func confirmDeleteLabAdmin(_ labAdmin: UILabAdmin) {
        Task {
            do {
                isLoading = true
                
                // Get hospital ID from UserDefaults
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    errorMessage = "Failed to delete lab admin: Hospital ID not found"
                    showError = true
                    isLoading = false
                    return
                }
                
                // Verify the lab admin ID exists
                guard let originalId = labAdmin.originalId else {
                    errorMessage = "Cannot delete: Invalid lab admin ID"
                    showError = true
                    isLoading = false
                    return
                }
                
                // Delete from Supabase
                try await adminController.deleteLabAdmin(id: originalId)
                
                // If successful, remove from local array
                await MainActor.run {
                    if let index = labAdmins.firstIndex(where: { $0.id == labAdmin.id }) {
                        labAdmins.remove(at: index)
                    }
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete lab admin: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    // Debug method to check database connection
    private func checkDatabaseConnection() async {
        do {
            isLoading = true
            
            // Check hospital ID
            guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                errorMessage = "No hospital ID found in UserDefaults"
                showError = true
                isLoading = false
                return
            }
            
            currentHospitalId = hospitalId
            
            // Get diagnostic info from AdminController
            let diagnosticInfo = try await adminController.getDatabaseDiagnosticInfo()
            var diagMsg = "Connected to database. "
            
            if let totalLabAdmins = diagnosticInfo["totalLabAdmins"] as? Int {
                diagMsg += "Found \(totalLabAdmins) total lab admins in the database. "
            } else {
                diagMsg += "Could not count lab admins. "
            }
            
            // Try to check the hospital
            do {
                let hospital = try await adminController.getHospital(id: hospitalId)
                diagMsg += "Hospital found: ID=\(hospital.id), Name=\(hospital.name). "
                
                // Try direct query for matching lab admins
                let labAdminCheck = try await adminController.checkLabAdminsForHospital(hospitalId: hospitalId)
                
                if let count = labAdminCheck["count"] as? Int {
                    diagMsg += "Direct query found \(count) lab admins for this hospital. "
                }
                
                // Show debug options
                await MainActor.run {
                    successMessage = diagMsg
                    showDebugOptions = true
                }
                
            } catch {
                diagMsg += "Hospital check failed: \(error.localizedDescription). "
                
                // Show simple alert for error case
                await MainActor.run {
                    successMessage = diagMsg
                    showSuccessMessage = true
                }
            }
            
            isLoading = false
        } catch {
            errorMessage = "Connection check failed: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    // Helper method to create a test lab admin
    private func createTestLabAdmin(for hospitalId: String) async {
        isLoading = true
        
        do {
            // Generate a test lab admin
            let testEmail = "testlab\(Int.random(in: 100...999))@example.com"
            let password = generateSecurePassword()
            let name = "Test Lab Admin"
            
            print("Creating test lab admin for hospital ID: \(hospitalId)")
            print("Email: \(testEmail)")
            print("Password: \(password)")
            
            let (labAdmin, _) = try await adminController.createLabAdmin(
                email: testEmail,
                password: password,
                name: name,
                labName: "Pathology & Laboratory",
                hospitalAdminId: hospitalId,
                contactNumber: "1234567890",
                department: "Pathology & Laboratory"
            )
            
            await MainActor.run {
                successMessage = "Successfully created test lab admin: \(labAdmin.id) - \(labAdmin.name)"
                showSuccessMessage = true
                
                // Refresh the list
                Task {
                    await fetchLabAdmins()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create test lab admin: \(error.localizedDescription)"
                showError = true
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

struct LabAdminCard: View {
    let labAdmin: UILabAdmin
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showOptions = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Lab admin header with name and menu
            HStack {
                Text(labAdmin.fullName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Three dots menu
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            Text(labAdmin.qualification)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Contact info
            HStack(spacing: 20) {
                Label {
                    Text(labAdmin.phone)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "phone.fill")
                }
                
                Label {
                    Text(labAdmin.email)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "envelope.fill")
                }
            }
            .foregroundColor(.gray)
            
            // License info
            Text("License: \(labAdmin.originalId ?? "Unknown")")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("Delete Lab Admin", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(labAdmin.fullName)? This action cannot be undone.")
        }
    }
}

#Preview {
    LabAdminsListView(labAdmins: .constant([]))
} 