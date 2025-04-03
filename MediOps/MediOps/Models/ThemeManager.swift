import SwiftUI

enum AppTheme: String, CaseIterable {
    case standard = "Standard"
    case highContrast = "High Contrast"
    case lowVision = "Low Vision Friendly"
    
    var description: String {
        switch self {
        case .standard:
            return "Default blue theme with optimal contrast"
        case .highContrast:
            return "Yellow/Orange theme for enhanced visibility"
        case .lowVision:
            return "Soft brown theme that reduces eye strain"
        }
    }
    
    var themeColors: [Color] {
        switch self {
        case .standard:
            return [
                Color(red: 0.0, green: 0.48, blue: 0.8),  // Primary blue
                Color(red: 0.1, green: 0.1, blue: 0.1),   // Text
                Color(red: 0.5, green: 0.6, blue: 0.7)    // Accent
            ]
        case .highContrast:
            return [
                Color(red: 0.95, green: 0.65, blue: 0.0), // Primary orange
                Color(red: 0.0, green: 0.48, blue: 0.8),  // Secondary blue
                Color(red: 1.0, green: 0.84, blue: 0.0)   // Accent yellow
            ]
        case .lowVision:
            return [
                Color(red: 0.4, green: 0.3, blue: 0.2),   // Primary brown
                Color(red: 0.85, green: 0.8, blue: 0.75), // Background beige
                Color(red: 0.5, green: 0.4, blue: 0.3)    // Accent brown
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
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .standard
        }
        
        self.colors = ThemeColors(
            primary: .blue,
            secondary: .black,
            accent: .blue,
            background: .white,
            text: .black,
            subtext: .gray,
            error: .red
        )
        
        updateColors()
    }
    
    private func updateColors() {
        switch currentTheme {
        case .standard:
            colors = ThemeColors(
                primary: Color(red: 0.0, green: 0.48, blue: 0.8),
                secondary: Color(red: 0.1, green: 0.1, blue: 0.1),
                accent: Color(red: 0.5, green: 0.6, blue: 0.7),
                background: .white,
                text: Color(red: 0.1, green: 0.1, blue: 0.1),
                subtext: Color(red: 0.5, green: 0.6, blue: 0.7),
                error: .red
            )
            
        case .highContrast:
            colors = ThemeColors(
                primary: Color(red: 0.95, green: 0.65, blue: 0.0),
                secondary: Color(red: 0.0, green: 0.48, blue: 0.8),
                accent: Color(red: 1.0, green: 0.84, blue: 0.0),
                background: .white,
                text: Color(red: 0.0, green: 0.48, blue: 0.8),
                subtext: Color(red: 0.95, green: 0.65, blue: 0.0),
                error: Color(red: 0.8, green: 0.0, blue: 0.0)
            )
            
        case .lowVision:
            colors = ThemeColors(
                primary: Color(red: 0.4, green: 0.3, blue: 0.2),
                secondary: Color(red: 0.5, green: 0.4, blue: 0.3),
                accent: Color(red: 0.5, green: 0.4, blue: 0.3),
                background: Color(red: 0.85, green: 0.8, blue: 0.75),
                text: Color(red: 0.4, green: 0.3, blue: 0.2),
                subtext: Color(red: 0.5, green: 0.4, blue: 0.3),
                error: Color(red: 0.7, green: 0.0, blue: 0.0)
            )
        }
    }
} 