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
        
        // Initialize with standard theme colors
        self.colors = ThemeColors(
            primary: Color(red: 0.351, green: 0.680, blue: 0.769),  // Teal
            secondary: Color(red: 1.0, green: 0.65, blue: 0.0),     // Orange/Gold
            accent: Color(red: 1.0, green: 0.65, blue: 0.0),        // Orange/Gold
            background: .white,
            text: .black,
            subtext: Color.gray,
            error: Color(red: 1.0, green: 0.65, blue: 0.0)          // Orange/Gold for consistency
        )
        
        updateColors()
    }
    
    private func updateColors() {
        switch currentTheme {
        case .standard:
            colors = ThemeColors(
                primary: Color(red: 0.351, green: 0.680, blue: 0.769),  // Teal
                secondary: Color(red: 1.0, green: 0.65, blue: 0.0),     // Orange/Gold
                accent: Color(red: 1.0, green: 0.65, blue: 0.0),        // Orange/Gold
                background: .white,
                text: .black,
                subtext: Color.gray,
                error: Color(red: 1.0, green: 0.65, blue: 0.0)          // Orange/Gold for consistency
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