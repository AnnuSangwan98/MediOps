import AppIntents
import SwiftUI

struct EmergencySOSIntent: AppIntent {
    static var title: LocalizedStringResource = "Call Hospital Emergency"
    static var description: IntentDescription = IntentDescription(
        "Call hospital emergency number",
        categoryName: "Emergency",
        searchKeywords: ["emergency", "hospital", "SOS", "ambulance", "help"]
    )
    
    // You can customize this based on your hospital's emergency number
    @Parameter(title: "Hospital Emergency Number")
    var emergencyNumber: String = "911" // Default emergency number, can be customized
    
    func perform() async throws -> some IntentResult {
        // Convert the phone number string to a URL
        guard let phoneURL = URL(string: "tel://\(emergencyNumber.replacingOccurrences(of: " ", with: ""))") else {
            throw Error.invalidPhoneNumber
        }
        
        // Open the phone URL to initiate the call
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
            return .result(dialog: "Calling hospital emergency number \(emergencyNumber)")
        } else {
            throw Error.cannotMakeCall
        }
    }
    
    enum Error: Swift.Error {
        case invalidPhoneNumber
        case cannotMakeCall
    }
}

// Create the shortcut
let emergencyShortcut = AppShortcut(
    intent: EmergencySOSIntent(),
    phrases: [
        "Call hospital emergency with \(.applicationName)",
        "Emergency SOS with \(.applicationName)",
        "Get medical help with \(.applicationName)"
    ],
    systemImageName: "phone.circle.fill"
) 