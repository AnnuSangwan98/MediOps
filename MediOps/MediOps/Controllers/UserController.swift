import Foundation

class UserController {
    static let shared = UserController()
    
    private let supabase = SupabaseController.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Login user with email and password
    func login(email: String, password: String) async throws -> AuthResponse {
        // Normalize email for case-insensitive matching
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("LOGIN: Attempting to login with normalized email: \(normalizedEmail)")
        
        // Download all users directly for more reliable matching
        let allUsers = try await supabase.select(from: "users")
        print("LOGIN: Downloaded \(allUsers.count) users from database")
        
        // Download all patients for potential direct password check
        let allPatients = try await supabase.select(from: "patients")
        print("LOGIN: Downloaded \(allPatients.count) patients from database")
        
        // Debug: Print all emails to verify
        print("LOGIN: Available emails in users table:")
        var matchedUser: [String: Any]? = nil
        var matchedPatient: [String: Any]? = nil
        
        // First try to find the user in the users table
        for user in allUsers {
            if let userEmail = user["email"] as? String {
                print("  - \(userEmail)")
                
                // Case-insensitive matching
                if userEmail.lowercased() == normalizedEmail {
                    matchedUser = user
                    print("LOGIN: ✓ Found matching user: \(userEmail)")
                    break
                }
            }
        }
        
        // If no user found in users table, or we need to check patient data
        // Look for the patient record as well
        for patient in allPatients {
            if let patientEmail = patient["email"] as? String,
               patientEmail.lowercased() == normalizedEmail {
                print("LOGIN: ✓ Found matching patient: \(patientEmail)")
                matchedPatient = patient
                
                // If we don't already have a matched user, try to find the corresponding user
                if matchedUser == nil, let userId = patient["user_id"] as? String {
                    // Look up the corresponding user
                    for user in allUsers {
                        if let id = user["id"] as? String, id == userId {
                            matchedUser = user
                            print("LOGIN: ✓ Found linked user with ID: \(id)")
                            break
                        }
                    }
                }
                break
            }
        }
        
        // If we still don't have a matched user, throw an error
        guard let user = matchedUser else {
            print("LOGIN: No matching user found for email: \(normalizedEmail)")
            throw AuthError.userNotFound
        }
        
        // Check if this is a patient login
        let isPatientLogin = matchedPatient != nil
        
        // 2. Verify password - check both user record and patient record if available
        var passwordIsValid = false
        
        // Check password in the users table
        if let storedPasswordHash = user["password_hash"] as? String {
            let hashedInputPassword = supabase.hashPassword(password)
            
            if storedPasswordHash == hashedInputPassword {
                passwordIsValid = true
                print("LOGIN: Password verified in users table")
            }
        }
        
        // If password didn't match in users table, check patient table if this is a patient login
        if !passwordIsValid && isPatientLogin {
            // Check if the patient record has a direct password (from the schema)
            if let patientPassword = matchedPatient?["password"] as? String {
                // For direct password comparison (non-hashed in the patients table)
                if patientPassword == password {
                    passwordIsValid = true
                    print("LOGIN: Password verified in patients table")
                } else {
                    // Try hashed comparison with patient table password
                    let hashedInputPassword = supabase.hashPassword(password)
                    if patientPassword == hashedInputPassword {
                        passwordIsValid = true
                        print("LOGIN: Hashed password verified in patients table")
                    }
                }
            }
        }
        
        // If password is still not valid, throw error
        if !passwordIsValid {
            print("LOGIN: Password mismatch for user")
            throw AuthError.invalidCredentials
        }
        
        // 3. Parse user data
        guard 
            let id = user["id"] as? String,
            let email = user["email"] as? String,
            let roleString = user["role"] as? String,
            let username = user["username"] as? String,
            let createdAtString = user["created_at"] as? String,
            let updatedAtString = user["updated_at"] as? String,
            let role = UserRole(rawValue: roleString)
        else {
            print("LOGIN: Invalid user data format")
            throw AuthError.invalidUserData
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        // 4. Create token and return auth response
        let token = supabase.generateToken(userId: id)
        userDefaults.set(token, forKey: "auth_token")
        userDefaults.set(id, forKey: "current_user_id")
        
        let userObject = User(
            id: id,
            email: email,
            role: role,
            username: username,
            createdAt: createdAt,
            updatedAt: updatedAt,
            passwordHash: nil // Don't expose password hash to client
        )
        
        print("LOGIN: Successfully authenticated user: \(email), role: \(role.rawValue)")
        return AuthResponse(user: userObject, token: token)
    }
    
    /// Register a new user
    func register(email: String, password: String, username: String, role: UserRole) async throws -> AuthResponse {
        // Normalize email to prevent case sensitivity issues
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("USER REGISTER: Attempting to register \(normalizedEmail)")
        
        // 1. Check if user already exists - case insensitive check
        let allUsers = try await supabase.select(from: "users")
        
        // Extra safety: loop through all users to check for case-insensitive email match
        for existingUser in allUsers {
            if let existingEmail = existingUser["email"] as? String,
               existingEmail.lowercased() == normalizedEmail {
                print("USER REGISTER: User with email \(normalizedEmail) already exists (case-insensitive match with \(existingEmail))")
                throw AuthError.emailAlreadyExists
            }
        }
        
        // 2. Create user
        let id = UUID().uuidString
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: now)
        let passwordHash = supabase.hashPassword(password)
        
        // Create a dictionary for insertion rather than using Any types
        let userData: [String: String] = [
            "id": id,
            "email": normalizedEmail, // Use normalized email for storage
            "role": role.rawValue,
            "username": username,
            "password_hash": passwordHash,
            "created_at": createdAt,
            "updated_at": createdAt
        ]
        
        print("USER REGISTER: Creating new user with ID: \(id)")
        try await supabase.insert(into: "users", data: userData)
        
        // 3. Create token and auth response
        let token = supabase.generateToken(userId: id)
        userDefaults.set(token, forKey: "auth_token")
        userDefaults.set(id, forKey: "current_user_id")
        
        print("USER REGISTER: Successfully registered new user")
        
        let userObject = User(
            id: id,
            email: normalizedEmail,
            role: role,
            username: username,
            createdAt: now,
            updatedAt: now,
            passwordHash: nil // Don't expose password hash to client
        )
        
        return AuthResponse(user: userObject, token: token)
    }
    
