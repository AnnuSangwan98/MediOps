import SwiftUI

struct AccessibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("APPEARANCE THEMES")) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeRow(theme: theme)
                    }
                }
                
                Section(header: Text("ABOUT ACCESSIBILITY THEMES")) {
                    VStack(alignment: .leading, spacing: 16) {
                        AccessibilityInfoRow(
                            title: "High Contrast Theme",
                            value: "Designed for better readability and clarity with strong contrast between text and background."
                        )
                        
                        AccessibilityInfoRow(
                            title: "Colorblind-Friendly Theme",
                            value: "Uses colors that are distinguishable for most types of color vision deficiency."
                        )
                        
                        AccessibilityInfoRow(
                            title: "Low Vision Friendly Theme",
                            value: "Reduces glare and enhances comfort for extended viewing."
                        )
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ThemeRow: View {
    let theme: AppTheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.rawValue)
                    .font(.body)
                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Theme color preview
            HStack(spacing: 4) {
                ForEach(theme.themeColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                }
            }
            
            if themeManager.currentTheme == theme {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .padding(.leading, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            themeManager.currentTheme = theme
        }
    }
}

private struct AccessibilityInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    AccessibilityView()
} 