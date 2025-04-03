import SwiftUI

struct AccessibilitySettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var selectedTheme: AppTheme?
    
    var body: some View {
        NavigationView {
            Group {
                if isPatientUser() {
                    patientAccessibilityView
                } else {
                    nonPatientView
                }
            }
            .navigationTitle("Accessibility")
            .background(Color.white.ignoresSafeArea())
            .foregroundColor(themeManager.currentTheme.primaryText)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // View shown to patients with accessibility theme options
    private var patientAccessibilityView: some View {
        List {
            Section(header: Text("Appearance Themes")) {
                ForEach(themeManager.availableThemes, id: \.self) { theme in
                    ThemeRow(theme: theme, isSelected: themeManager.currentTheme == theme)
                        .onTapGesture {
                            withAnimation {
                                // Apply theme and trigger UI refresh
                                themeManager.applyTheme(theme)
                                
                                // Additional UI refresh by triggering state change
                                selectedTheme = theme
                                
                                // Give time for the theme to apply
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    // Force a UI refresh by updating app state
                                    UIApplication.shared.windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                                }
                            }
                        }
                }
            }
            
            Section(header: Text("About Accessibility Themes")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("High Contrast Theme")
                        .font(.headline)
                    Text("Designed for better readability and clarity with strong contrast between text and background.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Colorblind-Friendly Theme")
                        .font(.headline)
                        .padding(.top, 5)
                    Text("Uses colors that are distinguishable for most types of color vision deficiency.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Low Vision-Friendly Theme")
                        .font(.headline)
                        .padding(.top, 5)
                    Text("Reduces eye strain with lower glare and comfortable color combinations for extended viewing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            }
        }
    }
    
    // View shown to non-patient users
    private var nonPatientView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            Text("Accessibility Features")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("These accessibility options are only available for patient accounts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Text("Please log in as a patient to access these features.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
                .padding(.top, 10)
        }
        .padding()
    }
    
    // Helper function to check if current user is a patient
    private func isPatientUser() -> Bool {
        return navigationState.userRole == .patient
    }
}

// Row for displaying a theme option with color samples
struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.displayName)
                    .font(.headline)
                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            // Color samples for the theme
            HStack(spacing: 4) {
                Circle()
                    .fill(theme.primaryText)
                    .frame(width: 15, height: 15)
                Circle()
                    .fill(theme.accentColor)
                    .frame(width: 15, height: 15)
                Circle()
                    .fill(theme.secondaryAccent)
                    .frame(width: 15, height: 15)
            }
        }
        .padding(.vertical, 8)
    }
}

// Make AppTheme hashable for ForEach
extension AppTheme: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .standard:
            hasher.combine(0)
        case .highContrast:
            hasher.combine(1)
        case .colorblindFriendly:
            hasher.combine(2)
        case .lowVisionFriendly:
            hasher.combine(3)
        }
    }
    
    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        switch (lhs, rhs) {
        case (.standard, .standard),
             (.highContrast, .highContrast),
             (.colorblindFriendly, .colorblindFriendly),
             (.lowVisionFriendly, .lowVisionFriendly):
            return true
        default:
            return false
        }
    }
}

#Preview {
    AccessibilitySettingsView()
        .environmentObject(AppNavigationState())
} 