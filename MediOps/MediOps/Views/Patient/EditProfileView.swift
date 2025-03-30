import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = EditProfileViewModel()

    var body: some View {
        // Implementation of the view
        Text("Edit Profile View")
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}

class EditProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var bloodGroup: String = ""
    @Published var phoneNumber: String = ""
    @Published var address: String = ""
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactNumber: String = ""
    @Published var emergencyRelationship: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var showingSuccessAlert: Bool = false

    private let supabase: SupabaseController
    private let patientController: PatientProfileController

    init(supabase: SupabaseController = SupabaseController.shared, patientController: PatientProfileController = PatientProfileController()) {
        self.supabase = supabase
        self.patientController = patientController
    }

    func updateProfile() {
        print("📱 EDIT PROFILE: Starting profile update")
        isLoading = true
        error = nil
        
        guard let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                          UserDefaults.standard.string(forKey: "current_user_id") else {
            print("📱 EDIT PROFILE ERROR: No user ID found in UserDefaults")
            error = "No user ID found. Please sign in again."
            isLoading = false
            return
        }
        
        print("📱 EDIT PROFILE: Updating profile for user \(userId)")
        print("📱 EDIT PROFILE: Blood Group being saved: \(bloodGroup)")
        
        // Create patient data dictionary with all fields
        var patientData: [String: Any] = [
            "name": name,
            "age": age,
            "gender": gender,
            "blood_group": bloodGroup, // Using snake_case for consistency with database
            "phone_number": phoneNumber,
            "address": address,
            "emergency_contact_name": emergencyContactName,
            "emergency_contact_number": emergencyContactNumber,
            "emergency_relationship": emergencyRelationship
        ]
        
        Task {
            do {
                // Fetch the current patient record to get the ID
                print("📱 EDIT PROFILE: Fetching current patient record")
                let patients = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                guard let patient = patients.first, let patientId = patient["id"] as? String else {
                    print("📱 EDIT PROFILE ERROR: Could not find patient record for user \(userId)")
                    await MainActor.run {
                        error = "Could not find your patient record."
                        isLoading = false
                    }
                    return
                }
                
                print("📱 EDIT PROFILE: Found patient with ID: \(patientId)")
                
                // Also ensure patient_id exists if it's missing (for backward compatibility)
                if patient["patient_id"] == nil {
                    patientData["patient_id"] = patientId
                    print("📱 EDIT PROFILE: Adding missing patient_id field with value: \(patientId)")
                }
                
                // Update the patient record
                print("📱 EDIT PROFILE: Updating patient record with data: \(patientData)")
                let result = try await supabase.update(
                    table: "patients",
                    id: patientId,
                    data: patientData
                )
                
                print("📱 EDIT PROFILE: Profile updated successfully")
                print("📱 EDIT PROFILE: Updated data result: \(result)")
                
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                    
                    // Update the profile in the parent view
                    Task {
                        await patientController.loadProfile(userId: userId)
                    }
                }
            } catch {
                print("📱 EDIT PROFILE ERROR: Failed to update profile: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = "Failed to update profile: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
} 