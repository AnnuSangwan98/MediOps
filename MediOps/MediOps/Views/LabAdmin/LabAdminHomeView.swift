import SwiftUI
import UIKit

struct LabAdminHomeView: View {
    @State private var showLogoutConfirmation = false
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var labAdmin: LabAdmin?
    @State private var showProfileDetails = false
    
    // App theme colors
    let primaryTeal = Color(red: 43/255, green: 182/255, blue: 205/255)
    let darkTeal = Color(red: 23/255, green: 130/255, blue: 160/255)
    
    var body: some View {
        Group {
            if let labAdmin = labAdmin {
                // Only show the Patient Reports View with custom header
                ZStack {
                    // Background gradient
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Custom header view
                        headerView(labAdmin: labAdmin)
                        
                        // Patient Reports View
                        PatientReportsView()
                            .navigationBarBackButtonHidden(true)
                            .navigationBarHidden(true)
                    }
                }
                .sheet(isPresented: $showProfileDetails) {
                    ProfileDetailsView(labAdmin: labAdmin)
                }
            } else {
                // Show loading view while fetching lab admin details
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(primaryTeal)
                        .padding(.bottom, 15)
                    Text("Loading profile...")
                        .font(.headline)
                        .foregroundColor(darkTeal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    // Background gradient
                    LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                )
                .onAppear {
                    fetchLabAdminDetails()
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            fetchLabAdminDetails()
        }
    }
    
    // New header view builder
    @ViewBuilder
    private func headerView(labAdmin: LabAdmin) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(labAdmin.name)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    showProfileDetails = true
                }) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(primaryTeal)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .gray.opacity(0.2), radius: 3)
                }
                .padding(.trailing)
            }
        }
        .padding(.horizontal)
        .padding(.top) // Extra padding for status bar
        .padding(.bottom, 10)
    }
    
    private func fetchLabAdminDetails() {
        // Get lab admin ID from UserDefaults
        if let id = UserDefaults.standard.string(forKey: "lab_admin_id") {
            
            // Fetch lab admin details from Supabase
            Task {
                do {
                    let labAdmins = try await SupabaseController.shared.select(
                        from: "lab_admins",
                        where: "id",
                        equals: id
                    )
                    
                    if let labAdminData = labAdmins.first {
                        await MainActor.run {
                            // Create a LabAdmin object from the data
                            if let name = labAdminData["name"] as? String,
                               let hospitalId = labAdminData["hospital_id"] as? String,
                               let email = labAdminData["email"] as? String,
                               let department = labAdminData["department"] as? String {
                                
                                let contactNumber = labAdminData["contact_number"] as? String ?? ""
                                let address = labAdminData["Address"] as? String ?? ""
                                
                                self.labAdmin = LabAdmin(
                                    id: id,
                                    hospitalId: hospitalId,
                                    name: name,
                                    email: email,
                                    contactNumber: contactNumber,
                                    department: department,
                                    address: address,
                                    createdAt: Date(),  // Using current date as fallback
                                    updatedAt: Date()   // Using current date as fallback
                                )
                            }
                        }
                    }
                } catch {
                    print("Failed to fetch lab admin details: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func logout() {
        // Clear stored IDs
        UserDefaults.standard.removeObject(forKey: "lab_admin_id")
        UserDefaults.standard.removeObject(forKey: "hospital_id")
        
        // Update navigation state
        navigationState.signOut()
        
        // Get the scene delegate window and reset to RoleSelectionView immediately
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // Reset to RoleSelectionView
        let contentView = NavigationStack {
            RoleSelectionView()
        }
        .environmentObject(navigationState)
        
        window.rootViewController = UIHostingController(rootView: contentView)
        window.makeKeyAndVisible()
    }
}

// Profile Details View
struct ProfileDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var showLogoutConfirmation = false
    @State private var showResetPasswordAlert = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showResetPasswordSheet = false
    @State private var showResetSuccess = false
    @State private var showResetError = false
    @State private var resetErrorMessage = ""
    @State private var editingEmail: String
    @State private var editingContact: String
    @State private var isEditing = false
    @State private var showSaveSuccess = false
    let labAdmin: LabAdmin
    
    // App theme colors
    let primaryTeal = Color(red: 43/255, green: 182/255, blue: 205/255)
    let darkTeal = Color(red: 23/255, green: 130/255, blue: 160/255)
    
    init(labAdmin: LabAdmin) {
        self.labAdmin = labAdmin
        _editingEmail = State(initialValue: labAdmin.email)
        _editingContact = State(initialValue: labAdmin.contactNumber)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(primaryTeal)
                        .padding(.top, 20)
                    
                    Text(labAdmin.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(darkTeal)
                        .padding(.bottom, 20)
                    
                    // Personal Information
                    GroupBox(label: 
                        Text("PERSONAL INFORMATION")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    ) {
                        VStack(spacing: 0) {
                                                       
                            // Editable Email field
                            if isEditing {
                                HStack {
                                    Text("Email")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("Email", text: $editingEmail)
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(primaryTeal)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                            } else {
                                LabProfileInfoRow(title: "Email", value: editingEmail)
                            }
                            Divider()
                            
                            // Editable Contact field
                            if isEditing {
                                HStack {
                                    Text("Contact")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    TextField("Contact", text: $editingContact)
                                        .multilineTextAlignment(.trailing)
                                        .keyboardType(.phonePad)
                                        .foregroundColor(primaryTeal)
                                        .onChange(of: editingContact) { newValue in
                                            // Filter non-digit characters
                                            let filtered = newValue.filter { "0123456789".contains($0) }
                                            
                                            // Limit to 10 digits
                                            if filtered.count > 10 {
                                                editingContact = String(filtered.prefix(10))
                                            } else if filtered != newValue {
                                                editingContact = filtered
                                            }
                                        }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                            } else {
                                LabProfileInfoRow(title: "Contact", value: editingContact.isEmpty ? "Not provided" : editingContact)
                            }
                            Divider()
                            
                            // Read-only field
                            LabProfileInfoRow(title: "Role", value: "Lab Administrator")
                        }
                        .padding(.vertical, 5)
                    }
                    .groupBoxStyle(WhiteGroupBoxStyle())
                    .padding(.horizontal)
                    
                    // Work Information
                    GroupBox(label: 
                        Text("WORK INFORMATION")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    ) {
                        VStack(spacing: 0) {
                            LabProfileInfoRow(title: "ID", value: labAdmin.id)
                            Divider()
                            LabProfileInfoRow(title: "Department", value: labAdmin.department)
                            Divider()
                            LabProfileInfoRow(title: "Hospital ID", value: labAdmin.hospitalId)
                            if !labAdmin.address.isEmpty {
                                Divider()
                                LabProfileInfoRow(title: "Address", value: labAdmin.address)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .groupBoxStyle(WhiteGroupBoxStyle())
                    .padding(.horizontal)
                    
                    // Security Section
                    GroupBox(label: 
                        Text("SECURITY")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    ) {
                        Button(action: {
                            showResetPasswordSheet = true
                        }) {
                            HStack {
                                Text("Reset Password")
                                    .foregroundColor(primaryTeal)
                                    .font(.system(size: 17))
                                Spacer()
                                Image(systemName: "key.fill")
                                    .foregroundColor(primaryTeal)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 10)
                        }
                    }
                    .groupBoxStyle(WhiteGroupBoxStyle())
                    .padding(.horizontal)
                    
                    // Logout Button
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .background(
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .foregroundColor(primaryTeal)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                        .foregroundColor(primaryTeal)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            // Reset to original values
                            editingEmail = labAdmin.email
                            editingContact = labAdmin.contactNumber
                            isEditing = false
                        }
                        .foregroundColor(primaryTeal)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(primaryTeal)
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    // Clear stored IDs
                    UserDefaults.standard.removeObject(forKey: "lab_admin_id")
                    UserDefaults.standard.removeObject(forKey: "hospital_id")
                    
                    // Update navigation state
                    navigationState.signOut()
                    
                    // Dismiss the sheet
                    dismiss()
                    
                    // Get the scene delegate window and reset to RoleSelectionView immediately
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else { return }
                    
                    // Reset to RoleSelectionView
                    let contentView = NavigationStack {
                        RoleSelectionView()
                    }
                    .environmentObject(navigationState)
                    
                    window.rootViewController = UIHostingController(rootView: contentView)
                    window.makeKeyAndVisible()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showResetPasswordSheet) {
                // Use the ResetPasswordView from AdminProfileView.swift
                ResetPasswordView(
                    currentPassword: $currentPassword,
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    onSubmit: handlePasswordReset,
                    onCancel: { showResetPasswordSheet = false }
                )
            }
            .alert("Success", isPresented: $showResetSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your password has been successfully reset.")
            }
            .alert("Profile Updated", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your profile information has been updated successfully.")
            }
            .alert("Error", isPresented: $showResetError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetErrorMessage)
            }
        }
    }
    
    private func saveChanges() {
        Task {
            do {
                print("Updating profile for lab admin ID: \(labAdmin.id)")
                
                // Basic email validation
                let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                
                if !emailPredicate.evaluate(with: editingEmail) {
                    print("Invalid email format: \(editingEmail)")
                    await MainActor.run {
                        showResetError = true
                        resetErrorMessage = "Please enter a valid email address."
                    }
                    return
                }
                
                // Basic phone number validation - exactly 10 digits
                if !editingContact.isEmpty {
                    let phoneRegex = "^[0-9]{10}$"
                    let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
                    
                    if !phonePredicate.evaluate(with: editingContact) {
                        print("Invalid phone format: \(editingContact)")
                        await MainActor.run {
                            showResetError = true
                            resetErrorMessage = "Please enter a valid 10-digit phone number."
                        }
                        return
                    }
                }
                
                print("Preparing update data for email: \(editingEmail) and contact: \(editingContact)")
                
                // Update the lab admin information in Supabase
                let updateData: [String: Any] = [
                    "email": editingEmail,
                    "contact_number": editingContact,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                print("Sending update to Supabase...")
                try await SupabaseController.shared.update(
                    table: "lab_admins",
                    id: labAdmin.id,
                    data: updateData
                )
                
                print("Update call completed successfully")
                
                // Verify the update was successful
                let updatedLabAdmins = try await SupabaseController.shared.select(
                    from: "lab_admins",
                    where: "id",
                    equals: labAdmin.id
                )
                
                if let updatedAdmin = updatedLabAdmins.first,
                   let updatedEmail = updatedAdmin["email"] as? String,
                   let updatedContact = updatedAdmin["contact_number"] as? String {
                    print("Profile update verification:")
                    print("- Email update: \(updatedEmail == editingEmail ? "SUCCESS" : "FAILED")")
                    print("- Contact update: \(updatedContact == editingContact ? "SUCCESS" : "FAILED")")
                } else {
                    print("Could not verify profile update - failed to fetch updated record")
                }
                
                // Show success message
                await MainActor.run {
                    isEditing = false
                    showSaveSuccess = true
                }
            } catch {
                print("Failed to update profile: \(error.localizedDescription)")
                await MainActor.run {
                    showResetError = true
                    resetErrorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handlePasswordReset() {
        // Implement password reset logic with Supabase
        Task {
            do {
                // Validate password against the constraints in the schema
                let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]+$"
                let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
                
                // Check password length
                if newPassword.count < 8 {
                    await MainActor.run {
                        showResetPasswordSheet = false
                        showResetError = true
                        resetErrorMessage = "Password must be at least 8 characters long."
                    }
                    return
                }
                
                // Check password complexity
                if !passwordPredicate.evaluate(with: newPassword) {
                    await MainActor.run {
                        showResetPasswordSheet = false
                        showResetError = true
                        resetErrorMessage = "Password must contain at least one uppercase letter, one lowercase letter, one digit, and one special character (@$!%*?&)."
                    }
                    return
                }
                
                // Confirm password match
                if newPassword != confirmPassword {
                    await MainActor.run {
                        showResetPasswordSheet = false
                        showResetError = true
                        resetErrorMessage = "New password and confirmation do not match."
                    }
                    return
                }
                
                print("Fetching lab admin data for ID: \(labAdmin.id)")
                
                // Verify the current password against Supabase
                let labAdmins = try await SupabaseController.shared.select(
                    from: "lab_admins",
                    where: "id",
                    equals: labAdmin.id
                )
                
                print("Lab admin data fetched. Records found: \(labAdmins.count)")
                
                guard let labAdminData = labAdmins.first else {
                    print("ERROR: No lab admin data found with ID: \(labAdmin.id)")
                    await MainActor.run {
                        showResetPasswordSheet = false
                        showResetError = true
                        resetErrorMessage = "Failed to retrieve your account information."
                    }
                    return
                }
                
                // Check if password field exists in the data
                if let storedPassword = labAdminData["password"] as? String {
                    print("Retrieved stored password hash. Length: \(storedPassword.count)")
                    
                    // Compare with entered current password
                    if storedPassword != currentPassword {
                        print("ERROR: Current password does not match stored password")
                        await MainActor.run {
                            showResetPasswordSheet = false
                            showResetError = true
                            resetErrorMessage = "Current password is incorrect."
                        }
                        return
                    }
                    
                    print("Current password verified successfully")
                } else {
                    print("ERROR: No password field found in lab admin data")
                    await MainActor.run {
                        showResetPasswordSheet = false
                        showResetError = true
                        resetErrorMessage = "Password field not found in your account."
                    }
                    return
                }
                
                // Debug print to trace the update call
                print("Updating password for lab admin with ID: \(labAdmin.id)")
                
                // Create update data dictionary
                let updateData: [String: Any] = [
                    "password": newPassword,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                print("Update data prepared: \(updateData)")
                
                // Update the password in Supabase with debug logging
                do {
                    try await SupabaseController.shared.update(
                        table: "lab_admins",
                        id: labAdmin.id,
                        data: updateData
                    )
                    print("Password update call completed successfully")
                } catch {
                    print("Password update failed with error: \(error.localizedDescription)")
                    throw error
                }
                
                // Verify the update was successful
                let updatedLabAdmins = try await SupabaseController.shared.select(
                    from: "lab_admins",
                    where: "id",
                    equals: labAdmin.id
                )
                
                if let updatedAdmin = updatedLabAdmins.first,
                   let updatedPassword = updatedAdmin["password"] as? String,
                   updatedPassword == newPassword {
                    print("Password verification after update: SUCCESS")
                } else {
                    print("Password verification after update: FAILED or couldn't verify")
                }
                
                // Reset forms and show success message
                await MainActor.run {
                    showResetPasswordSheet = false
                    showResetSuccess = true
                    
                    // Reset form fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            } catch {
                print("Password reset error: \(error.localizedDescription)")
                await MainActor.run {
                    showResetPasswordSheet = false
                    showResetError = true
                    resetErrorMessage = "Failed to reset password: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Custom InfoRow just for this view to avoid conflicts
struct LabProfileInfoRow: View {
    let title: String
    let value: String
    
    // App theme colors
    let primaryTeal = Color(red: 43/255, green: 182/255, blue: 205/255)
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
    }
}

// Custom white GroupBox style
struct WhiteGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
            VStack {
                configuration.content
            }
            .padding(.top, 6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.gray.opacity(0.2), radius: 3)
        )
    }
}

#Preview {
    NavigationStack {
        LabAdminHomeView()
            .environmentObject(AppNavigationState())
    }
} 
