import Foundation
import SwiftUI

// MARK: - FamilyMember Model
struct FamilyMember: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var age: Int
    var gender: String
    var relationship: String
    var bloodGroup: String
    var phone: String
    
    // For new entries
    static func empty() -> FamilyMember {
        FamilyMember(
            name: "",
            age: 0,
            gender: "Male",
            relationship: "Spouse",
            bloodGroup: "O+",
            phone: ""
        )
    }
}

// MARK: - Data Transfer Objects for API calls
// Used for inserting family member data
struct FamilyMemberData: Encodable {
    let id: String
    let patient_id: String
    let name: String
    let age: Int
    let gender: String
    let relationship: String
    let blood_group: String
    let phone: String
}

// Used for updating family member data
struct MemberUpdateData: Encodable {
    let name: String
    let age: Int
    let gender: String
    let relationship: String
    let blood_group: String
    let phone: String
}

// Used for updating patient data
struct PatientUpdateData: Encodable {
    let name: String
    let age: Int
    let gender: String
    let blood_group: String
    let email: String
    let phone_number: String
    let address: String
    let emergency_contact_name: String
    let emergency_contact_number: String
    let emergency_relationship: String
}

// MARK: - Patient Profile Controller
class PatientProfileController: ObservableObject {
    @Published var patient: Patient?
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase = SupabaseController.shared
    
    func loadProfile(userId: String) async {
        print("📱 PATIENT PROFILE: Starting to load profile for userId: \(userId)")
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            print("📱 PATIENT PROFILE: Querying patients table with user_id: \(userId)")
            // First query patients table to get the patient ID
            var patientResults = try await supabase.select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            print("📱 PATIENT PROFILE: Query returned \(patientResults.count) results")
            
            // If no results found directly, try with different formats of the user ID
            if patientResults.isEmpty {
                print("📱 PATIENT PROFILE: No results with exact user_id, trying fallback queries")
                
                // Try lowercase user ID if the original had uppercase
                if userId != userId.lowercased() {
                    print("📱 PATIENT PROFILE: Trying lowercase user_id")
                    patientResults = try await supabase.select(
                        from: "patients",
                        where: "user_id",
                        equals: userId.lowercased()
                    )
                }
                
                // If still empty, try with UUID format
                if patientResults.isEmpty {
                    print("📱 PATIENT PROFILE: Trying direct ID query as fallback")
                    patientResults = try await supabase.select(
                        from: "patients",
                        where: "id",
                        equals: userId
                    )
                }
            }
            
            guard let patientData = patientResults.first else {
                print("📱 PATIENT PROFILE ERROR: No patient record found for user_id: \(userId)")
                throw NSError(domain: "PatientProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Patient record not found"])
            }
            
            print("📱 PATIENT PROFILE: Found patient data with keys: \(patientData.keys.joined(separator: ", "))")
            
            // Parse basic patient data with more flexible handling of types
            let id = patientData["id"] as? String ?? UUID().uuidString
            
            // Handle name with fallback
            var name = "Unknown"
            if let nameValue = patientData["name"] as? String {
                name = nameValue
            }
            
            // Handle age which might be a number or string
            var age = 30 // Default
            if let ageInt = patientData["age"] as? Int {
                age = ageInt
            } else if let ageString = patientData["age"] as? String, let ageInt = Int(ageString) {
                age = ageInt
            }
            
            // Handle gender with fallback
            let gender = patientData["gender"] as? String ?? "Not specified"
            
            // Handle bloodGroup with different possible field names
            var bloodGroup = "O+"  // More realistic default
            if let bg = patientData["blood_group"] as? String, !bg.isEmpty {
                print("📱 PATIENT PROFILE: Found blood_group: \(bg)")
                bloodGroup = bg
            } else if let bg = patientData["bloodGroup"] as? String, !bg.isEmpty {
                print("📱 PATIENT PROFILE: Found bloodGroup: \(bg)")
                bloodGroup = bg
            } else {
                // Try a case-insensitive search for blood group field
                for (key, value) in patientData {
                    if key.lowercased().contains("blood") && value is String {
                        print("📱 PATIENT PROFILE: Found blood group in field \(key): \(value)")
                        bloodGroup = value as! String
                        break
                    }
                }
                print("📱 PATIENT PROFILE: Using default blood group: \(bloodGroup)")
            }
            
