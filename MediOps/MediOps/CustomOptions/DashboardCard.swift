import SwiftUI

// Dashboard card component with theme support
struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            // TODO: Implement action
        }) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : color)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
} 