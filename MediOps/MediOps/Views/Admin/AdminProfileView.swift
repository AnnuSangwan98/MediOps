import SwiftUI

struct AdminProfileView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var showLogoutAlert = false
    
    // Mock admin data - In a real app, this would come from your authentication system
    private let adminData = [
        "Name": "Admin User",
        "Email": "admin@mediops.com",
        "Role": "System Administrator",
        "Last Login": "Today at 9:00 AM"
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.teal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(adminData["Name"] ?? "")
                                .font(.headline)
                            Text(adminData["Email"] ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account Information") {
                    ForEach(adminData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        if key != "Name" && key != "Email" {
                            HStack {
                                Text(key)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(value)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    // TODO: Implement logout functionality
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    AdminProfileView()
}