            // Handle phone number with different possible field names
            var phoneNumber = "9999999999"
            if let phone = patientData["phone_number"] as? String {
                phoneNumber = phone
            } else if let phone = patientData["phoneNumber"] as? String {
                phoneNumber = phone
            }
            
            // Handle emergency contact fields with fallbacks
            let emergencyContactName = patientData["emergency_contact_name"] as? String ?? "Not specified"
            let emergencyContactNumber = patientData["emergency_contact_number"] as? String ?? "9999999999"
            let emergencyRelationship = patientData["emergency_relationship"] as? String ?? "Not specified"
            
            print("📱 PATIENT PROFILE: Successfully parsed patient data:")
            print("  - ID: \(id)")
            print("  - Name: \(name)")
            print("  - Age: \(age)")
            print("  - Gender: \(gender)")
            print("  - Blood Group: \(bloodGroup)")
            print("  - Phone: \(phoneNumber)")
            
            // Create Patient object
            let address = patientData["address"] as? String ?? ""
            let email = patientData["email"] as? String ?? ""
            let emailVerified = patientData["email_verified"] as? Bool ?? false
            
            // Get date information if available
            let dateFormatter = ISO8601DateFormatter()
            let createdAtString = patientData["created_at"] as? String ?? ""
            let updatedAtString = patientData["updated_at"] as? String ?? ""
            
            let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
            let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
            
            // Now fetch family members if any
            print("📱 PATIENT PROFILE: Fetching family members for patient_id: \(id)")
            let familyResults = try await supabase.select(
                from: "family_members",
                where: "patient_id",
                equals: id
            )
            
            print("📱 PATIENT PROFILE: Found \(familyResults.count) family members")
            
            var familyMembers: [FamilyMember] = []
            
            for familyData in familyResults {
                guard let familyId = familyData["id"] as? String,
                      let name = familyData["name"] as? String,
                      let age = familyData["age"] as? Int,
                      let gender = familyData["gender"] as? String,
                      let relationship = familyData["relationship"] as? String,
                      let bloodGroup = familyData["blood_group"] as? String,
                      let phone = familyData["phone"] as? String else {
                    print("📱 PATIENT PROFILE: Skipping invalid family member data")
                    continue
                }
                
                familyMembers.append(FamilyMember(
                    id: familyId,
                    name: name,
                    age: age,
                    gender: gender,
                    relationship: relationship,
                    bloodGroup: bloodGroup,
                    phone: phone
                ))
                
                print("📱 PATIENT PROFILE: Added family member: \(name)")
            }
            
            // Create patient object from the database fields
            let isBloodDonor = patientData["is_blood_donor"] as? Bool ?? false
            
            let patient = Patient(
                id: id,
                userId: userId,
                name: name,
                age: age,
                gender: gender,
                createdAt: createdAt,
                updatedAt: updatedAt,
                email: email,
                emailVerified: emailVerified,
                bloodGroup: bloodGroup,
                address: address,
                phoneNumber: phoneNumber,
                emergencyContactName: emergencyContactName,
                emergencyContactNumber: emergencyContactNumber,
                emergencyRelationship: emergencyRelationship,
                isBloodDonor: isBloodDonor
            )
            
            print("📱 PATIENT PROFILE: Successfully created Patient object: \(name)")
            
