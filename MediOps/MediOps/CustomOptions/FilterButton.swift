import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected 
                                ? (themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                                : Color.white
                        )
                )
                .foregroundColor(
                    isSelected 
                        ? Color.white 
                        : (themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected 
                                ? Color.clear 
                                : (themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.3) : Color.teal.opacity(0.3)),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected 
                        ? (themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.4) : Color.teal.opacity(0.4))
                        : Color.gray.opacity(0.2),
                    radius: 2,
                    y: 1
                )
        }
    }
}

#Preview {
    HStack {
        FilterButton(title: "All", isSelected: true, action: {})
        FilterButton(title: "Delhi", isSelected: false, action: {})
        FilterButton(title: "Mumbai", isSelected: false, action: {})
    }
    .padding()
} 