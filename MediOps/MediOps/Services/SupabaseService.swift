import Foundation
import Supabase
import CommonCrypto

// MARK: - SupabaseError
enum SupabaseError: Error {
    case invalidResponse
    case requestFailed(String)
    case decodingFailed
    case invalidData(String)
    case networkError(String)
    case tableNotFound(String)
    case unauthorized
    case custom(String)
}

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
        
        print("SUPABASE: Initialized with URL \(supabaseURL)")
    }
    
    // MARK: - Core Database Methods
    
    /// Generic method to insert data into a table
    func insert<T: Encodable>(into table: String, data: T) async throws {
        print("SUPABASE: Inserting data into \(table)")
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
        print("SUPABASE: Selecting all data from \(table)")
        
        // Use direct URL session with headers if the client approach isn't working
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?select=\(columns)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("SUPABASE ERROR: Invalid response type")
                return []
            }
            
            print("SUPABASE: Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: \(responseString)")
                }
                return []
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("SUPABASE ERROR: Failed to parse JSON data")
                return []
            }
            
            print("SUPABASE: Successfully retrieved \(jsonArray.count) records from \(table)")
            return jsonArray
        } catch {
            print("SUPABASE ERROR: Failed to fetch data from \(table): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetch hospital data from Supabase
    func fetchHospitals() async throws -> [Hospital] {
        print("SUPABASE: Fetching all hospitals")
        
        do {
            let jsonArray = try await select(from: "hospitals")
            
            // Parse the JSON array into Hospital objects
            var hospitals: [Hospital] = []
            
            for json in jsonArray {
                // Extract all required fields from the JSON
                guard let id = json["id"] as? String,
                      let name = json["hospital_name"] as? String,
                      let email = json["email"] as? String,
                      let contactNumber = json["contact_number"] as? String,
                      let emergencyContact = json["emergency_contact_number"] as? String,
                      let licenseNumber = json["licence"] as? String,
                      let hospitalAddress = json["hospital_address"] as? String,
                      let state = json["hospital_state"] as? String,
                      let city = json["hospital_city"] as? String,
                      let pincode = json["area_pincode"] as? String,
                      let statusString = json["status"] as? String else {
                    print("SUPABASE: Missing required fields in hospital data")
                    continue
                }
                
                // Convert status string to HospitalStatus enum
                let status: HospitalStatus
                switch statusString.lowercased() {
                case "active":
                    status = .active
                case "pending":
                    status = .pending
                case "inactive":
                    status = .inactive
                default:
                    status = .pending
                }
                
                // Convert profile image if available
                var imageData: Data? = nil
                if let imageBase64 = json["hospital_profile_image"] as? String, !imageBase64.isEmpty {
                    imageData = Data(base64Encoded: imageBase64)
                }
                
                // Fetch admin data for this hospital
                var adminName = "Admin"
                var adminPhone = contactNumber
                var adminEmail = email
                
                // Try to get admin data
                if let adminData = try? await fetchHospitalAdmin(hospitalId: id) {
                    if let name = adminData["admin_name"] as? String {
                        adminName = name
                    }
                    if let phone = adminData["contact_number"] as? String {
                        adminPhone = phone
                    }
                    if let mail = adminData["email"] as? String {
                        adminEmail = mail
                    }
                }
                
                // Create hospital object with extracted data
                let hospital = Hospital(
                    id: id,
                    name: name,
                    adminName: adminName,
                    licenseNumber: licenseNumber,
                    hospitalPhone: emergencyContact,
                    street: hospitalAddress,
                    city: city,
                    state: state,
                    zipCode: pincode,
                    phone: adminPhone,
                    email: adminEmail,
                    status: status,
                    registrationDate: Date(), // Default to current date if not available
                    lastModified: Date(),
                    lastModifiedBy: "System",
                    imageData: imageData
                )
                
                hospitals.append(hospital)
            }
            
            print("SUPABASE: Successfully parsed \(hospitals.count) hospitals")
            return hospitals
        } catch {
            print("SUPABASE ERROR: Failed to fetch hospitals: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Generic method to retrieve data with a filter
    func select(from table: String, columns: String = "*", where column: String, equals value: String) async throws -> [[String: Any]] {
        print("SUPABASE: Selecting from \(table) where \(column) = \(value)")
        
        // Use direct URL session with headers
        let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?select=\(columns)&\(column)=eq.\(escapedValue)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("SUPABASE ERROR: Invalid response type")
                return []
            }
            
            print("SUPABASE: Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: \(responseString)")
                }
                return []
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("SUPABASE ERROR: Failed to parse JSON data")
                return []
            }
            
            print("SUPABASE: Successfully retrieved \(jsonArray.count) records from \(table)")
            return jsonArray
        } catch {
            print("SUPABASE ERROR: Failed to fetch data from \(table): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Generic method to update data in a table
    func update<T: Encodable>(table: String, data: T, where column: String, equals value: String) async throws {
        print("SUPABASE: Updating \(table) where \(column) = \(value)")
        try await client.database
            .from(table)
            .update(data)
            .eq(column, value: value)
            .execute()
    }
    
    /// Generic method to delete data from a table
    func delete(from table: String, where column: String, equals value: String) async throws {
        print("SUPABASE: Deleting from \(table) where \(column) = \(value)")
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
    
    /// Fetch hospital admin details by hospital_id
    func fetchHospitalAdmin(hospitalId: String) async throws -> [String: Any]? {
        print("SUPABASE: Fetching admin details for hospital \(hospitalId)")
        
        do {
            let admins = try await select(
                from: "hospital_admins",
                where: "hospital_id",
                equals: hospitalId
            )
            
            guard let admin = admins.first else {
                print("SUPABASE: No admin found for hospital \(hospitalId)")
                return nil
            }
            
            print("SUPABASE: Successfully retrieved admin details for hospital \(hospitalId)")
            return admin
        } catch {
            print("SUPABASE ERROR: Failed to fetch admin details: \(error.localizedDescription)")
            throw error
        }
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

// MARK: - Additional Methods
extension SupabaseController {
    // Insert non-Encodable dictionary values
    func insert(into table: String, values: [String: Any]) async throws {
        print("SUPABASE: Inserting values into \(table)")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: values)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if httpResponse.statusCode >= 400 {
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: Failed to insert - \(errorStr)")
                }
                throw SupabaseError.requestFailed("Failed to insert into \(table), status: \(httpResponse.statusCode)")
            }
            
            print("SUPABASE: Successfully inserted into \(table)")
        } catch {
            print("SUPABASE ERROR: Insert failed - \(error.localizedDescription)")
            throw error
        }
    }
    
    // Check if pat_reports table exists, create it if not
    func ensurePatReportsTableExists() async throws {
        do {
            // First check if the table exists by trying to select from it
            _ = try await self.select(from: "pat_reports", limit: 1)
            print("pat_reports table already exists.")
        } catch {
            print("Creating pat_reports table...")
            // The table doesn't exist or there was another error, let's create the table
            let createTableSQL = """
            CREATE TABLE IF NOT EXISTS pat_reports (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                patient_name TEXT NOT NULL,
                patient_id TEXT NOT NULL,
                summary TEXT,
                file_url TEXT NOT NULL,
                uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
            """
            
            // Execute the SQL through Supabase
            let url = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let parameters: [String: Any] = ["sql": createTableSQL]
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw SupabaseError.requestFailed("Failed to create pat_reports table")
            }
            
            print("Successfully created pat_reports table")
        }
    }
    
    // Insert a sample report for testing
    func insertSamplePatientReport() async throws {
        let sampleReport: [String: Any] = [
            "patient_name": "John Smith",
            "patient_id": "PAT12345",
            "summary": "Complete blood count and lipid profile results",
            "file_url": "https://example.com/reports/sample.pdf"
        ]
        
        try await insert(into: "pat_reports", values: sampleReport)
        print("Sample patient report inserted successfully")
    }
    
    // Select with limit parameter
    func select(from table: String, limit: Int) async throws -> [[String: Any]] {
        print("SUPABASE: Selecting \(limit) records from \(table)")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("SUPABASE ERROR: Invalid response type")
                return []
            }
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: \(responseString)")
                }
                return []
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("SUPABASE ERROR: Failed to parse JSON data")
                return []
            }
            
            print("SUPABASE: Successfully retrieved \(jsonArray.count) records from \(table)")
            return jsonArray
        } catch {
            print("SUPABASE ERROR: Failed to fetch data from \(table): \(error.localizedDescription)")
            throw error
        }
    }
}

