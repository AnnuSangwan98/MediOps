import SwiftUI

// Theme Manager for accessibility options (only for patients)
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .standard {
        didSet {
            // Post notification when theme changes to trigger UI refresh
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }
    
    // Singleton instance for global access
    static let shared = ThemeManager()
    
    private init() {}
    
    // Current user role from AppNavigationState
    private var userRole: UserRole {
        // Get from UserDefaults if available
        if let userId = UserDefaults.standard.string(forKey: "current_user_id"),
           let userData = UserDefaults.standard.dictionary(forKey: "user_data_\(userId)"),
           let roleString = userData["role"] as? String,
           let role = UserRole(rawValue: roleString) {
            return role
        }
        
        // Default to patient if not found (for safety)
        return .patient
    }
    
    // Check if current user is a patient
    var isPatient: Bool {
        return userRole == .patient
    }
    
    // Apply theme only if user is a patient
    func applyTheme(_ theme: AppTheme) {
        if isPatient {
            currentTheme = theme
        }
    }
    
    // Get available themes - only return multiple options for patients
    var availableThemes: [AppTheme] {
        if isPatient {
            return [.standard, .highContrast, .colorblindFriendly, .lowVisionFriendly]
        } else {
            return [.standard]
        }
    }
}

// Available themes in the app
enum AppTheme {
    case standard
    case highContrast
    case colorblindFriendly
    case lowVisionFriendly
    
    // Primary colors for text, background, buttons, and accents
    var primaryText: Color {
        switch self {
        case .standard:
            return Color.primary
        case .highContrast:
            return Color(hex: "333333") // Dark Charcoal
        case .colorblindFriendly:
            return Color(hex: "0072B2") // Deep Blue
        case .lowVisionFriendly:
            return Color(hex: "004D40") // Dark Teal
        }
    }
    
    var background: Color {
        switch self {
        case .standard:
            return Color(.systemBackground)
        case .highContrast:
            return Color(hex: "FFFFFF") // Pure White
        case .colorblindFriendly:
            return Color.white
        case .lowVisionFriendly:
            return Color(hex: "E6D5C3") // Warm Beige
        }
    }
    
    var accentColor: Color {
        switch self {
        case .standard:
            return Color.accentColor
        case .highContrast:
            return Color(hex: "004488") // Deep Blue for highlights
        case .colorblindFriendly:
            return Color(hex: "E69F00") // Bright Orange
        case .lowVisionFriendly:
            return Color(hex: "A67C52") // Golden Brown
        }
    }
    
    var secondaryAccent: Color {
        switch self {
        case .standard:
            return Color.secondary
        case .highContrast:
            return Color(hex: "FFCC00") // Warm Yellow
        case .colorblindFriendly:
            return Color(hex: "009E73") // Forest Green
        case .lowVisionFriendly:
            return Color(hex: "6D8B74") // Soft Olive Green
        }
    }
    
    var tertiaryAccent: Color {
        switch self {
        case .standard:
            return Color.gray
        case .highContrast:
            return Color(hex: "004488").opacity(0.7) // Lighter Deep Blue
        case .colorblindFriendly:
            return Color(hex: "CC79A7") // Dark Purple
        case .lowVisionFriendly:
            return Color(hex: "004D40").opacity(0.8) // Lighter Dark Teal
        }
    }
    
    // Names for display in settings
    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .highContrast:
            return "High Contrast"
        case .colorblindFriendly:
            return "Colorblind Friendly"
        case .lowVisionFriendly:
            return "Low Vision Friendly"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "Default app appearance"
        case .highContrast:
            return "Maximizes readability with high contrast colors"
        case .colorblindFriendly:
            return "Optimized for users with color vision deficiency"
        case .lowVisionFriendly:
            return "Reduces glare and enhances comfort for extended viewing"
        }
    }
}

// Notification name for theme changes
extension Notification.Name {
    static let themeChanged = Notification.Name("com.mediops.themeChanged")
} 