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
                        Image(systemName: "chevron.left")
                            .foregroundColor(.teal)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .gray.opacity(0.2), radius: 3)
                    }
                    
                    Spacer()
                    
                    Text("Lab Admins")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Refresh button
                    Button(action: { 
                        Task {
                            await fetchLabAdmins()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.teal)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Status bar
                if !labAdmins.isEmpty {
                    HStack {
                        Text("\(labAdmins.count) lab admin\(labAdmins.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
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
                
                // Show success message if needed
                if !labAdmins.isEmpty {
                    successMessage = "Successfully retrieved \(labAdmins.count) lab admins"
                    showSuccessMessage = true
                }
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
        print("DELETE LAB ADMIN: Starting deletion process for lab admin with UUID: \(labAdmin.id)")
        print("DELETE LAB ADMIN: Original ID (from Supabase): \(labAdmin.originalId ?? "nil")")
        print("DELETE LAB ADMIN: Full Name: \(labAdmin.fullName)")
        
        // First check if the lab admin ID is valid
        guard let originalId = labAdmin.originalId, !originalId.isEmpty else {
            errorMessage = "Cannot delete: Invalid lab admin ID (originalId is nil or empty)"
            showError = true
            return
        }
        
        // Verify the lab admin in the database first
        Task {
            isLoading = true
            do {
                // Check if lab admin exists in database before attempting deletion
                let verifyResult = try await adminController.verifyLabAdminExists(id: originalId)
                let exists = verifyResult["exists"] as? Bool ?? false
                
                if !exists {
                    // Lab admin doesn't exist in the database, but still in the UI
                    // This is a sync issue - remove from UI list
                    await MainActor.run {
                        withAnimation {
                            if let index = labAdmins.firstIndex(where: { $0.id == labAdmin.id }) {
                                labAdmins.remove(at: index)
                                successMessage = "Lab admin was already deleted from the database. UI has been updated."
                                showSuccessMessage = true
                                clearLabAdminToDelete()
                } else {
                                errorMessage = "Could not find lab admin in the list."
                                showError = true
                                clearLabAdminToDelete()
                            }
                        }
                    }
                    return
                }
                
                // Now that we confirmed the lab admin exists, attempt deletion
                isLoading = true
                labAdminToDelete = labAdmin
                
                print("DELETE LAB ADMIN: Calling adminController.deleteLabAdmin with ID: \(originalId)")
                
                // Call the AdminController to delete the lab admin from Supabase
                try await adminController.deleteLabAdmin(id: originalId)
                print("DELETE LAB ADMIN: Successfully deleted lab admin from database")
                
                await MainActor.run {
                    // Remove from UI list with animation
                    print("DELETE LAB ADMIN: Removing lab admin from UI list")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let index = labAdmins.firstIndex(where: { $0.id == labAdmin.id }) {
                            labAdmins.remove(at: index)
                            print("DELETE LAB ADMIN: Removed lab admin at index \(index)")
                        } else {
                            print("DELETE LAB ADMIN WARNING: Could not find lab admin in UI list with UUID: \(labAdmin.id)")
                        }
                    }
                    
                    // Show success message
                    successMessage = "Lab admin \(labAdmin.fullName) successfully removed from the system"
                    showSuccessMessage = true
                    clearLabAdminToDelete()
                }
            } catch let error as AdminError {
                await MainActor.run {
                    print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
                    
                    // Provide specific error messages based on error type
                    switch error {
                    case .labAdminNotFound:
                        errorMessage = "The lab admin could not be found in the database. It may have been already deleted."
                    case .invalidData(let message):
                        errorMessage = "Invalid data: \(message)"
                    case .customError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Failed to delete lab admin: \(error.errorDescription ?? "Unknown error")"
                    }
                    
                    showError = true
                    clearLabAdminToDelete()
                }
            } catch {
                await MainActor.run {
                    print("DELETE LAB ADMIN ERROR: \(error.localizedDescription)")
                    print("DELETE LAB ADMIN ERROR DETAILS: \(String(describing: error))")
                    errorMessage = "Failed to delete lab admin: \(error.localizedDescription)"
                    showError = true
                    clearLabAdminToDelete()
                }
            }
        }
    }
    
    // Helper method to clear the labAdminToDelete and set isLoading to false
    private func clearLabAdminToDelete() {
        print("DELETE LAB ADMIN: Clearing labAdminToDelete reference and setting isLoading to false")
        isLoading = false
        // We keep the reference in labAdminToDelete for a short time to show in the loading overlay
        // But clear it after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.labAdminToDelete = nil
            print("DELETE LAB ADMIN: Cleared labAdminToDelete reference after delay")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Lab admin header with avatar
            HStack(spacing: 12) {
                // Avatar/Icon
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "flask.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.teal)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(labAdmin.fullName)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(labAdmin.qualification)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action buttons with clear icons
                HStack(spacing: 12) {
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Edit \(labAdmin.fullName)")
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Delete \(labAdmin.fullName)")
                }
            }
            
            Divider()
            
            // Contact information
            VStack(spacing: 8) {
                HStack {
                    Label {
                        Text(labAdmin.email)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 12))
                    }
                    Spacer()
                }
                
                HStack {
                    Label {
                        Text(labAdmin.phone.isEmpty ? "No phone" : labAdmin.phone)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 12))
                    }
                    Spacer()
                }
                
                if !labAdmin.address.isEmpty {
                    HStack {
                        Label {
                            Text(labAdmin.address)
                                .font(.footnote)
                        .foregroundColor(.gray)
                        } icon: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.teal)
                                .font(.system(size: 12))
                        }
                        Spacer()
                    }
                }
            }
            
            // ID display (for debugging purposes)
            HStack {
                Spacer()
                Text("ID: \(labAdmin.originalId ?? "Unknown")")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    LabAdminsListView(labAdmins: .constant([]))
} 