import SwiftUI

// View modifier to apply theme to any view
struct ThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentTheme.background)
            .foregroundColor(themeManager.currentTheme.primaryText)
            .accentColor(themeManager.currentTheme.accentColor)
    }
}

// Theme modifier that only applies if user is a patient
struct PatientThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        if themeManager.isPatient {
            content
                .background(themeManager.currentTheme.background)
                .foregroundColor(themeManager.currentTheme.primaryText)
                .accentColor(themeManager.currentTheme.accentColor)
        } else {
            content
        }
    }
}

// Style for themed buttons
struct ThemedButtonStyle: ButtonStyle {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.accentColor)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// Style for themed secondary buttons
struct ThemedSecondaryButtonStyle: ButtonStyle {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 1.5)
            )
            .foregroundColor(themeManager.currentTheme.accentColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// Style for themed text fields
struct ThemedTextFieldStyle: TextFieldStyle {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.background)
                    .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1)
            )
    }
}

// Extension for easy theme application
extension View {
    func themed() -> some View {
        self.modifier(ThemeModifier())
    }
    
    func patientThemed() -> some View {
        self.modifier(PatientThemeModifier())
    }
    
    func themedButton() -> some View {
        self.buttonStyle(ThemedButtonStyle())
    }
    
    func themedSecondaryButton() -> some View {
        self.buttonStyle(ThemedSecondaryButtonStyle())
    }
} 