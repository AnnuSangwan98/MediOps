import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var adminId: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and Header
                VStack(spacing: 15) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.teal)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                    
                    Text("Admin Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Admin ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your admin ID", text: $adminId)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // Login Button
                    Button(action: handleLogin) {
                        HStack {
                            Text("Login")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.teal, Color.teal.opacity(0.8)]),
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .shadow(color: .teal.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            NavigationLink(destination: AdminHomeView(), isActive: $isLoggedIn) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleLogin() {
        // Validate inputs
        if adminId.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        // TODO: Implement actual login logic
        isLoggedIn = true
    }
}

#Preview {
    NavigationStack {
        AdminLoginView()
    }
} 