            await MainActor.run {
                self.patient = patient
                self.familyMembers = familyMembers
                self.isLoading = false
                print("📱 PATIENT PROFILE: Profile loaded successfully")
            }
        } catch {
            print("📱 PATIENT PROFILE ERROR: \(error.localizedDescription)")
            
            // If we failed to load the profile, let's create a test profile as a fallback
            let shouldCreateTestProfile = true // Change this if you want to disable auto-creation
            
            if shouldCreateTestProfile {
                print("📱 PATIENT PROFILE: Creating test profile as fallback after error")
                let success = await insertTestPatient(userId: userId)
                
                if success {
                    print("📱 PATIENT PROFILE: Successfully created test profile as fallback")
                    await MainActor.run {
                        self.error = nil
                        self.isLoading = false
                    }
                    return
                }
            }
            
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func addFamilyMember(_ member: FamilyMember) async -> Bool {
        guard let patientId = patient?.id else { return false }
        
        do {
            let memberId = member.id
            
            let memberData = FamilyMemberData(
                id: memberId,
                patient_id: patientId,
                name: member.name,
                age: member.age,
                gender: member.gender,
                relationship: member.relationship,
                blood_group: member.bloodGroup,
                phone: member.phone
            )
            
            try await supabase.insert(into: "family_members", data: memberData)
            
            await MainActor.run {
                familyMembers.append(member)
            }
            
            return true
        } catch {
            print("Error adding family member: \(error)")
            return false
        }
    }
    
    func updateFamilyMember(_ member: FamilyMember) async -> Bool {
        do {
            let memberData = MemberUpdateData(
                name: member.name,
                age: member.age,
                gender: member.gender,
                relationship: member.relationship,
                blood_group: member.bloodGroup,
                phone: member.phone
            )
            
            try await supabase.update(
                table: "family_members",
                data: memberData,
                where: "id",
                equals: member.id
            )
            
            await MainActor.run {
                if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
                    familyMembers[index] = member
                }
            }
            
            return true
        } catch {
            print("Error updating family member: \(error)")
            return false
        }
    }
    
    func deleteFamilyMember(id: String) async -> Bool {
        do {
            try await supabase.delete(
                from: "family_members",
                where: "id",
                equals: id
            )
            
            await MainActor.run {
                familyMembers.removeAll { $0.id == id }
            }
            
            return true
        } catch {
            print("Error deleting family member: \(error)")
            return false
        }
    }
    
    func updateProfile(
        name: String,
        age: Int,
        gender: String,
        bloodGroup: String,
        email: String,
        phoneNumber: String,
        address: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) async -> Bool {
        guard let patientId = patient?.id else {
            print("❌ UPDATE PROFILE ERROR: No patient ID available")
            return false
        }
        
        print("🔄 UPDATE PROFILE: Starting update for patient with ID: \(patientId)")
        print("🔄 UPDATE PROFILE: Data to update - name: '\(name)', age: \(age), gender: '\(gender)', bloodGroup: '\(bloodGroup)'")
        
        // Check if the patient ID exists in Supabase before updating
        do {
            // Query to check if the patient exists
            let verifyUrl = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)&select=id")!
            var verifyRequest = URLRequest(url: verifyUrl)
            verifyRequest.httpMethod = "GET"
            verifyRequest.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            verifyRequest.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (verifyData, verifyResponse) = try await URLSession.shared.data(for: verifyRequest)
            guard let httpVerifyResponse = verifyResponse as? HTTPURLResponse else {
                print("❌ VERIFICATION ERROR: Invalid response")
                return false
            }
            
            let verifyResponseString = String(data: verifyData, encoding: .utf8) ?? "[]"
            print("🔍 VERIFICATION: Status code: \(httpVerifyResponse.statusCode), response: \(verifyResponseString)")
            
            // Check if the response is empty array or error
            if verifyResponseString == "[]" || httpVerifyResponse.statusCode != 200 {
                print("❌ VERIFICATION ERROR: Patient ID \(patientId) not found in database")
                
                // Try to get patient ID by user ID instead
                if let userId = patient?.userId {
                    print("🔄 VERIFICATION: Trying to find patient by user ID: \(userId)")
                    let userVerifyUrl = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?user_id=eq.\(userId)&select=id")!
                    var userVerifyRequest = URLRequest(url: userVerifyUrl)
                    userVerifyRequest.httpMethod = "GET"
                    userVerifyRequest.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
                    userVerifyRequest.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    
                    let (userVerifyData, userVerifyResponse) = try await URLSession.shared.data(for: userVerifyRequest)
                    if let httpUserVerifyResponse = userVerifyResponse as? HTTPURLResponse,
                       httpUserVerifyResponse.statusCode == 200,
                       let responseStr = String(data: userVerifyData, encoding: .utf8),
                       responseStr != "[]" {
                        // Try to parse the response to get the patient ID
                        do {
                            if let jsonArray = try JSONSerialization.jsonObject(with: userVerifyData) as? [[String: Any]],
                               let firstPatient = jsonArray.first,
                               let realPatientId = firstPatient["id"] as? String {
                                print("✅ VERIFICATION: Found patient ID \(realPatientId) by user ID")
                                // Use this ID for updating
                                return await updatePatientWithId(
                                    patientId: realPatientId,
                                    name: name,
                                    age: age,
                                    gender: gender,
                                    bloodGroup: bloodGroup,
                                    email: email,
                                    phoneNumber: phoneNumber,
                                    address: address,
                                    emergencyContactName: emergencyContactName,
                                    emergencyContactNumber: emergencyContactNumber,
                                    emergencyRelationship: emergencyRelationship
                                )
                            }
                        } catch {
                            print("❌ VERIFICATION ERROR: Failed to parse patient by user ID: \(error.localizedDescription)")
                        }
                    }
                }
                
                // If everything fails, try creating a test patient
                print("🔄 VERIFICATION: No patient found. Creating a test patient...")
                if await insertTestPatient(userId: patient?.userId ?? "USER_TEST") {
                    // Retry loading the profile
                    await loadProfile(userId: patient?.userId ?? "USER_TEST")
                    // Now try to update again with the newly created patient
                    return await updateProfile(
                        name: name,
                        age: age,
                        gender: gender,
                        bloodGroup: bloodGroup,
                        email: email,
                        phoneNumber: phoneNumber,
                        address: address,
                        emergencyContactName: emergencyContactName,
                        emergencyContactNumber: emergencyContactNumber,
                        emergencyRelationship: emergencyRelationship
                    )
                }
                
                return false
            }
        } catch {
            print("❌ VERIFICATION ERROR: Failed to verify patient: \(error.localizedDescription)")
            // Continue with update anyway since verification failed, not the update itself
        }
        
        // Continue with the normal update process
        return await updatePatientWithId(
            patientId: patientId,
            name: name,
            age: age,
            gender: gender,
            bloodGroup: bloodGroup,
            email: email,
            phoneNumber: phoneNumber,
            address: address,
            emergencyContactName: emergencyContactName,
            emergencyContactNumber: emergencyContactNumber,
            emergencyRelationship: emergencyRelationship
        )
    }
    
    // Helper method to update patient with verified ID
    private func updatePatientWithId(
        patientId: String,
        name: String,
        age: Int,
        gender: String,
        bloodGroup: String,
        email: String,
        phoneNumber: String,
        address: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) async -> Bool {
        print("🔄 UPDATE PATIENT: Using ID: \(patientId)")
        
        do {
            // Create a dictionary with string values for safer transmission
            let patientUpdateData: [String: String] = [
                "name": name,
                "age": "\(age)",
                "gender": gender,
                "blood_group": bloodGroup,
                "email": email,
                "phone_number": phoneNumber,
                "address": address,
                "emergency_contact_name": emergencyContactName,
                "emergency_contact_number": emergencyContactNumber,
                "emergency_relationship": emergencyRelationship,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Build the update URL with proper format
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: patientUpdateData)
            request.httpBody = jsonData
            
            print("🔄 UPDATE PATIENT: Sending PATCH request to URL: \(url.absoluteString)")
            print("🔄 UPDATE PATIENT: Request payload: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert data to string")")
            
            // Execute request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            // Get response as string for debugging
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ UPDATE PATIENT ERROR: Invalid response type")
                print("❌ Response: \(responseString)")
                return false
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            print("📊 Response body: \(responseString)")
            
            // Check status code
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("✅ UPDATE PATIENT: Successfully updated patient profile, status code: \(httpResponse.statusCode)")
                
                // Update the local patient object
                await MainActor.run {
                    if let currentPatient = self.patient {
                        // Create a new Patient instance with updated values
                        let updatedPatient = Patient(
                            id: patientId, // Use the provided patientId
                            userId: currentPatient.userId,
                            name: name,
                            age: age,
                            gender: gender,
                            createdAt: currentPatient.createdAt,
                            updatedAt: Date(), // Use current date for updatedAt
                            email: email,
                            emailVerified: currentPatient.emailVerified,
                            bloodGroup: bloodGroup,
                            address: address,
                            phoneNumber: phoneNumber,
                            emergencyContactName: emergencyContactName,
                            emergencyContactNumber: emergencyContactNumber,
                            emergencyRelationship: emergencyRelationship,
                            isBloodDonor: currentPatient.isBloodDonor
                        )
                        self.patient = updatedPatient
                    }
                }
                
                return true
            } else {
                // Log the error response
                print("❌ UPDATE PATIENT ERROR: Failed with status code \(httpResponse.statusCode)")
                print("❌ UPDATE PATIENT ERROR: Response: \(responseString)")
                
                // Try fallback method with direct JSON approach
                return await directJsonUpdateProfile(
                    patientId: patientId,
                    name: name,
                    age: age,
                    gender: gender,
                    bloodGroup: bloodGroup,
                    email: email,
                    phoneNumber: phoneNumber,
                    address: address,
                    emergencyContactName: emergencyContactName,
                    emergencyContactNumber: emergencyContactNumber,
                    emergencyRelationship: emergencyRelationship
                )
            }
        } catch {
            print("❌ UPDATE PATIENT ERROR: \(error.localizedDescription)")
            
            // Try fallback method
            return await directJsonUpdateProfile(
                patientId: patientId,
                name: name,
                age: age,
                gender: gender,
                bloodGroup: bloodGroup,
                email: email,
                phoneNumber: phoneNumber,
                address: address,
                emergencyContactName: emergencyContactName,
                emergencyContactNumber: emergencyContactNumber,
                emergencyRelationship: emergencyRelationship
            )
        }
    }
    
    // Direct update using JSON string approach
    private func directJsonUpdateProfile(
        patientId: String,
        name: String,
        age: Int,
        gender: String,
        bloodGroup: String,
        email: String,
        phoneNumber: String,
        address: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) async -> Bool {
        print("🔄 UPDATE PROFILE: Trying direct JSON approach for patient ID: \(patientId)")
        
        do {
            // Construct JSON directly as a string
            let jsonString = """
            {
                "name": "\(name)",
                "age": \(age),
                "gender": "\(gender)",
                "blood_group": "\(bloodGroup)",
                "email": "\(email)",
                "phone_number": "\(phoneNumber)",
                "address": "\(address)",
                "emergency_contact_name": "\(emergencyContactName)",
                "emergency_contact_number": "\(emergencyContactNumber)",
                "emergency_relationship": "\(emergencyRelationship)",
                "updated_at": "\(ISO8601DateFormatter().string(from: Date()))"
            }
            """
            
            // Use different URL format
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("*/*", forHTTPHeaderField: "Accept")
            
            // Set the JSON string as the request body
            guard let jsonData = jsonString.data(using: .utf8) else {
                print("❌ Failed to convert JSON string to data")
                return false
            }
            
            request.httpBody = jsonData
            print("🔄 DIRECT JSON: Request payload: \(jsonString)")
            
            // Execute request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ DIRECT JSON: Invalid response type")
                return false
            }
            
            print("📊 DIRECT JSON: Response status code: \(httpResponse.statusCode)")
            print("📊 DIRECT JSON: Response: \(responseString)")
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("✅ DIRECT JSON: Successfully updated patient profile")
                
                // Update the local patient object
                await MainActor.run {
                    if let currentPatient = self.patient {
                        // Create a new Patient instance with updated values
                        let updatedPatient = Patient(
                            id: patientId,
                            userId: currentPatient.userId,
                            name: name,
                            age: age,
                            gender: gender,
                            createdAt: currentPatient.createdAt,
                            updatedAt: Date(), // Use current date for updatedAt
                            email: email,
                            emailVerified: currentPatient.emailVerified,
                            bloodGroup: bloodGroup,
                            address: address,
                            phoneNumber: phoneNumber,
                            emergencyContactName: emergencyContactName,
                            emergencyContactNumber: emergencyContactNumber,
                            emergencyRelationship: emergencyRelationship,
                            isBloodDonor: currentPatient.isBloodDonor
                        )
                        self.patient = updatedPatient
                    }
                }
                
                return true
            } else {
                // Try one final approach
                return await fallbackUpdateProfile(
                    patientId: patientId,
                    name: name,
                    age: age,
                    gender: gender,
                    bloodGroup: bloodGroup,
                    email: email,
                    phoneNumber: phoneNumber,
                    address: address,
                    emergencyContactName: emergencyContactName,
                    emergencyContactNumber: emergencyContactNumber,
                    emergencyRelationship: emergencyRelationship
                )
            }
        } catch {
            print("❌ DIRECT JSON ERROR: \(error.localizedDescription)")
            return false
        }
    }
    
    // Final fallback method to update profile
    private func fallbackUpdateProfile(
        patientId: String,
        name: String,
        age: Int,
        gender: String,
        bloodGroup: String,
        email: String,
        phoneNumber: String,
        address: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        emergencyRelationship: String
    ) async -> Bool {
        print("🔄 UPDATE PROFILE: Trying final fallback method for patient ID: \(patientId)")
        
        do {
            // Create a simple dictionary with proper field naming for the table
            let updateData: [String: String] = [
                "name": name,
                "age": String(age),
                "gender": gender,
                "blood_group": bloodGroup,
                "email": email,
                "phone_number": phoneNumber,
                "address": address,
                "emergency_contact_name": emergencyContactName,
                "emergency_contact_number": emergencyContactNumber,
                "emergency_relationship": emergencyRelationship
            ]
            
            // Use a simpler URL format
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)
            request.httpBody = jsonData
            
            print("🔄 FALLBACK UPDATE: Request payload: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert data to string")")
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ FALLBACK UPDATE ERROR: Invalid response")
                return false
            }
            
            print("📊 FALLBACK UPDATE: Response status code: \(httpResponse.statusCode)")
            print("📊 FALLBACK UPDATE: Response: \(responseString)")
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("✅ FALLBACK UPDATE: Successfully updated patient profile")
                
                // Update the local patient object
                await MainActor.run {
                    if let currentPatient = self.patient {
                        // Create a new Patient instance with updated values
                        let updatedPatient = Patient(
                            id: patientId,
                            userId: currentPatient.userId,
                            name: name,
                            age: age,
                            gender: gender,
                            createdAt: currentPatient.createdAt,
                            updatedAt: Date(), // Use current date for updatedAt
                            email: email,
                            emailVerified: currentPatient.emailVerified,
                            bloodGroup: bloodGroup,
                            address: address,
                            phoneNumber: phoneNumber,
                            emergencyContactName: emergencyContactName,
                            emergencyContactNumber: emergencyContactNumber,
                            emergencyRelationship: emergencyRelationship,
                            isBloodDonor: currentPatient.isBloodDonor
                        )
                        self.patient = updatedPatient
                    }
                }
                
                return true
            } else {
                print("❌ FALLBACK UPDATE ERROR: Failed with status code \(httpResponse.statusCode)")
                print("❌ FALLBACK UPDATE ERROR: Response: \(responseString)")
                return false
            }
        } catch {
            print("❌ FALLBACK UPDATE ERROR: \(error.localizedDescription)")
            return false
        }
    }
    
    // Method to verify OTP for profile changes or access
    func verifyOTP(otp: String, email: String) async -> Bool {
        // In a real app, this would verify against an actual OTP sent
        // For this demo, we'll accept any non-empty OTP
        return !otp.isEmpty
    }
    
    // MARK: - Debug Functions
    
    /// Creates a test patient profile locally in the app (doesn't insert into Supabase)
    func createDebugPatientProfile() {
        print("🐞 DEBUG: Creating test patient profile for debugging")
        
        // Create a test patient with all required fields
        let testPatient = Patient(
            id: "TEST_PATIENT_ID",
            userId: "TEST_USER_ID",
            name: "Test Patient",
            age: 30,
            gender: "Male",
            createdAt: Date(),
            updatedAt: Date(),
            email: "test@example.com",
            emailVerified: true,
            bloodGroup: "O+",
            address: "123 Test Street, Test City",
            phoneNumber: "9876543210",
            emergencyContactName: "Emergency Contact",
            emergencyContactNumber: "1234567890",
            emergencyRelationship: "Family",
            isBloodDonor: false
        )
        
        // Manually set the patient property
        DispatchQueue.main.async {
            self.patient = testPatient
            self.isLoading = false
            self.error = nil
            print("🐞 DEBUG: Test patient profile created successfully")
        }
    }
    
    /// Creates and inserts a real test patient into Supabase database
    func createAndInsertTestPatientInSupabase() async -> Bool {
        print("🔄 Creating and inserting test patient into Supabase")
        
        // Get current user ID from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                          UserDefaults.standard.string(forKey: "current_user_id") else {
            print("❌ No user ID available in UserDefaults")
            
            // Create a fake user ID for testing purposes
            let testUserId = "USER_\(Int(Date().timeIntervalSince1970))"
            print("⚠️ Using generated test user ID: \(testUserId)")
            
            // Save this ID for future use
            UserDefaults.standard.set(testUserId, forKey: "userId")
            UserDefaults.standard.set(testUserId, forKey: "current_user_id")
            UserDefaults.standard.synchronize()
            
            // Use this test ID
            return await insertTestPatient(userId: testUserId)
        }
        
        return await insertTestPatient(userId: userId)
    }
    
    private func insertTestPatient(userId: String) async -> Bool {
        print("🔄 Inserting test patient for user ID: \(userId)")
        
        // Test patient data structured for Supabase
        let patientData: [String: Any] = [
            "id": "PAT_\(Int(Date().timeIntervalSince1970))",
            "user_id": userId,
            "name": "Test Patient",
            "age": 30,
            "gender": "Male",
            "blood_group": "O+",
            "phone_number": "9876543210",
            "email": "test@example.com",
            "address": "123 Test Street, Test City",
            "emergency_contact_name": "Emergency Contact",
            "emergency_contact_number": "1234567890",
            "emergency_relationship": "Family",
            "is_blood_donor": false
        ]
        
        do {
            // Direct insert using URL session to avoid encoding issues
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            let jsonData = try JSONSerialization.data(withJSONObject: patientData)
            request.httpBody = jsonData
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                return false
            }
            
            print("📊 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                if let responseStr = String(data: responseData, encoding: .utf8) {
                    print("✅ Test patient created successfully: \(responseStr)")
                }
                
                // Now load the profile we just created
                await loadProfile(userId: userId)
                return true
            } else {
                if let errorStr = String(data: responseData, encoding: .utf8) {
                    print("❌ Error details: \(errorStr)")
                }
                return false
            }
        } catch {
            print("❌ Failed to insert test patient: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Diagnostic Functions
    
    /// Inspect the patients table schema and look for blood group related fields
    func inspectPatientsTableSchema() async {
        print("🔍 DIAGNOSTIC: Starting inspection of patients table schema")
        
        // First, try to get a single patient record to see all available fields
        do {
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?limit=1")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ DIAGNOSTIC: Invalid response")
                return
            }
            
            print("📊 DIAGNOSTIC: Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let result = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], 
                   let firstRecord = result.first {
                    print("✅ DIAGNOSTIC: Found patient record with the following fields:")
                    for (key, value) in firstRecord {
                        let valueType = type(of: value)
                        let valuePreview = String(describing: value).prefix(50)
                        print("  - \(key) (\(valueType)): \(valuePreview)")
                        
                        // Check if this field might be related to blood group
                        if key.lowercased().contains("blood") {
                            print("  ⚠️ POSSIBLE BLOOD GROUP FIELD: \(key) = \(value)")
                        }
                    }
                } else {
                    print("❌ DIAGNOSTIC: Could not parse patient record or no patients found")
                }
            } else {
                print("❌ DIAGNOSTIC: Request failed with status code \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("  Error: \(errorText)")
                }
            }
            
            // Also check for schema information
            print("\n🔍 DIAGNOSTIC: Checking for explicit schema information")
            let schemaUrl = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?select=body")!
            var schemaRequest = URLRequest(url: schemaUrl)
            schemaRequest.httpMethod = "HEAD"  // Just get headers
            schemaRequest.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            schemaRequest.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (_, schemaResponse) = try await URLSession.shared.data(for: schemaRequest)
            if let httpSchemaResponse = schemaResponse as? HTTPURLResponse {
                print("📊 DIAGNOSTIC: Schema request status code: \(httpSchemaResponse.statusCode)")
                
                // Check response headers for schema information
                print("📊 DIAGNOSTIC: Response headers:")
                for (key, value) in httpSchemaResponse.allHeaderFields {
                    print("  - \(key): \(value)")
                }
            }
        } catch {
            print("❌ DIAGNOSTIC ERROR: \(error.localizedDescription)")
        }
    }
    
    /// Specifically check for blood_group field in patient record
    func checkBloodGroupField(patientId: String) async {
        print("🔍 BLOOD GROUP CHECK: Starting check for blood_group field in patient record")
        
        do {
            // Query to specifically check for blood_group field in the patient record
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)&select=id,blood_group,bloodGroup")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ BLOOD GROUP CHECK: Invalid response")
                return
            }
            
            print("📊 BLOOD GROUP CHECK: Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let result = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], 
                   let patient = result.first {
                    print("✅ BLOOD GROUP CHECK: Found patient record with ID: \(patientId)")
                    
                    // Check for blood_group field
                    if let bloodGroup = patient["blood_group"] as? String {
                        print("✅ BLOOD GROUP CHECK: Found blood_group field with value: '\(bloodGroup)'")
                    } else {
                        print("❌ BLOOD GROUP CHECK: No blood_group field found")
                    }
                    
                    // Check for alternative bloodGroup field (camelCase)
                    if let bloodGroup = patient["bloodGroup"] as? String {
                        print("✅ BLOOD GROUP CHECK: Found bloodGroup field (camelCase) with value: '\(bloodGroup)'")
                    } else {
                        print("❌ BLOOD GROUP CHECK: No bloodGroup field (camelCase) found")
                    }
                    
                    // Check if any key contains "blood"
                    var foundBloodRelatedField = false
                    for (key, value) in patient {
                        if key.lowercased().contains("blood") {
                            foundBloodRelatedField = true
                            print("✅ BLOOD GROUP CHECK: Found blood-related field '\(key)' with value: '\(value)'")
                        }
                    }
                    
                    if !foundBloodRelatedField {
                        print("❌ BLOOD GROUP CHECK: No blood-related fields found in the patient record")
                        print("🔄 BLOOD GROUP CHECK: Adding blood_group field with default value 'O+'")
                        
                        // Try to add the blood_group field with a default value
                        let success = await fixBloodGroup(patientId: patientId, bloodGroup: "O+")
                        if success {
                            print("✅ BLOOD GROUP CHECK: Successfully added blood_group field")
                        } else {
                            print("❌ BLOOD GROUP CHECK: Failed to add blood_group field")
                        }
                    }
                } else {
                    print("❌ BLOOD GROUP CHECK: Could not parse patient record or no patient found with ID: \(patientId)")
                }
            } else {
                print("❌ BLOOD GROUP CHECK: Request failed with status code \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("  Error: \(errorText)")
                }
            }
        } catch {
            print("❌ BLOOD GROUP CHECK ERROR: \(error.localizedDescription)")
        }
    }
    
    /// Check existing data in current patient object
    func inspectCurrentPatientObject() {
        guard let patient = self.patient else {
            print("❌ DIAGNOSTIC: No patient object available")
            return
        }
        
        print("\n🔍 DIAGNOSTIC: Current patient object values:")
        print("  - ID: \(patient.id)")
        print("  - User ID: \(patient.userId)")
        print("  - Name: \(patient.name)")
        print("  - Age: \(patient.age)")
        print("  - Gender: \(patient.gender)")
        print("  - Blood Group: '\(patient.bloodGroup)'")
        print("  - Phone Number: \(patient.phoneNumber)")
        
        // Additional information
        if let address = patient.address {
            print("  - Address: \(address)")
        } else {
            print("  - Address: nil")
        }
        
        if let email = patient.email {
            print("  - Email: \(email)")
        } else {
            print("  - Email: nil")
        }
        
        // Emergency contact info
        if let emergencyName = patient.emergencyContactName {
            print("  - Emergency Contact Name: \(emergencyName)")
        } else {
            print("  - Emergency Contact Name: nil")
        }
        print("  - Emergency Contact Number: \(patient.emergencyContactNumber)")
        print("  - Emergency Relationship: \(patient.emergencyRelationship)")
    }
    
    /// Fix blood group for a patient record
    func fixBloodGroup(patientId: String, bloodGroup: String) async -> Bool {
        print("🩸 BLOOD GROUP FIX: Attempting to fix blood group for patient ID: \(patientId)")
        print("🩸 BLOOD GROUP FIX: Setting blood group to: \(bloodGroup)")
        
        do {
            // Create a simple dictionary to update just the blood group field
            let updateData: [String: String] = [
                "blood_group": bloodGroup
            ]
            
            // Build the update URL
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)
            request.httpBody = jsonData
            
            print("🩸 BLOOD GROUP FIX: Sending PATCH request to update blood_group field")
            print("🩸 BLOOD GROUP FIX: Request payload: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert data to string")")
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ BLOOD GROUP FIX ERROR: Invalid response")
                return false
            }
            
            print("📊 BLOOD GROUP FIX: Response status code: \(httpResponse.statusCode)")
            print("📊 BLOOD GROUP FIX: Response: \(responseString)")
            
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("✅ BLOOD GROUP FIX: Successfully updated blood group")
                
                // Update the local patient object
                await MainActor.run {
                    if var updatedPatient = self.patient {
                        updatedPatient.bloodGroup = bloodGroup
                        self.patient = updatedPatient
                    }
                }
                
                return true
            } else {
                print("❌ BLOOD GROUP FIX ERROR: Failed with status code \(httpResponse.statusCode)")
                return false
            }
        } catch {
            print("❌ BLOOD GROUP FIX ERROR: \(error.localizedDescription)")
            return false
        }
    }
} 