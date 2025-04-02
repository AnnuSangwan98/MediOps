import Foundation
// Fix the import for Process
#if os(macOS)
import Foundation.NSProcessInfo // This brings in Process on macOS
#endif

class EmailService {
    static let shared = EmailService()
    
    // HARDCODED URL - do not change this unless absolutely necessary
    private(set) var serverUrl = "http://127.0.0.1:8082"
    
    // Public accessor for the server URL
    var baseServerUrl: String {
        return serverUrl
    }
    
    private init() {
        // Fixed port for stability
        serverUrl = "http://127.0.0.1:8082"
        print("EMAIL SERVICE: Using fixed server URL \(serverUrl)")
    }
    
    // Method to send OTP and store it in memory for verification
    func sendOTP(to email: String, role: String) async throws -> String {
        // Generate a random 6-digit OTP
        let otp = String(Int.random(in: 100000...999999))
        print("SEND OTP: Generated OTP: \(otp) for \(email)")
        
        // ALWAYS store OTP in UserDefaults for verification even if email fails
        // This ensures login flow works even if email server is down
        UserDefaults.standard.set(otp, forKey: "otp_for_\(email)")
        print("SEND OTP: Stored OTP in UserDefaults for \(email)")
        
        // Try to send email but don't block app functionality if it fails
        do {
            guard let url = URL(string: "\(serverUrl)/send-email") else {
                print("SEND OTP WARNING: Invalid URL: \(serverUrl)/send-email")
                return otp // Return OTP anyway so app flow continues
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "to": email,
                "otp": otp,
                "role": role
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("SEND OTP: Attempting to send email to \(email) via \(serverUrl)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, 
               (200...299).contains(httpResponse.statusCode) {
                print("SEND OTP: Successfully sent email to \(email)")
            } else {
                print("SEND OTP WARNING: Server returned non-success status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let responseText = String(data: data, encoding: .utf8) {
                    print("SEND OTP WARNING: Response: \(responseText)")
                }
            }
        } catch {
            print("SEND OTP WARNING: Failed to send email: \(error.localizedDescription)")
            print("SEND OTP: Continuing without email - OTP is stored locally")
        }
        
        return otp
    }
    
    // Method to verify OTP
    func verifyOTP(email: String, otp: String) -> Bool {
        guard let storedOTP = UserDefaults.standard.string(forKey: "otp_for_\(email)") else {
            print("VERIFY OTP: No OTP found for \(email)")
            return false
        }
        
        let isValid = storedOTP == otp
        print("VERIFY OTP: Comparing entered OTP: \(otp) with stored OTP: \(storedOTP) for \(email) - \(isValid ? "Valid" : "Invalid")")
        
        // Remove the OTP from storage after verification
        if isValid {
            UserDefaults.standard.removeObject(forKey: "otp_for_\(email)")
            print("VERIFY OTP: Removed OTP for \(email) after successful verification")
        }
        
        return isValid
    }
    
    /// Method to send a password reset email and return the token
    func sendPasswordResetEmail(to email: String, role: String) async throws -> String {
        print("PASSWORD RESET: Generating token for \(email)")
        
        // Generate a secure token (similar structure to how the server would do it)
        let token = UUID().uuidString
        
        // Store token in UserDefaults for verification
        UserDefaults.standard.set(email, forKey: "reset_token_\(token)")
        print("PASSWORD RESET: Stored token for \(email) locally")
        
        // Try to send email but don't block app functionality if it fails
        do {
            guard let url = URL(string: "\(serverUrl)/send-password-reset") else {
                print("PASSWORD RESET WARNING: Invalid URL")
                return token
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "email": email,
                "role": role,
                "token": token  // Include the token in the request
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            print("PASSWORD RESET: Attempting to send password reset email to \(email)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, 
               (200...299).contains(httpResponse.statusCode) {
                print("PASSWORD RESET: Successfully sent email to \(email)")
            } else {
                print("PASSWORD RESET WARNING: Server returned non-success status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let responseText = String(data: data, encoding: .utf8) {
                    print("PASSWORD RESET WARNING: Response: \(responseText)")
                }
            }
        } catch {
            print("PASSWORD RESET WARNING: Failed to send email: \(error.localizedDescription)")
            print("PASSWORD RESET: Continuing without email - token is stored locally")
        }
        
        return token
    }
    
    /// Method to verify a password reset token
    func verifyPasswordResetToken(token: String) async throws -> String {
        // Check if token exists in UserDefaults
        guard let email = UserDefaults.standard.string(forKey: "reset_token_\(token)") else {
            print("VERIFY TOKEN: Invalid or expired token")
            throw NSError(domain: "EmailError", 
                         code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid or expired reset token."])
        }
        
        print("VERIFY TOKEN: Valid token for \(email)")
        // Remove the token from storage after verification
        UserDefaults.standard.removeObject(forKey: "reset_token_\(token)")
        
        return email
    }
}
