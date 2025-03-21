import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()
    private let supabase = SupabaseClient(supabaseURL: URL(string: SupabaseConfig.projectURL)!, supabaseKey: SupabaseConfig.anonKey)
    
    private init() {}
    
    // MARK: - Patient Authentication
    func signUpPatient(email: String, password: String, name: String, age: Int, gender: String) async throws -> User {
        // Create auth user
        let authResponse = try await supabase.auth.signUp(email: email, password: password)
        guard let userId = authResponse.user.id else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
        }
        
        // Create user record with role
        let formattedId = generateFormattedUserId(role: .patient)
        let user = User(id: formattedId, email: email, role: .patient, username: nil, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("users").insert(user).execute()
        
        // Create patient record
        let patient = Patient(id: UUID().uuidString, userId: userId, name: name, age: age, gender: gender, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("patients").insert(patient).execute()
        
        return user
    }
    
    // MARK: - Hospital Admin Management
    func createHospitalAdmin(email: String, name: String, hospitalName: String) async throws -> (User, String) {
        let password = generateSecurePassword()
        let username = generateUsername(from: name)
        
        // Create auth user
        let authResponse = try await supabase.auth.admin.createUser(.init(email: email, password: password, emailConfirm: true))
        guard let userId = authResponse.user.id else {
            throw NSError(domain: "AuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create hospital admin"])
        }
        
        // Create user record with role
        let formattedId = generateFormattedUserId(role: .hospitalAdmin)
        let user = User(id: formattedId, email: email, role: .hospitalAdmin, username: username, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("users").insert(user).execute()
        
        // Create hospital admin record
        let hospitalAdmin = HospitalAdmin(id: UUID().uuidString, userId: userId, name: name, hospitalName: hospitalName, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("hospital_admins").insert(hospitalAdmin).execute()
        
        // Send credentials via email
        try await sendCredentialsEmail(to: email, username: username, password: password, role: .hospitalAdmin)
        
        return (user, password)
    }
    
    // MARK: - Doctor Management
    func createDoctor(email: String, name: String, specialization: String, hospitalAdminId: String) async throws -> (User, String) {
        let password = generateSecurePassword()
        let username = generateUsername(from: name)
        
        // Create auth user
        let authResponse = try await supabase.auth.admin.createUser(.init(email: email, password: password, emailConfirm: true))
        guard let userId = authResponse.user.id else {
            throw NSError(domain: "AuthError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create doctor"])
        }
        
        // Create user record with role
        let formattedId = generateFormattedUserId(role: .doctor)
        let user = User(id: formattedId, email: email, role: .doctor, username: username, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("users").insert(user).execute()
        
        // Create doctor record
        let doctor = Doctor(id: UUID().uuidString, userId: userId, name: name, specialization: specialization, hospitalAdminId: hospitalAdminId, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("doctors").insert(doctor).execute()
        
        // Send credentials via email
        try await sendCredentialsEmail(to: email, username: username, password: password, role: .doctor)
        
        return (user, password)
    }
    
    // MARK: - Lab Admin Management
    func createLabAdmin(email: String, name: String, labName: String, hospitalAdminId: String) async throws -> (User, String) {
        let password = generateSecurePassword()
        let username = generateUsername(from: name)
        
        // Create auth user
        let authResponse = try await supabase.auth.admin.createUser(.init(email: email, password: password, emailConfirm: true))
        guard let userId = authResponse.user.id else {
            throw NSError(domain: "AuthError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create lab admin"])
        }
        
        // Create user record with role
        let formattedId = generateFormattedUserId(role: .labAdmin)
        let user = User(id: formattedId, email: email, role: .labAdmin, username: username, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("users").insert(user).execute()
        
        // Create lab admin record
        let labAdmin = LabAdmin(id: UUID().uuidString, userId: userId, name: name, labName: labName, hospitalAdminId: hospitalAdminId, createdAt: Date(), updatedAt: Date())
        try await supabase.database.from("lab_admins").insert(labAdmin).execute()
        
        // Send credentials via email
        try await sendCredentialsEmail(to: email, username: username, password: password, role: .labAdmin)
        
        return (user, password)
    }
    
    // MARK: - Helper Methods
    private func generateFormattedUserId(role: UserRole) -> String {
        switch role {
        case .superAdmin:
            return "SUPERMAIN"
        case .hospitalAdmin:
            return "HOS" + String(format: "%03d", getNextSequence(for: "hospital_admin"))
        case .doctor:
            return "DOCT" + String(format: "%04d", getNextSequence(for: "doctor"))
        case .labAdmin:
            return "LABT" + String(format: "%03d", getNextSequence(for: "lab_admin"))
        case .patient:
            return "PAT" + String(format: "%05d", getNextSequence(for: "patient"))
        }
    }
    
    private func getNextSequence(for role: String) -> Int {
        // TODO: Implement sequence management in database
        // For now, using a simple random number for demonstration
        switch role {
        case "hospital_admin": return Int.random(in: 1...999)
        case "doctor": return Int.random(in: 1...9999)
        case "lab_admin": return Int.random(in: 1...999)
        case "patient": return Int.random(in: 1...99999)
        default: return 1
        }
    }
    
    internal func generateSecurePassword() -> String {
        let length = 12
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    internal func generateUsername(from name: String) -> String {
        let cleanName = name.lowercased().components(separatedBy: .whitespaces).joined()
        let randomSuffix = String(Int.random(in: 1000...9999))
        return "\(cleanName)\(randomSuffix)"
    }
    
    private func sendCredentialsEmail(to email: String, username: String, password: String, role: UserRole) async throws {
        // Implement email sending logic using your email service
        // This is a placeholder for the actual email sending implementation
        print("Credentials sent to \(email) - Username: \(username), Password: \(password), Role: \(role.rawValue)")
    }
}