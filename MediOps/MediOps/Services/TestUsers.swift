import Foundation

class TestUsers {
    static let shared = TestUsers()
    private let authService = AuthService.shared
    
    private init() {}
    
    func createTestUsers() async throws {
        // Create Hospital Admin
        let (hospitalAdmin, _) = try await authService.createHospitalAdmin(
            email: "hospital.admin@mediops.test",
            name: "John Smith",
            hospitalName: "MediOps General Hospital"
        )
        
        // Create Doctor
        let (doctor, _) = try await authService.createDoctor(
            email: "doctor@mediops.test",
            name: "Dr. Sarah Johnson",
            specialization: "Cardiology",
            hospitalAdminId: hospitalAdmin.id
        )
        
        // Create Lab Admin
        let (labAdmin, _) = try await authService.createLabAdmin(
            email: "lab.admin@mediops.test",
            name: "Michael Brown",
            labName: "MediOps Central Lab",
            hospitalAdminId: hospitalAdmin.id
        )
        
        // Create Patient
        let _ = try await authService.signUpPatient(
            email: "patient@mediops.test",
            password: "Test@123",
            name: "Robert Wilson",
            age: 35,
            gender: "Male"
        )
        
        print("Test users created successfully:")
        print("Hospital Admin ID: \(hospitalAdmin.id)")
        print("Doctor ID: \(doctor.id)")
        print("Lab Admin ID: \(labAdmin.id)")
    }
}