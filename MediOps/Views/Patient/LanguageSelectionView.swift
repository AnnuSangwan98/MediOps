import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var translationManager = TranslationManager.shared
    @State private var selectedLanguage: AppLanguage
    
    init() {
        // Initialize selected language to the current one
        _selectedLanguage = State(initialValue: TranslationManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                        translationManager.setLanguage(language)
                        dismiss()
                    }) {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.teal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .localizedLayout()
    }
} 