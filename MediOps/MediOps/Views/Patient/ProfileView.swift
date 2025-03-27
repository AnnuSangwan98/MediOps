import SwiftUI

struct ProfileView: View {
    @AppStorage("userId") private var userId: String?
    @StateObject private var profileController = PatientProfileController()
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.teal)
                        
                        Text(profileController.patient.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(profileController.patient.phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    // Profile Options
                    VStack(spacing: 15) {
                        ProfileOptionButton(
                            icon: "person.text.rectangle",
                            title: "Edit Profile",
                            action: { showingEditProfile = true }
                        )
                        
                        ProfileOptionButton(
                            icon: "bell",
                            title: "Notifications",
                            action: {}
                        )
                        
                        ProfileOptionButton(
                            icon: "doc.text",
                            title: "Medical Records",
                            action: {}
                        )
                        
                        ProfileOptionButton(
                            icon: "heart",
                            title: "Health Data",
                            action: {}
                        )
                        
                        ProfileOptionButton(
                            icon: "gear",
                            title: "Settings",
                            action: {}
                        )
                        
                        ProfileOptionButton(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            action: {}
                        )
                        
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Logout")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(profileController: profileController)
            }
        }
    }
    
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userRole")
        
        // Navigate to login screen
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let loginView = LoginView(
                title: "Login",
                initialCredentials: PatientCredentials(email: "", password: ""),
                onLogin: { credentials in
                    // Handle login if needed
                }
            )
            window.rootViewController = UIHostingController(rootView: loginView)
            window.makeKeyAndVisible()
        }
    }
}

struct ProfileOptionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.teal)
                Text(title)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 5)
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var profileController: PatientProfileController
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    profileController.updateProfile(
                        name: name,
                        phoneNumber: phone,
                        address: address
                    )
                    dismiss()
                }
            )
            .onAppear {
                name = profileController.patient.name
                phone = profileController.patient.phoneNumber
                address = profileController.patient.address
            }
        }
    }
} 