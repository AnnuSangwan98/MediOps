import Foundation

class UserController {
    static let shared = UserController()
    
    private let supabase = SupabaseController.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Login user with email and password
    func login(email: String, password: String) async throws -> AuthResponse {
        // 1. Get user from users table
        let lowercaseEmail = email.lowercased()
        print("Attempting to login with email: \(lowercaseEmail)")
        
        let users = try await supabase.select(
            from: "users",
            where: "email",
            equals: lowercaseEmail
        )
        
        guard let user = users.first else {
            print("User not found for email: \(lowercaseEmail)")
            throw AuthError.userNotFound
        }
        
        print("User found: \(user["id"] as? String ?? "unknown ID")")
        
        // 2. Verify password
        guard let storedPasswordHash = user["password_hash"] as? String else {
            print("Password hash not found for user")
            throw AuthError.invalidCredentials
        }
        
        let hashedInputPassword = supabase.hashPassword(password)
        
        if storedPasswordHash != hashedInputPassword {
            print("Password mismatch for user")
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
            return nil
        }
        
        let users = try await supabase.select(
            from: "users",
            where: "id",
            equals: userId
        )
        
        guard let user = users.first else {
            return nil
        }
        
        guard 
            let id = user["id"] as? String,
            let email = user["email"] as? String,
            let roleString = user["role"] as? String,
            let username = user["username"] as? String,
            let createdAtString = user["created_at"] as? String,
            let updatedAtString = user["updated_at"] as? String,
            let role = UserRole(rawValue: roleString)
        else {
            return nil
        }
        
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