    /// Logout current user
    func logout() {
        userDefaults.removeObject(forKey: "auth_token")
        userDefaults.removeObject(forKey: "current_user_id")
    }
    
    /// Get current user data
    func getCurrentUser() async throws -> User? {
        guard let userId = userDefaults.string(forKey: "current_user_id") else {
            print("GET CURRENT USER: No user ID found in UserDefaults")
            return nil
        }
        
        print("GET CURRENT USER: Fetching user with ID: \(userId)")
        let users = try await supabase.select(
            from: "users",
            where: "id",
            equals: userId
        )
        
        guard let user = users.first else {
            print("GET CURRENT USER: No user found with ID: \(userId)")
            return nil
        }
        
        print("GET CURRENT USER: Raw user data: \(user)")
        
        guard 
            let id = user["id"] as? String,
            let email = user["email"] as? String,
            let roleString = user["role"] as? String,
            let username = user["username"] as? String,
            let createdAtString = user["created_at"] as? String,
            let updatedAtString = user["updated_at"] as? String
        else {
            print("GET CURRENT USER: Missing required fields in user data")
            return nil
        }
        
        // Use the custom initializer to handle various role string formats
        guard let role = UserRole(rawValue: roleString) else {
            print("GET CURRENT USER: Invalid role string: \(roleString)")
            // Fallback to patient if role can't be parsed
            let fallbackRole = UserRole.patient
            print("GET CURRENT USER: Using fallback role: \(fallbackRole.rawValue)")
            
            // If we can identify a hospital admin from email, override the fallback
            if let hospitalAdmins = try? await supabase.select(
                from: "hospital_admins",
                where: "email",
                equals: email
            ), !hospitalAdmins.isEmpty {
                print("GET CURRENT USER: Found matching hospital admin record, using hospitalAdmin role")
                return createUserWithRole(id: id, email: email, username: username, 
                                        createdAtString: createdAtString, 
                                        updatedAtString: updatedAtString, 
                                        role: .hospitalAdmin)
            }
            
            return createUserWithRole(id: id, email: email, username: username, 
                                    createdAtString: createdAtString, 
                                    updatedAtString: updatedAtString, 
                                    role: fallbackRole)
        }
        
        print("GET CURRENT USER: Successfully parsed role: \(role.rawValue)")
        return createUserWithRole(id: id, email: email, username: username, 
                                createdAtString: createdAtString, 
                                updatedAtString: updatedAtString, 
                                role: role)
    }
    
    // Helper method to create user with proper date parsing
    private func createUserWithRole(id: String, email: String, username: String, 
                                  createdAtString: String, updatedAtString: String, 
                                  role: UserRole) -> User {
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        
        return User(
            id: id,
            email: email,
            role: role,
            username: username,
            createdAt: createdAt,
            updatedAt: updatedAt,
            passwordHash: nil
        )
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return userDefaults.string(forKey: "auth_token") != nil
    }
    
    /// Debug function to check if user exists
    func checkUserExists(email: String) async throws -> Bool {
        let lowercaseEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: Checking if user exists with email: \(lowercaseEmail)")
        
        let users = try await supabase.select(
            from: "users",
            where: "email",
            equals: lowercaseEmail
        )
        
        let exists = !users.isEmpty
        print("DEBUG: User exists: \(exists)")
        
        if exists, let user = users.first {
            print("DEBUG: Found user ID: \(user["id"] as? String ?? "unknown")")
            print("DEBUG: User data: \(user)")
        }
        
        return exists
    }
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError, Equatable {
    case userNotFound
    case invalidCredentials
    case invalidUserData
    case emailAlreadyExists
    case unauthorized
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidUserData:
            return "Invalid user data"
        case .emailAlreadyExists:
            return "Email already exists"
        case .unauthorized:
            return "Not authorized"
        case .networkError:
            return "Network error. Please check your connection"
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.userNotFound, .userNotFound),
             (.invalidCredentials, .invalidCredentials),
             (.invalidUserData, .invalidUserData),
             (.emailAlreadyExists, .emailAlreadyExists),
             (.unauthorized, .unauthorized),
             (.networkError, .networkError):
            return true
        default:
            return false
        }
    }
} 