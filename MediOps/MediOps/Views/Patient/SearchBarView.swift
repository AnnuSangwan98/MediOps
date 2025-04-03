import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search hospitals..."
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            
            TextField(placeholder, text: $text)
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(
                    color: themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        .teal.opacity(0.2), 
                    radius: 3
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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

// Preview
struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarView(text: .constant(""))
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 