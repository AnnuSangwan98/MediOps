//
//  DoctorCredentialsManager.swift
//  MediOps
//
//  Created by Sharvan on 21/03/25.
//

import Foundation

class DoctorCredentialsManager {
    static func generateDoctorId(prefix: String = "DOC") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "\(prefix)\(timestamp % 10000)\(random)"
    }
    
    static func generateSecurePassword(length: Int = 12) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*"
        
        var password = ""
        
        // Ensure at least one character from each category
        password += String(letters.randomElement()!)
        password += String(letters.uppercased().randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(specialChars.randomElement()!)
        
        // Fill the rest with random characters
        let allChars = letters + numbers + specialChars
        for _ in password.count..<length {
            password += String(allChars.randomElement()!)
        }
        
        // Shuffle the password
        return String(password.shuffled())
    }
    
    static func sendCredentialsEmail(doctor: Doctor, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://localhost:8082/send-credentials") else {
            completion(false, "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Set timeout to 30 seconds
        
        let emailData: [String: Any] = [
            "fullName": doctor.fullName,
            "doctorId": doctor.id,
            "email": doctor.email,
            "password": password,
            "specialization": doctor.specialization,
            "license": doctor.license,
            "phone": doctor.phone
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        switch error.code {
                        case NSURLErrorTimedOut:
                            completion(false, "Request timed out. Please try again.")
                        case NSURLErrorNotConnectedToInternet:
                            completion(false, "No internet connection. Please check your network settings.")
                        case NSURLErrorCannotConnectToHost:
                            completion(false, "Cannot connect to server. Please try again later.")
                        default:
                            completion(false, "Error: \(error.localizedDescription)")
                        }
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            completion(true, nil)
                        } else {
                            completion(false, "Failed to send credentials email (Status: \(httpResponse.statusCode))")
                        }
                    }
                }
            }.resume()
        } catch {
            completion(false, "Failed to prepare email data")
        }
    }
}