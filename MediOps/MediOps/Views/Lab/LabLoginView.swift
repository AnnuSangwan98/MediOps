//
//  LabLoginView.swift
//  MediOps
//
//  Created by IOS on 17/03/25.
//

import SwiftUI

struct LabLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var labId: String = ""
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
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                        
                        Image(systemName: "document.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    Text("Lab Login")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.teal)
                }
                .padding(.top, 50)
                
                // Login Form
                VStack(spacing: 25) {
                    // Admin ID field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lab ID")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your Lab ID", text: $labId)
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
            
//            NavigationLink(destination: AdminHomeView(), isActive: $isLoggedIn) {
//                EmptyView()
//            }
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
        if labId.isEmpty || password.isEmpty {
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
        LabLoginView()
    }
}

