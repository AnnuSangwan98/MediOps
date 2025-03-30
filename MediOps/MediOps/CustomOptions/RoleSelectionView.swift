import SwiftUI

struct RoleSelectionView: View {
    @State private var selectedRole: Role = .none
    @EnvironmentObject private var navigationState: AppNavigationState
    
    enum Role {
        case superAdmin, admin, doctor, lab, patient, none
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Logo and Welcome Text
                VStack(spacing: 20) {
                    // Medical bag logo
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                        
                        Image(systemName: "cross.case.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                    }
                    
                    // Welcome Text
                    VStack(spacing: 8) {
                        Text("Welcome to MediOps")
                            .font(.system(size: 35, weight: .semibold))
                            .foregroundColor(.teal)
                            .multilineTextAlignment(.center)
                        
                        Text("Select your role")
                            .font(.title3)
                            .foregroundColor(.gray)
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
                            icon: "person.badge.key",
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
            .background(Color.white)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
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
