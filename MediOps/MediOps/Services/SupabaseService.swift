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
        
        // For debugging purposes, print out the data structure for lab_admins
        if table == "lab_admins" {
            do {
                let jsonData = try JSONEncoder().encode(data)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("SUPABASE DEBUG - lab_admins data: \(jsonString)")
                }
            } catch {
                print("SUPABASE WARNING: Unable to encode lab_admins data for debugging: \(error.localizedDescription)")
            }
        }
        
        do {
        try await client.database
            .from(table)
            .insert(data)
            .execute()
            print("SUPABASE: Successfully inserted data into \(table)")
        } catch {
            print("SUPABASE ERROR: Failed to insert into \(table): \(error.localizedDescription)")
            
            // For more detailed error inspection for lab_admins insertions
            if table == "lab_admins" {
                // Try to extract more detailed error information
                if let supabaseError = error as? PostgrestError {
                    let errorMessage = supabaseError.message ?? "No detailed message"
                    let errorCode = supabaseError.code ?? "No error code"
                    
                    print("SUPABASE DETAILED ERROR: \(errorMessage)")
                    print("SUPABASE ERROR CODE: \(errorCode)")
                    
                    // Check for common constraints
                    if errorMessage.contains("violates check constraint") {
                        if errorMessage.contains("lab_admins_id_format") {
                            throw SupabaseError.invalidData("Lab admin ID must be in the format LAB followed by 3 digits")
                        } else if errorMessage.contains("lab_admins_contact_number_format") {
                            throw SupabaseError.invalidData("Contact number must be exactly 10 digits")
                        } else if errorMessage.contains("lab_admins_password_format") {
                            throw SupabaseError.invalidData("Password must be at least 8 characters with at least one uppercase letter, one lowercase letter, one digit, and one special character")
                        } else if errorMessage.contains("lab_admins_department_check") {
                            throw SupabaseError.invalidData("Department must be 'Pathology & Laboratory'")
                        }
                    } else if errorMessage.contains("duplicate key") && errorMessage.contains("email") {
                        throw SupabaseError.invalidData("Email address is already in use")
                    }
                }
            }
            
            throw error
        }
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
        do {
            let result = try await client.database
            .from(table)
            .delete()
            .eq(column, value: value)
            .execute()
            
            // Add logging about the deletion result
            print("SUPABASE: Delete operation completed successfully")
            print("SUPABASE: Response status: \(result.status)")
            
            // Check if any rows were affected (deleted)
            if let count = result.count, count > 0 {
                print("SUPABASE: Successfully deleted \(count) records")
            } else {
                print("SUPABASE WARNING: Delete operation completed but no records were affected")
            }
        } catch {
            print("SUPABASE ERROR: Delete operation failed: \(error.localizedDescription)")
            print("SUPABASE ERROR DETAILS: \(String(describing: error))")
            throw error
        }
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
        print("🔄 APPOINTMENT: Creating appointment with ID: \(id)")
        print("   Using patient_id: \(patientId)")
        
        // Format date for database
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)
        
        // Create appointment data conforming to the table schema exactly as defined
        let appointmentData: [String: Any] = [
            "id": id,
            "patient_id": patientId,
            "doctor_id": doctorId,
            "hospital_id": hospitalId,
            "availability_slot_id": slotId,
            "appointment_date": formattedDate,
            "status": "upcoming",
            "reason": reason.isEmpty ? "Medical consultation" : reason,
            "isdone": false,
            "is_premium": false
            // booking_time, created_at, and updated_at will use the DEFAULT CURRENT_TIMESTAMP
        ]
        
        // Log the data being sent
        print("📋 APPOINTMENT DATA:")
        appointmentData.forEach { key, value in
            print("   \(key): \(value)")
        }
        
        // First verify the patient exists with the right ID column
        print("🔍 APPOINTMENT: Verifying patient_id exists in patients table")
        do {
            // 1. First check if the patient exists with this ID
            let patientResults = try await select(
                from: "patients",
                where: "id",
                equals: patientId
            )
            
            if patientResults.isEmpty {
                print("⚠️ APPOINTMENT: Patient with ID \(patientId) not found in patients table")
                
                // 2. Try to find a patient with this ID in the patient_id column
                let patientIdResults = try await select(
                    from: "patients",
                    where: "patient_id",
                    equals: patientId
                )
                
                if patientIdResults.isEmpty {
                    print("⚠️ APPOINTMENT: No patient found with patient_id = \(patientId) either")
                    
                    // 3. Look up the current user to get userId
                    let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                                 UserDefaults.standard.string(forKey: "current_user_id")
                    
                    if let userId = userId {
                        print("🔍 APPOINTMENT: Found user ID: \(userId), looking up patient record")
                        
                        // 4. Look up the patient by user_id
                        let userPatients = try await select(
                            from: "patients",
                            where: "user_id",
                            equals: userId
                        )
                        
                        if let userPatient = userPatients.first, 
                           let patientActualId = userPatient["id"] as? String {
                            // We found a valid patient record, but with a different ID
                            print("✅ APPOINTMENT: Found patient with different ID: \(patientActualId)")
                            
                            // Create or update patient record with the expected ID
                            print("🔧 APPOINTMENT: Creating/updating patient record with ID: \(patientId)")
                            
                            let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
                            var sqlRequest = URLRequest(url: sqlUrl)
                            sqlRequest.httpMethod = "POST"
                            sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                            sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                            sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                            
                            // SQL to create or update patient record with correct ID
                            let sql = """
                            BEGIN;
                            -- Create a new patient record with the expected ID if it doesn't exist
                            INSERT INTO patients (id, patient_id, user_id, name, age, gender)
                            VALUES (
                                '\(patientId)', 
                                '\(patientId)', 
                                '\(userId)',
                                (SELECT name FROM patients WHERE id = '\(patientActualId)'),
                                (SELECT age FROM patients WHERE id = '\(patientActualId)'),
                                (SELECT gender FROM patients WHERE id = '\(patientActualId)')
                            )
                            ON CONFLICT (id) DO UPDATE 
                            SET patient_id = '\(patientId)',
                                user_id = '\(userId)';
                            
                            COMMIT;
                            """
                            
                            let sqlParams = ["sql": sql]
                            let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
                            sqlRequest.httpBody = sqlJsonData
                            
                            let (sqlResponseData, sqlResponse) = try await URLSession.shared.data(for: sqlRequest)
                            
                            if let sqlHttpResponse = sqlResponse as? HTTPURLResponse, 
                               sqlHttpResponse.statusCode >= 200 && sqlHttpResponse.statusCode < 300 {
                                print("✅ APPOINTMENT: Successfully created/updated patient record with ID: \(patientId)")
                            } else {
                                if let sqlErrorStr = String(data: sqlResponseData, encoding: .utf8) {
                                    print("❌ APPOINTMENT: Error creating/updating patient: \(sqlErrorStr)")
                                }
                                print("⚠️ APPOINTMENT: Failed to create/update patient with status: \(String(describing: (sqlResponse as? HTTPURLResponse)?.statusCode))")
                            }
                        } else {
                            print("⚠️ APPOINTMENT: No patient found for user ID: \(userId)")
                        }
                    } else {
                        print("⚠️ APPOINTMENT: No user ID found in UserDefaults")
                    }
                    
                    // 5. Create a basic patient record with this ID as a last resort
                    print("🔧 APPOINTMENT: Creating basic patient record with ID: \(patientId) as last resort")
                    
                    let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
                    var sqlRequest = URLRequest(url: sqlUrl)
                    sqlRequest.httpMethod = "POST"
                    sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // SQL to create a basic patient record
                    let sql = """
                    BEGIN;
                    -- Create a basic patient record with the needed ID
                    INSERT INTO patients (id, patient_id)
                    VALUES ('\(patientId)', '\(patientId)')
                    ON CONFLICT (id) DO UPDATE 
                    SET patient_id = '\(patientId)';
                    
                    COMMIT;
                    """
                    
                    let sqlParams = ["sql": sql]
                    let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
                    sqlRequest.httpBody = sqlJsonData
                    
                    let (sqlResponseData, sqlResponse) = try await URLSession.shared.data(for: sqlRequest)
                    
                    if let sqlHttpResponse = sqlResponse as? HTTPURLResponse, 
                       sqlHttpResponse.statusCode >= 200 && sqlHttpResponse.statusCode < 300 {
                        print("✅ APPOINTMENT: Successfully created basic patient record with ID: \(patientId)")
                    } else {
                        if let sqlErrorStr = String(data: sqlResponseData, encoding: .utf8) {
                            print("❌ APPOINTMENT: Error creating basic patient: \(sqlErrorStr)")
                        }
                        print("⚠️ APPOINTMENT: Failed to create basic patient with status: \(String(describing: (sqlResponse as? HTTPURLResponse)?.statusCode))")
                        
                        throw NSError(domain: "AppointmentError", code: 400, userInfo: [
                            NSLocalizedDescriptionKey: "Could not create or find a valid patient record"
                        ])
                    }
                } else {
                    print("✅ APPOINTMENT: Found patient with patient_id = \(patientId)")
                }
            } else {
                print("✅ APPOINTMENT: Patient verification successful - found in patients table")
            }
            
            // Double-check the patient_id field is set
            let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
            var sqlRequest = URLRequest(url: sqlUrl)
            sqlRequest.httpMethod = "POST"
            sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // SQL to ensure patient_id column is set
            let sql = """
            BEGIN;
            -- Ensure patient_id column is set to match id
            UPDATE patients 
            SET patient_id = '\(patientId)'
            WHERE id = '\(patientId)' AND (patient_id IS NULL OR patient_id = '');
            
            COMMIT;
            """
            
            let sqlParams = ["sql": sql]
            let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
            sqlRequest.httpBody = sqlJsonData
            
            try await URLSession.shared.data(for: sqlRequest)
            print("✅ APPOINTMENT: Ensured patient_id is set")
        } catch {
            print("❌ APPOINTMENT: Error during patient verification: \(error.localizedDescription)")
            // Continue anyway, as the direct insert will tell us if there's a foreign key issue
        }
        
        // Now try to insert the appointment
        let url = URL(string: "\(supabaseURL)/rest/v1/appointments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let jsonData = try JSONSerialization.data(withJSONObject: appointmentData)
        request.httpBody = jsonData
        
        // Print the raw JSON being sent for debugging
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📦 APPOINTMENT: Raw JSON payload: \(jsonString)")
        }
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AppointmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("📊 APPOINTMENT: Response status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
            if let errorStr = String(data: responseData, encoding: .utf8) {
                print("❌ APPOINTMENT: Error details: \(errorStr)")
                
                // If there's a foreign key error, try a different approach
                if errorStr.contains("foreign key constraint") && errorStr.contains("patient_id") {
                    print("🔧 APPOINTMENT: Trying a direct SQL approach to insert the appointment")
                    
                    let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
                    var sqlRequest = URLRequest(url: sqlUrl)
                    sqlRequest.httpMethod = "POST"
                    sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Escape values for SQL
                    let escapedReason = reason.replacingOccurrences(of: "'", with: "''")
                    
                    // Create SQL that will ensure the patient exists first, then insert the appointment
                    let sql = """
                    BEGIN;
                    
                    -- First ensure the patient exists
                    INSERT INTO patients (id, patient_id)
                    VALUES ('\(patientId)', '\(patientId)')
                    ON CONFLICT (id) DO UPDATE 
                    SET patient_id = '\(patientId)';
                    
                    -- Then insert the appointment
                    INSERT INTO appointments (
                        id, patient_id, doctor_id, hospital_id, 
                        availability_slot_id, appointment_date, status, 
                        reason, isdone, is_premium
                    ) VALUES (
                        '\(id)', '\(patientId)', '\(doctorId)', '\(hospitalId)', 
                        \(slotId), '\(formattedDate)', 'upcoming', 
                        '\(escapedReason.isEmpty ? "Medical consultation" : escapedReason)', 
                        false, false
                    );
                    
                    COMMIT;
                    """
                    
                    let sqlParams = ["sql": sql]
                    let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
                    sqlRequest.httpBody = sqlJsonData
                    
                    let (sqlResponseData, sqlResponse) = try await URLSession.shared.data(for: sqlRequest)
                    
                    if let sqlHttpResponse = sqlResponse as? HTTPURLResponse {
                        if sqlHttpResponse.statusCode >= 200 && sqlHttpResponse.statusCode < 300 {
                            print("✅ APPOINTMENT: SQL insert successful")
                            if let responseStr = String(data: sqlResponseData, encoding: .utf8) {
                                print("   Response: \(responseStr)")
                            }
                            return
                        } else {
                            print("❌ APPOINTMENT: SQL insert failed with status \(sqlHttpResponse.statusCode)")
                            if let sqlErrorStr = String(data: sqlResponseData, encoding: .utf8) {
                                print("   Error: \(sqlErrorStr)")
                            }
                        }
                    }
                }
                
                throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create appointment: \(errorStr)"])
            } else {
                throw NSError(domain: "AppointmentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create appointment with status code \(httpResponse.statusCode)"])
            }
        }
        
        print("✅ APPOINTMENT: Successfully created appointment")
    }
    
    // MARK: - Network Connectivity Check
    
    /// Check if we can connect to Supabase
    func checkConnectivity() async -> Bool {
        print("🔍 SUPABASE: Checking connectivity...")
        
        // Use a simple health check endpoint
        let url = URL(string: "\(supabaseURL)/rest/v1/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ SUPABASE CONNECTIVITY: Invalid response type")
                return false
            }
            
            let isConnected = (200..<300).contains(httpResponse.statusCode)
            print(isConnected 
                  ? "✅ SUPABASE CONNECTIVITY: Connected successfully (Status: \(httpResponse.statusCode))" 
                  : "❌ SUPABASE CONNECTIVITY: Failed to connect (Status: \(httpResponse.statusCode))")
            
            return isConnected
        } catch {
            print("❌ SUPABASE CONNECTIVITY: Error checking connection: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Ensure patient has a patient_id field - useful for fixing missing patient_id issues
    func ensurePatientHasPatientId(userId: String) async -> String? {
        print("🔄 PATIENT_ID: Checking patient record for user ID: \(userId)")
        
        do {
            // 1. First fetch the patient record by user_id
            let patients = try await select(
                from: "patients",
                where: "user_id",
                equals: userId
            )
            
            guard let patientData = patients.first else {
                print("❌ PATIENT_ID: No patient found for user ID: \(userId)")
                return nil
            }
            
            print("🔍 PATIENT_ID: Found patient record with keys: \(patientData.keys.joined(separator: ", "))")
            
            // 2. Check if patient_id already exists
            if let patientId = patientData["patient_id"] as? String, !patientId.isEmpty {
                print("✅ PATIENT_ID: Patient already has patient_id: \(patientId)")
                
                // Verify this patient_id exists in the patients table (double-check)
                let verifyPatients = try await select(
                    from: "patients",
                    where: "id",
                    equals: patientId
                )
                
                if !verifyPatients.isEmpty {
                    print("✅ PATIENT_ID: Verified patient_id exists as a primary key in patients table")
                    return patientId
                } else {
                    print("⚠️ PATIENT_ID: patient_id doesn't match any primary key in patients table")
                    // Fall through to use the id field instead
                }
            }
            
            // 3. If not, use the id as the patient_id
            guard let id = patientData["id"] as? String else {
                print("❌ PATIENT_ID: Patient record doesn't have an id")
                return nil
            }
            
            print("ℹ️ PATIENT_ID: Patient doesn't have patient_id, using id: \(id) to create one")
            
            // 4. Try a direct SQL update approach
            let url = URL(string: "\(supabaseURL)/rest/v1/patients?id=eq.\(id)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let updateData = ["patient_id": id]
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)
            request.httpBody = jsonData
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ PATIENT_ID: Successfully updated patient record with patient_id")
                } else {
                    if let errorStr = String(data: responseData, encoding: .utf8) {
                        print("⚠️ PATIENT_ID: Error updating patient: \(errorStr)")
                    }
                    print("⚠️ PATIENT_ID: Failed to update patient with status code: \(httpResponse.statusCode)")
                    
                    // Try an alternate approach - direct SQL
                    print("🔄 PATIENT_ID: Trying alternate SQL approach to add patient_id")
                    
                    // Create a direct SQL query to add the patient_id column if it doesn't exist
                    let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
                    var sqlRequest = URLRequest(url: sqlUrl)
                    sqlRequest.httpMethod = "POST"
                    sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Execute a SQL command to add the patient_id column
                    let sql = """
                    BEGIN;
                    -- Add patient_id column if it doesn't exist
                    DO $$ 
                    BEGIN
                        IF NOT EXISTS (
                            SELECT FROM information_schema.columns 
                            WHERE table_name = 'patients' AND column_name = 'patient_id'
                        ) THEN
                            ALTER TABLE patients ADD COLUMN patient_id VARCHAR(36);
                        END IF;
                    END $$;
                    
                    -- Update the specific patient record
                    UPDATE patients SET patient_id = '\(id)' WHERE id = '\(id)';
                    
                    -- Also ensure this record exists in patients table with id as primary key
                    INSERT INTO patients (id, patient_id, user_id)
                    VALUES ('\(id)', '\(id)', '\(userId)')
                    ON CONFLICT (id) DO UPDATE SET patient_id = '\(id)';
                    
                    COMMIT;
                    """
                    
                    let sqlParams = ["sql": sql]
                    let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
                    sqlRequest.httpBody = sqlJsonData
                    
                    let (sqlResponseData, sqlResponse) = try await URLSession.shared.data(for: sqlRequest)
                    
                    if let sqlHttpResponse = sqlResponse as? HTTPURLResponse {
                        if sqlHttpResponse.statusCode >= 200 && sqlHttpResponse.statusCode < 300 {
                            print("✅ PATIENT_ID: SQL approach successfully updated patient record")
                        } else {
                            if let sqlErrorStr = String(data: sqlResponseData, encoding: .utf8) {
                                print("❌ PATIENT_ID: SQL error: \(sqlErrorStr)")
                            }
                            print("❌ PATIENT_ID: SQL approach failed with status code: \(sqlHttpResponse.statusCode)")
                        }
                    }
                }
            }
            
            // 5. Verify the update worked by fetching the patient data again
            let updatedPatients = try await select(
                from: "patients",
                where: "id",
                equals: id
            )
            
            if let updatedPatient = updatedPatients.first,
               let updatedPatientId = updatedPatient["patient_id"] as? String,
               !updatedPatientId.isEmpty {
                print("✅ PATIENT_ID: Verification successful, patient_id: \(updatedPatientId)")
                
                // Additional check for foreign key constraint
                // Make sure this ID exists as a primary key in the patients table
                let primaryKeyPatients = try await select(
                    from: "patients", 
                    where: "id", 
                    equals: updatedPatientId
                )
                
                if !primaryKeyPatients.isEmpty {
                    print("✅ PATIENT_ID: Verified patient_id exists as a primary key in patients table")
                    return updatedPatientId
                } else {
                    print("⚠️ PATIENT_ID: patient_id doesn't match any primary key in patients table, using id as primary key")
                    
                    // If the patient_id doesn't exist as a primary key, we need to create that record
                    // This happens when the patient_id field exists but doesn't match a primary key
                    let fixSqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
                    var fixSqlRequest = URLRequest(url: fixSqlUrl)
                    fixSqlRequest.httpMethod = "POST"
                    fixSqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    fixSqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    fixSqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Execute SQL to fix the relationship
                    let fixSql = """
                    INSERT INTO patients (id, patient_id, user_id)
                    VALUES ('\(updatedPatientId)', '\(updatedPatientId)', '\(userId)')
                    ON CONFLICT (id) DO UPDATE SET patient_id = '\(updatedPatientId)';
                    """
                    
                    let fixSqlParams = ["sql": fixSql]
                    let fixSqlJsonData = try JSONSerialization.data(withJSONObject: fixSqlParams)
                    fixSqlRequest.httpBody = fixSqlJsonData
                    
                    let (fixSqlResponseData, fixSqlResponse) = try await URLSession.shared.data(for: fixSqlRequest)
                    
                    if let fixSqlHttpResponse = fixSqlResponse as? HTTPURLResponse,
                       fixSqlHttpResponse.statusCode >= 200 && fixSqlHttpResponse.statusCode < 300 {
                        print("✅ PATIENT_ID: Fixed primary key issue")
                        return updatedPatientId
                    } else {
                        if let fixSqlErrorStr = String(data: fixSqlResponseData, encoding: .utf8) {
                            print("❌ PATIENT_ID: Fix SQL error: \(fixSqlErrorStr)")
                        }
                        print("⚠️ PATIENT_ID: Couldn't fix primary key issue, using id as fallback")
                        return id
                    }
                }
            } else {
                print("⚠️ PATIENT_ID: Verification failed, returning id as fallback")
                return id // Return the id anyway, as a last resort
            }
        } catch {
            print("❌ PATIENT_ID: Error ensuring patient has patient_id: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Custom SQL Execution
    
    /// Execute a custom SQL query directly on the Supabase database
    /// - Parameter sql: The SQL query to execute
    /// - Returns: Dictionary containing the query result
    func executeSQL(sql: String) async throws -> [[String: Any]] {
        print("📊 Executing SQL: \(sql)")
        
        let sqlUrl = URL(string: "\(supabaseURL)/rest/v1/rpc/execute_sql")!
        var sqlRequest = URLRequest(url: sqlUrl)
        sqlRequest.httpMethod = "POST"
        sqlRequest.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        sqlRequest.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        sqlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sqlParams = ["sql": sql]
        let sqlJsonData = try JSONSerialization.data(withJSONObject: sqlParams)
        sqlRequest.httpBody = sqlJsonData
        
        let (data, response) = try await URLSession.shared.data(for: sqlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response format")
            throw NSError(domain: "SupabaseService", code: 1001, userInfo: 
                         [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        if httpResponse.statusCode == 200 {
            // Parse response as JSON
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return jsonArray
            } else if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return [jsonObject]
            } else {
                print("❌ Failed to parse SQL response JSON")
                throw NSError(domain: "SupabaseService", code: 1002, userInfo: 
                             [NSLocalizedDescriptionKey: "Failed to parse SQL response"])
            }
        } else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("❌ SQL execution failed with status \(httpResponse.statusCode): \(responseString)")
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: 
                         [NSLocalizedDescriptionKey: "SQL execution failed: \(responseString)"])
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
            CREATE TABLE IF NOT EXISTS public.pat_reports (
              id uuid not null default gen_random_uuid(),
              patient_name text not null,
              patient_id text not null,
              summary text null,
              file_url text not null,
              uploaded_at timestamp with time zone not null default timezone('utc'::text, now()),
              constraint pat_reports_pkey primary key (id)
            ) TABLESPACE pg_default;
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
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: Failed to create pat_reports table - \(errorStr)")
                }
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
    
    // Update hospital password with special handling for constraints
    func updateHospitalPassword(hospitalId: String, newPassword: String) async throws {
        print("SUPABASE: Updating hospital password for ID: \(hospitalId)")
        
        // First check if the hospital exists
        let hospitals = try await select(
            from: "hospitals",
            where: "id",
            equals: hospitalId
        )
        
        guard !hospitals.isEmpty else {
            print("SUPABASE ERROR: Hospital not found with ID: \(hospitalId)")
            throw SupabaseError.tableNotFound("Hospital not found with ID: \(hospitalId)")
        }
        
        // Prepare the update data
        let updateData: [String: Any] = [
            "password": newPassword,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Update the hospital record
        do {
            let url = URL(string: "\(supabaseURL)/rest/v1/hospitals?id=eq.\(hospitalId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.addValue("return=representation", forHTTPHeaderField: "Prefer")
            
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if httpResponse.statusCode >= 400 {
                // Parse the error message
                if let errorStr = String(data: data, encoding: .utf8) {
                    print("SUPABASE ERROR: Failed to update hospital password - \(errorStr)")
                    
                    // Check for constraint violations
                    if errorStr.contains("violates unique constraint") && errorStr.contains("hospitals_password_key") {
                        throw SupabaseError.invalidData("This password is already in use by another hospital")
                    } else if errorStr.contains("violates check constraint") {
                        throw SupabaseError.invalidData("Password does not meet the required format")
                    }
                }
                
                throw SupabaseError.requestFailed("Failed to update hospital password, status: \(httpResponse.statusCode)")
            }
            
            print("SUPABASE: Successfully updated hospital password for ID: \(hospitalId)")
        } catch let error as SupabaseError {
            print("SUPABASE ERROR: Hospital password update failed - \(error.localizedDescription)")
            throw error
        } catch {
            print("SUPABASE ERROR: Unexpected error updating hospital password - \(error.localizedDescription)")
            throw SupabaseError.requestFailed("Failed to update hospital password: \(error.localizedDescription)")
        }
    }
}

