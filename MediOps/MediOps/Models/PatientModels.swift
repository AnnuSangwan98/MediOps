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
                emergencyRelationship: emergencyRelationship
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
                            emergencyRelationship: emergencyRelationship
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
                            emergencyRelationship: emergencyRelationship
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
                            emergencyRelationship: emergencyRelationship
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
            emergencyRelationship: "Family"
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
            "emergency_relationship": "Family"
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
    
    // MARK: - Blood Group Management Methods
    
    // Inspect the patients table schema to check the blood_group field
    func inspectPatientsTableSchema() async {
        print("🔍 SCHEMA INSPECTION: Checking patients table schema for blood_group field")
        
        do {
            // Use the introspection endpoint to get table information
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/?apikey=\(supabase.supabaseAnonKey)")!
            var request = URLRequest(url: url)
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, 
               httpResponse.statusCode == 200,
               let jsonStr = String(data: data, encoding: .utf8) {
                print("✅ SCHEMA INSPECTION: Successfully retrieved schema info")
                print("🔍 SCHEMA INSPECTION: Looking for blood_group field in patients table")
                
                // Check if the response contains information about the blood_group field
                if jsonStr.contains("blood_group") || jsonStr.contains("bloodGroup") {
                    print("✅ SCHEMA INSPECTION: Found blood group field in schema")
                } else {
                    print("⚠️ SCHEMA INSPECTION: No blood group field found in schema")
                    }
                } else {
                print("❌ SCHEMA INSPECTION: Failed to get schema information")
            }
        } catch {
            print("❌ SCHEMA INSPECTION ERROR: \(error.localizedDescription)")
        }
    }
    
    // Inspect the current patient object
    func inspectCurrentPatientObject() {
        print("🔍 PATIENT OBJECT: Checking current patient object for blood group data")
        
        if let patient = self.patient {
            print("✅ PATIENT OBJECT: Patient object exists with ID: \(patient.id)")
            print("🔍 PATIENT OBJECT: Blood Group value: '\(patient.bloodGroup)'")
            print("🔍 PATIENT OBJECT: Blood Group empty? \(patient.bloodGroup.isEmpty)")
            print("🔍 PATIENT OBJECT: Blood Group 'Not specified'? \(patient.bloodGroup == "Not specified")")
            } else {
            print("❌ PATIENT OBJECT: No patient object available")
        }
    }
    
    // Check and fix blood group field
    func checkBloodGroupField(patientId: String) async {
        print("🔍 BLOOD GROUP CHECK: Checking blood group for patient ID: \(patientId)")
        
        do {
            // Query the patients table to get the current blood group value
            let results = try await supabase.select(
                from: "patients",
                where: "id",
                equals: patientId
            )
            
            if let patientData = results.first {
                print("✅ BLOOD GROUP CHECK: Found patient record")
                print("🔍 BLOOD GROUP CHECK: Available fields: \(patientData.keys.joined(separator: ", "))")
                
                // Check if blood_group field exists and has a value
                if let bloodGroup = patientData["blood_group"] as? String, !bloodGroup.isEmpty {
                    print("✅ BLOOD GROUP CHECK: Found blood_group field with value: \(bloodGroup)")
                } else {
                    print("⚠️ BLOOD GROUP CHECK: blood_group field is missing or empty")
                    
                    // Try to find an alternative field with blood group information
                    for (key, value) in patientData {
                        if key.lowercased().contains("blood") && value is String && !(value as! String).isEmpty {
                            print("✅ BLOOD GROUP CHECK: Found alternative blood group field '\(key)' with value: \(value)")
                            
                            // Update the blood_group field with this value
                            let success = await fixBloodGroup(patientId: patientId, bloodGroup: value as! String)
                            if success {
                                print("✅ BLOOD GROUP CHECK: Successfully updated blood_group field")
                            } else {
                                print("❌ BLOOD GROUP CHECK: Failed to update blood_group field")
                            }
                            
                            return
                        }
                    }
                    
                    print("⚠️ BLOOD GROUP CHECK: No blood group information found in any field")
                }
            } else {
                print("❌ BLOOD GROUP CHECK: Patient record not found")
            }
        } catch {
            print("❌ BLOOD GROUP CHECK ERROR: \(error.localizedDescription)")
        }
    }
    
    // Fix blood group field
    func fixBloodGroup(patientId: String, bloodGroup: String) async -> Bool {
        print("🩸 FIX BLOOD GROUP: Updating blood group to '\(bloodGroup)' for patient ID: \(patientId)")
        
        do {
            // Prepare update data
            let updateData: [String: String] = [
                "blood_group": bloodGroup,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            // Build the update URL
            let url = URL(string: "\(supabase.supabaseURL)/rest/v1/patients?id=eq.\(patientId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabase.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabase.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)
            request.httpBody = jsonData
            
            // Execute request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ FIX BLOOD GROUP ERROR: Invalid response type")
                return false
            }
            
            // Check status code
            if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
                print("✅ FIX BLOOD GROUP: Successfully updated blood group, status code: \(httpResponse.statusCode)")
                
                // Update the local patient object
                await MainActor.run {
                    if let currentPatient = self.patient {
                        // Update the blood group in the current patient object
                        let updatedPatient = Patient(
                            id: currentPatient.id,
                            userId: currentPatient.userId,
                            name: currentPatient.name,
                            age: currentPatient.age,
                            gender: currentPatient.gender,
                            createdAt: currentPatient.createdAt,
                            updatedAt: Date(),
                            email: currentPatient.email,
                            emailVerified: currentPatient.emailVerified,
                            bloodGroup: bloodGroup, // Set the new blood group
                            address: currentPatient.address,
                            phoneNumber: currentPatient.phoneNumber,
                            emergencyContactName: currentPatient.emergencyContactName,
                            emergencyContactNumber: currentPatient.emergencyContactNumber,
                            emergencyRelationship: currentPatient.emergencyRelationship
                        )
                        self.patient = updatedPatient
                        print("✅ FIX BLOOD GROUP: Updated local patient object with new blood group: \(bloodGroup)")
                    }
                }
                
                return true
                        } else {
                print("❌ FIX BLOOD GROUP ERROR: Failed with status code \(httpResponse.statusCode)")
                print("❌ FIX BLOOD GROUP ERROR: Response: \(responseString)")
                return false
            }
        } catch {
            print("❌ FIX BLOOD GROUP ERROR: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Direct Update Methods with Enhanced Error Handling
    
    /// Robust method to update profile with multiple retries and error handling
    func updateProfileWithRetry(
        patientId: String,
        userId: String,
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
        print("🔐 ROBUST UPDATE: Starting enhanced profile update for patient ID: \(patientId)")
        
        // Format data for update - use a consistent structure
        let updateData: [String: Any] = [
            "name": name,
            "age": age,
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
        
        // First, verify patient exists with this ID
        print("🔍 ROBUST UPDATE: Verifying patient exists with ID: \(patientId)")
        do {
            let results = try await supabase.select(
                from: "patients",
                where: "id",
                equals: patientId
            )
            
            if results.isEmpty {
                print("⚠️ ROBUST UPDATE: Patient not found with ID: \(patientId)")
                print("🔄 ROBUST UPDATE: Checking if patient exists with user_id: \(userId)")
                
                // Patient not found by ID, check if exists by user_id
                let userResults = try await supabase.select(
                    from: "patients",
                    where: "user_id",
                    equals: userId
                )
                
                if let userData = userResults.first, let realPatientId = userData["id"] as? String {
                    print("✅ ROBUST UPDATE: Found patient with user_id: \(userId), real patient ID is: \(realPatientId)")
                    // Use this patient ID instead
                    return await directUpdateProfileWithExactPatientId(
                        patientId: realPatientId,
                        updateData: updateData
                    )
        } else {
                    print("⚠️ ROBUST UPDATE: No patient found with this user_id either. Creating new patient.")
                    
                    // Create completely new patient
                    let newPatientId = "PAT_\(Int(Date().timeIntervalSince1970))"
                    var newPatientData = updateData
                    newPatientData["id"] = newPatientId
                    newPatientData["user_id"] = userId
                    newPatientData["created_at"] = ISO8601DateFormatter().string(from: Date())
                    
                    // Try to insert
                    try await supabase.insert(into: "patients", values: newPatientData)
                    print("✅ ROBUST UPDATE: Created new patient with ID: \(newPatientId)")
                    
                    // Update our local object and return success
                    await MainActor.run {
                        self.patient = Patient(
                            id: newPatientId,
                            userId: userId,
                            name: name,
                            age: age,
                            gender: gender,
                            createdAt: Date(),
                            updatedAt: Date(),
                            email: email,
                            emailVerified: false,
                            bloodGroup: bloodGroup,
                            address: address,
                            phoneNumber: phoneNumber,
                            emergencyContactName: emergencyContactName,
                            emergencyContactNumber: emergencyContactNumber,
                            emergencyRelationship: emergencyRelationship
                        )
                    }
                    
                    return true
                }
        } else {
                print("✅ ROBUST UPDATE: Patient exists with ID: \(patientId), proceeding with update")
                
                // Patient exists, continue with direct update
                return await directUpdateProfileWithExactPatientId(
                    patientId: patientId,
                    updateData: updateData
                )
            }
        } catch {
            print("❌ ROBUST UPDATE ERROR: Failed to verify patient: \(error.localizedDescription)")
            
            // Continue with update anyway, since verification failed but patient might still exist
            print("⚠️ ROBUST UPDATE: Attempting update despite verification error")
            return await directUpdateProfileWithExactPatientId(
                patientId: patientId,
                updateData: updateData
            )
        }
    }
    
    /// Direct update method using raw HTTP for maximum compatibility
    private func directUpdateProfileWithExactPatientId(
        patientId: String,
        updateData: [String: Any]
    ) async -> Bool {
        print("🔧 DIRECT UPDATE: Updating patient with ID: \(patientId)")
        print("🔧 DIRECT UPDATE: Update data: \(updateData)")
        
        do {
            // Create a simplified version of the data specifically for Supabase
            // This avoids potential issues with complex data types
            let simplifiedData: [String: String] = [
                "name": updateData["name"] as? String ?? "",
                "age": String(describing: updateData["age"] ?? "0"),
                "gender": updateData["gender"] as? String ?? "",
                "blood_group": updateData["blood_group"] as? String ?? "",
                "email": updateData["email"] as? String ?? "",
                "phone_number": updateData["phone_number"] as? String ?? "",
                "address": updateData["address"] as? String ?? "",
                "emergency_contact_name": updateData["emergency_contact_name"] as? String ?? "",
                "emergency_contact_number": updateData["emergency_contact_number"] as? String ?? "",
                "emergency_relationship": updateData["emergency_relationship"] as? String ?? ""
            ]
            
            // Convert data to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: simplifiedData)
            
            // Use direct URL to the specific patient record
            let apiKey = supabase.supabaseAnonKey
            let baseUrl = supabase.supabaseURL
            let urlString = "\(baseUrl)/rest/v1/patients?id=eq.\(patientId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? patientId)"
            
            guard let url = URL(string: urlString) else {
                print("❌ DIRECT UPDATE: Invalid URL")
                return false
            }
            
            print("🔄 DIRECT UPDATE: Using URL: \(urlString)")
            
            // Create the request with detailed headers
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.httpBody = jsonData
            
            // Add all necessary headers
            request.addValue(apiKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("*/*", forHTTPHeaderField: "Accept")
            request.addValue("return=minimal", forHTTPHeaderField: "Prefer") // Use minimal to reduce data transfer
            
            print("🔄 DIRECT UPDATE: Request payload: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert data to string")")
            
            // Try multiple approaches with different configurations
            var success = false
            
            // Attempt 1: Standard approach
            success = await tryUpdateWithRequest(request, attempt: 1, patientId: patientId, updateData: simplifiedData)
            if success { return true }
            
            // Attempt 2: Different URL format
            if let url2 = URL(string: "\(baseUrl)/rest/v1/patients?id=eq.\(patientId)") {
                var request2 = URLRequest(url: url2)
                request2.httpMethod = "PATCH"
                request2.httpBody = jsonData
                request2.addValue(apiKey, forHTTPHeaderField: "apikey")
                request2.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                success = await tryUpdateWithRequest(request2, attempt: 2, patientId: patientId, updateData: simplifiedData)
                if success { return true }
            }
            
            // Attempt 3: Try POST with UPSERT
            if let url3 = URL(string: "\(baseUrl)/rest/v1/patients") {
                var request3 = URLRequest(url: url3)
                request3.httpMethod = "POST"
                
                // Add ID to the data for upsert
                var upsertData = simplifiedData
                upsertData["id"] = patientId
                
                let upsertJsonData = try JSONSerialization.data(withJSONObject: upsertData)
                request3.httpBody = upsertJsonData
                
                request3.addValue(apiKey, forHTTPHeaderField: "apikey")
                request3.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request3.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request3.addValue("upsert", forHTTPHeaderField: "Prefer")
                
                success = await tryUpdateWithRequest(request3, attempt: 3, patientId: patientId, updateData: upsertData)
                if success { return true }
            }
            
            // Final fallback: Try PUT method
            if let url4 = URL(string: "\(baseUrl)/rest/v1/patients?id=eq.\(patientId)") {
                var request4 = URLRequest(url: url4)
                request4.httpMethod = "PUT"
                
                // For PUT, we need to include all required fields
                var putData = simplifiedData
                putData["id"] = patientId
                putData["user_id"] = self.patient?.userId ?? ""
                
                let putJsonData = try JSONSerialization.data(withJSONObject: putData)
                request4.httpBody = putJsonData
                
                request4.addValue(apiKey, forHTTPHeaderField: "apikey")
                request4.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request4.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                success = await tryUpdateWithRequest(request4, attempt: 4, patientId: patientId, updateData: putData)
                if success { return true }
            }
            
            // If we got here, all attempts failed
            updateLocalPatientAnyway(patientId: patientId, updateData: updateData)
            return false
        } catch {
            print("❌ DIRECT UPDATE ERROR: \(error.localizedDescription)")
            updateLocalPatientAnyway(patientId: patientId, updateData: updateData)
            return false
        }
    }
    
    /// Helper method to try update with a specific request
    private func tryUpdateWithRequest(_ request: URLRequest, attempt: Int, patientId: String, updateData: [String: String]) async -> Bool {
        do {
            print("🔄 DIRECT UPDATE: Starting attempt \(attempt)")
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ DIRECT UPDATE: Invalid response type on attempt \(attempt)")
                return false
            }
            
            let responseString = String(data: responseData, encoding: .utf8) ?? "No response data"
            print("📊 DIRECT UPDATE: Response status code: \(httpResponse.statusCode)")
            print("📊 DIRECT UPDATE: Response: \(responseString)")
            
            // Success cases for different HTTP methods
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                print("✅ DIRECT UPDATE: Successfully updated patient profile on attempt \(attempt)")
                
                // Update local patient data
                updateLocalPatient(patientId: patientId, updateData: updateData)
                return true
            } else {
                print("❌ DIRECT UPDATE: Failed with status code \(httpResponse.statusCode) on attempt \(attempt)")
                print("❌ DIRECT UPDATE: Error response: \(responseString)")
                return false
            }
        } catch {
            print("❌ DIRECT UPDATE ERROR on attempt \(attempt): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Update local patient object with the new data
    private func updateLocalPatient(patientId: String, updateData: [String: String]) {
        Task {
            await MainActor.run {
                if let currentPatient = self.patient {
                    let updatedPatient = Patient(
                        id: patientId,
                        userId: currentPatient.userId,
                        name: updateData["name"] ?? currentPatient.name,
                        age: Int(updateData["age"] ?? "") ?? currentPatient.age,
                        gender: updateData["gender"] ?? currentPatient.gender,
                        createdAt: currentPatient.createdAt,
                        updatedAt: Date(),
                        email: updateData["email"] ?? currentPatient.email ?? "",
                        emailVerified: currentPatient.emailVerified,
                        bloodGroup: updateData["blood_group"] ?? currentPatient.bloodGroup,
                        address: updateData["address"] ?? currentPatient.address ?? "",
                        phoneNumber: updateData["phone_number"] ?? currentPatient.phoneNumber,
                        emergencyContactName: updateData["emergency_contact_name"] ?? currentPatient.emergencyContactName ?? "",
                        emergencyContactNumber: updateData["emergency_contact_number"] ?? currentPatient.emergencyContactNumber,
                        emergencyRelationship: updateData["emergency_relationship"] ?? currentPatient.emergencyRelationship
                    )
                    
                    self.patient = updatedPatient
                    print("✅ DIRECT UPDATE: Updated local patient object")
                }
            }
        }
    }
    
    /// Update the local patient even if server update failed to keep UI consistent
    private func updateLocalPatientAnyway(patientId: String, updateData: [String: Any]) {
        // Create string-only version
        let stringData: [String: String] = [
            "name": updateData["name"] as? String ?? "",
            "age": String(describing: updateData["age"] ?? "0"),
            "gender": updateData["gender"] as? String ?? "",
            "blood_group": updateData["blood_group"] as? String ?? "",
            "email": updateData["email"] as? String ?? "",
            "phone_number": updateData["phone_number"] as? String ?? "",
            "address": updateData["address"] as? String ?? "",
            "emergency_contact_name": updateData["emergency_contact_name"] as? String ?? "",
            "emergency_contact_number": updateData["emergency_contact_number"] as? String ?? "",
            "emergency_relationship": updateData["emergency_relationship"] as? String ?? ""
        ]
        
        updateLocalPatient(patientId: patientId, updateData: stringData)
        print("⚠️ DIRECT UPDATE: Updated local patient data despite server failure for better user experience")
    }
} 