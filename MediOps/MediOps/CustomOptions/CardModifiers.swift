import SwiftUI

// MARK: - View Modifiers for themed UI elements

// Themed card modifier with customizable background and overlay
struct ThemedCardModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 5
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(
                        color: themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.15) : 
                            .gray.opacity(0.15), 
                        radius: shadowRadius
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.2) : 
                            Color.teal.opacity(0.2), 
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal)
    }
}

// Themed search bar modifier
struct ThemedSearchBarModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    var cornerRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(
                        color: themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.2) : 
                            .teal.opacity(0.2), 
                        radius: 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.3) : 
                            Color.teal.opacity(0.3), 
                        lineWidth: 1
                    )
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}

// Themed hospital card modifier
struct ThemedHospitalCardModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.15) : 
                            .gray.opacity(0.15), 
                        radius: 5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        themeManager.isPatient ? 
                            themeManager.currentTheme.accentColor.opacity(0.2) : 
                            Color.teal.opacity(0.2), 
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal)
    }
}

// MARK: - View Extensions

extension View {
    func themedCard(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 5) -> some View {
        self.modifier(ThemedCardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    func themedSearchBar(cornerRadius: CGFloat = 10) -> some View {
        self.modifier(ThemedSearchBarModifier(cornerRadius: cornerRadius))
    }
    
    func themedHospitalCard() -> some View {
        self.modifier(ThemedHospitalCardModifier())
    }
}

// MARK: - Themed Components

struct ThemedSearchBar: View {
    @Binding var text: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            
            TextField("Search hospitals...", text: $text)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                }
            }
        }
        .themedSearchBar()
    }
}

struct ThemedDivider: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Divider()
            .background(themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
    }
} 