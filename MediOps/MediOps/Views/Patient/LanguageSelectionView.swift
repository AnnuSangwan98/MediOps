import SwiftUI

// Simple enum to represent application languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case spanish = "es"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        case .spanish: return "Español (Spanish)"
        }
    }
}

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedLanguage: AppLanguage
    
    init() {
        // Initialize selected language to default
        _selectedLanguage = State(initialValue: .english)
    }
    
    // Helper functions to simplify view building
    private func textColor() -> Color {
        return themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary
    }
    
    private func accentColor() -> Color {
        return themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal
    }
    
    private func rowBackground() -> Color {
        // Use background instead of cardBackground (which doesn't exist)
        return themeManager.isPatient ? themeManager.currentTheme.background : .white
    }
    
    private func toolbarBackground() -> Color {
        return themeManager.isPatient ? themeManager.currentTheme.background : Color.teal.opacity(0.1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Apply themed background
                if themeManager.isPatient {
                    themeManager.currentTheme.background
                        .ignoresSafeArea()
                }
                
                List {
                    ForEach(AppLanguage.allCases) { language in
                        Button(action: {
                            selectedLanguage = language
                            // Save language preference (mock functionality)
                            UserDefaults.standard.set(language.rawValue, forKey: "preferred_language")
                            dismiss()
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(textColor())
                                Spacer()
                                if language == selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(accentColor())
                                }
                            }
                        }
                        .listRowBackground(rowBackground())
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(textColor())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(accentColor())
                }
            }
            .toolbarBackground(toolbarBackground(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
} 