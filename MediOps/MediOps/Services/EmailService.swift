import Foundation

class EmailService {
    static let shared = EmailService()
    
    // Make this public for other services to use
    private(set) var serverUrl = "http://127.0.0.1:8085"
    
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
    
    func sendOTP(to email: String, role: String) async throws -> String {
        // Generate a random 6-digit OTP
        let otp = String(Int.random(in: 100000...999999))
        print("Sending OTP: \(otp) to \(email)")
        
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                    print("Email server error: \(responseString)")
                    throw NSError(domain: "EmailError", 
                                 code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to send verification code. Please try again later."])
                }
            }
            
            print("OTP sent successfully to \(email)")
            return otp
        } catch let error as NSError {
            if error.domain == "NSURLErrorDomain" {
                // Check if email server is running
                print("Email server connection error: \(error.localizedDescription)")
                
                // For a better user experience, try to restart the email server
                tryRestartEmailServer()
                
                throw NSError(domain: "EmailError", 
                             code: error.code,
                             userInfo: [NSLocalizedDescriptionKey: "Could not connect to email service. Please try again."])
            }
            
            print("Error sending OTP: \(error.localizedDescription)")
            throw NSError(domain: "EmailError", 
                         code: error.code,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to send verification code: \(error.localizedDescription)"])
        }
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
        
        // Execute the email_server.sh script
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["/Users/aryanshukla/Documents/GitHub/MediOps/MediOps/Services/email_server.sh"]
        
        do {
            try task.run()
            // Wait a moment for server to start
            Thread.sleep(forTimeInterval: 3)
            print("Email server restart attempt completed")
        } catch {
            print("Failed to restart email server: \(error.localizedDescription)")
        }
        #endif
    }
} 