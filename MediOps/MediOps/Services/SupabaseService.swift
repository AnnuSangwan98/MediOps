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
    
    public let supabaseURL = URL(string: "https://cwahmqodmutorxkoxtyz.supabase.co")!
    public let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YWhtcW9kbXV0b3J4a294dHl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI1MzA5MjEsImV4cCI6MjA1ODEwNjkyMX0.06VZB95gPWVIySV2dk8dFCZAXjwrFis1v7wIfGj3hmk"
    
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
    
    /// Generic method to retrieve data with a filter
    func select(from table: String, columns: String = "*", where column: String, equals value: String) async throws -> [[String: Any]] {
        print("🔍 SUPABASE: Selecting from \(table) where \(column) = \(value)")
        
        // Use direct URL session with headers
        let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
        let urlString = "\(supabaseURL)/rest/v1/\(table)?select=\(columns)&\(column)=eq.\(escapedValue)"
        print("🌐 SUPABASE URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ SUPABASE ERROR: Invalid URL: \(urlString)")
            throw NSError(domain: "SupabaseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        // Print request headers for debugging
        print("📋 SUPABASE REQUEST HEADERS:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        
        do {
            print("🔄 SUPABASE: Starting request to \(table) at \(Date().formatted(date: .numeric, time: .standard))")
            print("🔍 SUPABASE QUERY: SELECT \(columns) FROM \(table) WHERE \(column) = '\(value)'")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ SUPABASE ERROR: Invalid response type")
                return []
            }
            
            print("📊 SUPABASE: Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ SUPABASE ERROR: \(responseString)")
                }
                return []
            }
            
            // Log raw response data for debugging
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("📋 SUPABASE RAW DATA (\(table), \(data.count) bytes):")
                print(rawJSON.prefix(500)) // Show first 500 chars to avoid huge logs
                if rawJSON.count > 500 {
                    print("... (truncated)")
                }
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("❌ SUPABASE ERROR: Failed to parse JSON data")
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("❌ SUPABASE ERROR: Raw JSON: \(jsonStr)")
                }
                return []
            }
            
            print("✅ SUPABASE: Successfully retrieved \(jsonArray.count) records from \(table)")
            
            // Extra logging for table key information if records exist
            if !jsonArray.isEmpty && jsonArray.count <= 5 { // Limit detailed logging to small result sets
                print("🔑 SUPABASE: Sample data keys:")
                for (index, item) in jsonArray.enumerated() {
                    print("  Record #\(index + 1) keys: \(item.keys.joined(separator: ", "))")
                }
            }
            
            // Special case for important tables
            if table == "patients" && column == "user_id" {
                print("👤 PATIENT DATA CHECK:")
                for (index, patient) in jsonArray.enumerated() {
                    print("  Patient #\(index + 1):")
                    print("    ID: \(patient["id"] ?? "nil")")
                    print("    User ID: \(patient["user_id"] ?? "nil")")
                    print("    Name: \(patient["name"] ?? "nil")")
                }
            }
            
            return jsonArray
        } catch {
            print("❌ SUPABASE ERROR: Failed to fetch data from \(table): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update a record by ID
    func update(table: String, id: String, data: [String: Any]) async throws {
        print("🔄 SUPABASE: Updating record with ID \(id) in \(table)")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/\(table)?id=eq.\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        // Serialize the data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpBody = jsonData
            
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ SUPABASE ERROR: Invalid response type")
                throw NSError(domain: "SupabaseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            print("📊 SUPABASE: Update response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 204 && httpResponse.statusCode != 200 {
                print("❌ SUPABASE ERROR: Failed to update record with status code \(httpResponse.statusCode)")
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Update failed with status code \(httpResponse.statusCode)"])
            }
            
            print("✅ SUPABASE: Successfully updated record with ID \(id) in \(table)")
        } catch {
            print("❌ SUPABASE ERROR: Failed to update record in \(table): \(error.localizedDescription)")
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
    
    /// Diagnostic method to check if appointments table is accessible and has data
    func checkAppointmentsTable() async -> Bool {
        print("🩺 DIAGNOSTIC: Checking appointments table accessibility")
        do {
            let results = try await select(from: "appointments", columns: "count(*)", where: "id", equals: "dummy_value")
            print("✅ DIAGNOSTIC: Successfully connected to appointments table")
            
            // Try to get total count from appointments table
            let allResults = try await select(from: "appointments", columns: "count(*)")
            if let firstResult = allResults.first, let count = firstResult["count"] as? Int {
                print("📊 DIAGNOSTIC: Total appointments in database: \(count)")
            } else {
                print("⚠️ DIAGNOSTIC: Could not get appointments count")
            }
            
            // Try to get a sample appointment
            let sampleResults = try await select(from: "appointments")
            if let firstAppointment = sampleResults.first {
                print("📋 DIAGNOSTIC: Sample appointment data found: \(firstAppointment["id"] ?? "unknown")")
                if let patientId = firstAppointment["patient_id"] as? String {
                    print("👤 DIAGNOSTIC: Sample patient_id: \(patientId)")
                }
            } else {
                print("⚠️ DIAGNOSTIC: No sample appointment found")
            }
            
            return true
        } catch {
            print("❌ DIAGNOSTIC: Failed to access appointments table: \(error.localizedDescription)")
            return false
        }
    }
    
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
    
    /// Direct method to insert an appointment with proper formatting according to the database schema
    func insertAppointment(id: String, patientId: String, doctorId: String, hospitalId: String, 
                          slotId: Int, date: Date, reason: String) async throws {
        print("🔄 DIRECT APPOINTMENT INSERT: Creating appointment with ID: \(id)")
        
        // Format date for database
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)
        
        // Create appointment data conforming to the table schema
        let appointmentData: [String: Any] = [
            "id": id,
            "patient_id": patientId,
            "doctor_id": doctorId,
            "hospital_id": hospitalId,
            "availability_slot_id": slotId,
            "appointment_date": formattedDate,
            "status": "upcoming",
            "reason": reason
        ]
        
        let url = URL(string: "\(supabaseURL)/rest/v1/appointments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let jsonData = try JSONSerialization.data(withJSONObject: appointmentData)
        request.httpBody = jsonData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📊 Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            if let errorStr = String(data: responseData, encoding: .utf8) {
                print("❌ Error details: \(errorStr)")
                throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create appointment: \(errorStr)"])
            } else {
                throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create appointment"])
            }
        }
        
        if let responseStr = String(data: responseData, encoding: .utf8) {
            print("✅ Appointment created successfully: \(responseStr)")
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

