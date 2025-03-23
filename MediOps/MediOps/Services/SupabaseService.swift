import Foundation
import Supabase
import CommonCrypto

// MARK: - SupabaseController
/// Core controller for Supabase operations
class SupabaseController {
    static let shared = SupabaseController()
    
    private let supabaseURL = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co")!
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk"
    
    private let client: SupabaseClient
    private let session: URLSession
    
    private init() {
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Core Database Methods
    
    /// Generic method to insert data into a table
    func insert<T: Encodable>(into table: String, data: T) async throws {
        try await client.database
            .from(table)
            .insert(data)
            .execute()
    }
    
    /// Attempt to rollback a previously inserted record if a subsequent operation fails
    /// This creates a manual transaction-like functionality since Supabase JS client doesn't support transactions directly
    func deleteRollback(from table: String, where column: String, equals value: String) async {
        do {
            try await client.database
                .from(table)
                .delete()
                .eq(column, value: value)
                .execute()
            print("ROLLBACK: Successfully removed record from \(table) where \(column) = \(value)")
        } catch {
            print("ROLLBACK: Failed to remove record from \(table): \(error.localizedDescription)")
        }
    }
    
    /// Generic method to retrieve data from a table
    func select(from table: String, columns: String = "*") async throws -> [[String: Any]] {
        let response = try await client.database
            .from(table)
            .select(columns)
            .execute()
        
        guard let data = response.data as? [[String: Any]] else {
            return []
        }
        
        return data
    }
    
    /// Generic method to retrieve data with a filter
    func select(from table: String, columns: String = "*", where column: String, equals value: String) async throws -> [[String: Any]] {
        let response = try await client.database
            .from(table)
            .select(columns)
            .eq(column, value: value)
            .execute()
        
        guard let data = response.data as? [[String: Any]] else {
            return []
        }
        
        return data
    }
    
    /// Generic method to update data in a table
    func update<T: Encodable>(table: String, data: T, where column: String, equals value: String) async throws {
        try await client.database
            .from(table)
            .update(data)
            .eq(column, value: value)
            .execute()
    }
    
    /// Generic method to delete data from a table
    func delete(from table: String, where column: String, equals value: String) async throws {
        try await client.database
            .from(table)
            .delete()
            .eq(column, value: value)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    /// Hash a password using SHA256
    func hashPassword(_ password: String) -> String {
        // Returning plain text password instead of hashing for development purposes
        // WARNING: This is insecure and should not be used in production
        return password
    }
    
    /// Generate a JWT token (simplified for now)
    func generateToken(userId: String) -> String {
        // In a real app, you'd use a proper JWT library
        return "token_\(userId)_\(Int(Date().timeIntervalSince1970))"
    }
}

// Simple SHA256 implementation
private enum SHA256 {
    static func hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

