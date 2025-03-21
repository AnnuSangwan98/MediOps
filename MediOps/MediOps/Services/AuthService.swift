import Foundation

// First, define the auth response type
struct AuthResponse: Codable {
    let user: User
    let token: String
}

class AuthService {
    static let shared = AuthService()
        
    private init() {}
    
    // MARK: - Patient Authentication
    func signUpPatient(email: String, password: String, name: String, age: Int, gender: String) async throws -> (MediOpsPatient, String) {
        let authResponse = AuthResponse(
            user: User(
                id: UUID(),
                email: email,
                role: .patient,
                username: name,
                createdAt: Date(),
                updatedAt: Date()
            ),
            token: "mock_token"
        )
        
        let patient = MediOpsPatient(
            id: authResponse.user.id.uuidString,
            userId: authResponse.user.id.uuidString,
            name: name,
            age: age,
            gender: gender,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return (patient, authResponse.token)
    }
    
    // MARK: - Hospital Admin Management
    func createHospitalAdmin(email: String, name: String, hospitalName: String) async throws -> (HospitalAdmin, String) {
        let authResponse = AuthResponse(
            user: User(
                id: UUID(),
                email: email,
                role: .hospitalAdmin,
                username: name,
                createdAt: Date(),
                updatedAt: Date()
            ),
            token: "mock_token"
        )
        
        let admin = HospitalAdmin(
            id: UUID(),
            userId: authResponse.user.id,
            name: name,
            hospitalName: hospitalName,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return (admin, authResponse.token)
    }
    
    // MARK: - Doctor Management
    func createDoctor(email: String, name: String, specialization: String, hospitalAdminId: UUID) async throws -> (Doctor, String) {
        let authResponse = AuthResponse(
            user: User(
                id: UUID(),
                email: email,
                role: .doctor,
                username: name,
                createdAt: Date(),
                updatedAt: Date()
            ),
            token: "mock_token"
        )
        
        let doctor = Doctor(
            id: UUID(),
            userId: authResponse.user.id,
            name: name,
            specialization: specialization,
            hospitalAdminId: hospitalAdminId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return (doctor, authResponse.token)
    }
    
    // MARK: - Lab Admin Management
    func createLabAdmin(email: String, name: String, labName: String, hospitalAdminId: UUID) async throws -> (LabAdmin, String) {
        let authResponse = AuthResponse(
            user: User(
                id: UUID(),
                email: email,
                role: .labAdmin,
                username: name,
                createdAt: Date(),
                updatedAt: Date()
            ),
            token: "mock_token"
        )
        
        let labAdmin = LabAdmin(
            id: UUID(),
            userId: authResponse.user.id,
            name: name,
            labName: labName,
            hospitalAdminId: hospitalAdminId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return (labAdmin, authResponse.token)
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