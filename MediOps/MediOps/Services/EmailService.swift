import Foundation
// Fix the import for Process
#if os(macOS)
import Foundation.NSProcessInfo // This brings in Process on macOS
#endif

class EmailService {
    static let shared = EmailService()
    
    // Make this public for other services to use
    private(set) var serverUrl = "http://127.0.0.1:8089"
    
    // Public accessor for the server URL
    var baseServerUrl: String {
        return serverUrl
    }
    
    private init() {
        // Check if a specific port is set in UserDefaults or temp file
        if let savedPort = UserDefaults.standard.string(forKey: "email_server_port") {
            serverUrl = "http://127.0.0.1:\(savedPort)"
            print("Using saved email server port from UserDefaults: \(savedPort)")
        } else {
            // Try to read from the temp file that the email_server.sh script writes
            do {
                let portString = try String(contentsOfFile: "/tmp/email_server_port.txt", encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                if !portString.isEmpty {
                    serverUrl = "http://127.0.0.1:\(portString)"
                    print("Using email server port from temp file: \(portString)")
                    UserDefaults.standard.set(portString, forKey: "email_server_port")
                }
            } catch {
                print("Could not read email server port from temp file: \(error.localizedDescription)")
            }
        }
    }
    
    // Method to send OTP and store it in memory for verification
    func sendOTP(to email: String, role: String) async throws -> String {
        // Generate a random 6-digit OTP
        let otp = String(Int.random(in: 100000...999999))
        print("Sending OTP: \(otp) to \(email)")
        
        // In all builds, send the email
        guard let url = URL(string: "\(serverUrl)/send-otp") else {
            print("Invalid URL: \(serverUrl)/send-otp")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "otp": otp,
            "subject": "Your MediOps \(role) Verification Code"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response data"
            print("Email server error: \(responseString)")
            
            // Try to restart the server if it's not responding
            tryRestartEmailServer()
            
            throw NSError(domain: "EmailError", 
                         code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to send verification code. Please try again later."])
        }
        
        print("OTP sent successfully to \(email)")
        
        // Store OTP in UserDefaults temporarily for verification (not secure for production!)
        // This is just to make the current flow work
        UserDefaults.standard.set(otp, forKey: "otp_for_\(email)")
        
        return otp
    }
    
    // Method to verify OTP
    func verifyOTP(email: String, otp: String) -> Bool {
        guard let storedOTP = UserDefaults.standard.string(forKey: "otp_for_\(email)") else {
            return false
        }
        
        let isValid = storedOTP == otp
        
        // Remove the OTP from storage after verification
        if isValid {
            UserDefaults.standard.removeObject(forKey: "otp_for_\(email)")
        }
        
        return isValid
    }
    
    // Method to update the server port if it changes
    func updateServerPort(_ port: String) {
        serverUrl = "http://127.0.0.1:\(port)"
        UserDefaults.standard.set(port, forKey: "email_server_port")
        print("Email server URL updated to: \(serverUrl)")
    }
    
    // Try to restart the email server if it's not responding
    private func tryRestartEmailServer() {
        #if DEBUG
        print("Attempting to restart email server...")
        
        #if os(macOS)
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["/Users/aryanshukla/Documents/GitHub/MediOps/MediOps/Services/email_server.sh"]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print("Server restart output: \(output)")
            }
            
            // Wait a moment for server to start
            Thread.sleep(forTimeInterval: 3)
            print("Email server restart attempt completed")
        } catch {
            print("Failed to restart email server: \(error.localizedDescription)")
        }
        #else
        print("Server restart not implemented for this platform")
        #endif
        #endif
    }
} 