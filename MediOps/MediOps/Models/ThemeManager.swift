import SwiftUI

enum AppTheme: String, CaseIterable {
    case standard = "Standard"
    case highContrast = "High Contrast"
    case colorblindFriendly = "Colorblind Friendly"
    case lowVision = "Low Vision Friendly"
    
    var description: String {
        switch self {
        case .standard:
            return "Default app appearance"
        case .highContrast:
            return "Maximizes readability with high contrast colors"
        case .colorblindFriendly:
            return "Optimized for users with color vision deficiency"
        case .lowVision:
            return "Reduces glare and enhances comfort for extended viewing"
        }
    }
    
    var themeColors: [Color] {
        switch self {
        case .standard:
            return [
                Color(red: 0.4, green: 0.7, blue: 0.8),  // Teal
                Color.black,
                Color.gray
            ]
        case .highContrast:
            return [
                Color.black,          // Primary
                Color(red: 0.0, green: 0.32, blue: 0.73),  // Secondary (navy blue)
                Color(red: 1.0, green: 0.84, blue: 0.0)   // Accent (yellow)
            ]
        case .colorblindFriendly:
            return [
                Color(red: 0.0, green: 0.45, blue: 0.7),   // Primary (blue)
                Color(red: 0.85, green: 0.55, blue: 0.0),   // Secondary (orange)
                Color(red: 0.2, green: 0.6, blue: 0.4)     // Accent (green)
            ]
        case .lowVision:
            return [
                Color(red: 0.2, green: 0.4, blue: 0.3),    // Primary (dark green)
                Color(red: 0.45, green: 0.35, blue: 0.3),   // Secondary (brown)
                Color(red: 0.5, green: 0.6, blue: 0.5)      // Accent (sage)
            ]
        }
    }
}

struct ThemeColors {
    let primary: Color      // Main brand color
    let secondary: Color    // Secondary elements
    let accent: Color       // Accent elements
    let background: Color   // Background color
    let text: Color        // Primary text
    let subtext: Color     // Secondary text
    let error: Color       // Error messages and indicators
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
            updateColors()
        }
    }
    
    @Published private(set) var colors: ThemeColors
    
    private init() {
        // Reset the saved theme to ensure Standard is the new default
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        self.currentTheme = .standard
        
        self.colors = ThemeColors(
            primary: Color(red: 0.4, green: 0.7, blue: 0.8),  // Teal
            secondary: Color.black,
            accent: Color.gray,
            background: .white,
            text: Color.black,
            subtext: Color.gray,
            error: .red
        )
        
        updateColors()
    }
    
    private func updateColors() {
        switch currentTheme {
        case .standard:
            colors = ThemeColors(
                primary: Color(red: 0.4, green: 0.7, blue: 0.8),  // Teal
                secondary: Color.black,
                accent: Color.gray,
                background: .white,
                text: Color.black,
                subtext: Color.gray,
                error: .red
            )
            
        case .highContrast:
            colors = ThemeColors(
                primary: .black,
                secondary: Color(red: 0.0, green: 0.32, blue: 0.73),
                accent: Color(red: 1.0, green: 0.84, blue: 0.0),
                background: .white,
                text: .black,
                subtext: Color(red: 0.0, green: 0.32, blue: 0.73),
                error: Color(red: 0.8, green: 0.0, blue: 0.0)
            )
            
        case .colorblindFriendly:
            colors = ThemeColors(
                primary: Color(red: 0.0, green: 0.45, blue: 0.7),
                secondary: Color(red: 0.85, green: 0.55, blue: 0.0),
                accent: Color(red: 0.2, green: 0.6, blue: 0.4),
                background: .white,
                text: Color(red: 0.0, green: 0.45, blue: 0.7),
                subtext: Color(red: 0.85, green: 0.55, blue: 0.0),
                error: Color(red: 0.8, green: 0.0, blue: 0.0)
            )
            
        case .lowVision:
            colors = ThemeColors(
                primary: Color(red: 0.2, green: 0.4, blue: 0.3),
                secondary: Color(red: 0.45, green: 0.35, blue: 0.3),
                accent: Color(red: 0.5, green: 0.6, blue: 0.5),
                background: Color(red: 0.95, green: 0.93, blue: 0.90),
                text: Color(red: 0.2, green: 0.4, blue: 0.3),
                subtext: Color(red: 0.45, green: 0.35, blue: 0.3),
                error: Color(red: 0.7, green: 0.0, blue: 0.0)
            )
        }
    }
} 