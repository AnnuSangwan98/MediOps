import SwiftUI

struct RoleSelectionView: View {
    @State private var selectedRole: Role = .none
    @EnvironmentObject private var navigationState: AppNavigationState
    @State private var particleOpacity = 0.0
    
    // Define the teal color to match the app's color scheme
    let primaryTeal = Color(red: 43/255, green: 182/255, blue: 205/255)
    
    enum Role {
        case superAdmin, admin, doctor, lab, patient, none
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.95), Color(white: 0.97)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Particle effects
                ParticlesView(count: 75)
                    .opacity(particleOpacity)
                
                // Circular glow
                Circle()
                    .fill(primaryTeal.opacity(0.1))
                    .frame(width: 350, height: 450)
                    .blur(radius: 50)
                    .opacity(particleOpacity)
                
                VStack(spacing: 40) {
                    
                    VStack(spacing: 20) {
                        
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: .gray.opacity(0.2), radius: 10)
                            
                            Image(systemName: "person.fill.questionmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.teal)
                        }
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            Text("Select Your Role")
                                .font(.system(size: 35, weight: .semibold))
                                .foregroundColor(.teal)
                                .multilineTextAlignment(.center)
                            
                        }
                    }
                    .padding(.top, 60)
                    
                    // Role Selection Buttons
                    VStack(spacing: 20) {
                        // Super Admin Button
                        NavigationLink(destination: SuperAdminLoginView()) {
                            RoleButton(
                                icon: "person.badge.key",
                                title: "Super Admin",
                                isHighlighted: selectedRole == .superAdmin
                            )
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedRole = .superAdmin
                            navigationState.selectRole(.superAdmin)
                        })
                        
                        // Administrator Button
                        NavigationLink(destination: AdminLoginView()) {
                            RoleButton(
                                icon: "person.badge.plus",
                                title: "Admin",
                                isHighlighted: selectedRole == .admin
                            )
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedRole = .admin
                        })
                        
                        // Doctor Button
                        NavigationLink(destination: DoctorLoginView()) {
                            RoleButton(
                                icon: "stethoscope",
                                title: "Doctor",
                                isHighlighted: selectedRole == .doctor
                            )
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedRole = .doctor
                            navigationState.selectRole(.doctor)
                        })
                        
                        // Lab Button
                        NavigationLink(destination: LabAdminLoginView()) {
                            RoleButton(
                                icon: "flask",
                                title: "Lab Admin",
                                isHighlighted: selectedRole == .lab
                            )
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedRole = .lab
                            navigationState.selectRole(.labAdmin)
                        })
                        
                        // Patient Button
                        NavigationLink(destination: PatientLoginView()) {
                            RoleButton(
                                icon: "person",
                                title: "Patient",
                                isHighlighted: selectedRole == .patient
                            )
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            selectedRole = .patient
                            navigationState.selectRole(.patient)
                        })
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EmptyView()
                    }
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    particleOpacity = 1.0
                }
            }
        }
    }
}

struct RoleButton: View {
    let icon: String
    let title: String
    let isHighlighted: Bool
    
    var body: some View {
        HStack {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(isHighlighted ? Color.white : Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(color: .gray.opacity(0.2), radius: 8)
                
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.teal)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(isHighlighted ? .white : .black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(isHighlighted ? .white : .gray)
                .font(.system(size: 20, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isHighlighted ? Color.teal : Color.white)
                .shadow(color: .gray.opacity(0.15), radius: 8)
        )
    }
}

#Preview {
    RoleSelectionView()
} 
