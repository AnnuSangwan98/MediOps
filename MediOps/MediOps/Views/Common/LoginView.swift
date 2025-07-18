import SwiftUI
import Foundation

struct LoginView<Credentials: LoginCredentials>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentials: Credentials
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showChangePasswordSheet: Bool = false
    
    let title: String
    let onLogin: (Credentials) -> Void
    
    // Add initializer for credentials
    init(title: String, initialCredentials: Credentials, onLogin: @escaping (Credentials) -> Void) {
        self.title = title
        self._credentials = State(initialValue: initialCredentials)
        self.onLogin = onLogin
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Login form implementation
                // ... (existing login form UI code) ...
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // Make sure CustomBackButton is defined
                Button("Back") {
                    dismiss()
                }
            }
        }
    }
} 