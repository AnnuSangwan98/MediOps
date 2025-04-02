import SwiftUI
import struct MediOps.BloodDonor

struct AllBloodDonorsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var donors: [BloodDonor] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    
    private let adminController = AdminController.shared
    
    var filteredDonors: [BloodDonor] {
        if searchText.isEmpty {
            return donors
        } else {
            return donors.filter { donor in
                donor.name.lowercased().contains(searchText.lowercased()) ||
                donor.bloodGroup.lowercased().contains(searchText.lowercased()) ||
                donor.email.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading donors...")
                        .padding()
                } else if donors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "drop.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No blood donors registered")
                            .font(.headline)
                        
                        Text("There are no registered blood donors in the system")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredDonors) { donor in
                            DonorRow(donor: donor)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search donors by name or blood group")
                }
            }
            .navigationTitle("All Blood Donors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await fetchAllDonors()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await fetchAllDonors()
            }
        }
    }
    
    private func fetchAllDonors() async {
        isLoading = true
        
        do {
            // Pass nil to get all donors without filtering by blood group
            donors = try await adminController.getRegisteredBloodDonors(bloodGroup: nil)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load blood donors: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct DonorRow: View {
    let donor: BloodDonor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(donor.name)
                    .font(.headline)
                
                Spacer()
                
                Text(donor.bloodGroup)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(getBloodGroupColor(donor.bloodGroup))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.gray)
                Text(formatPhoneNumber(donor.contactNumber))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.gray)
                Text(donor.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
    
    // Format phone number to standard display format
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        guard phoneNumber.count == 10 else { return phoneNumber }
        
        let firstPart = phoneNumber.prefix(3)
        let secondPart = phoneNumber.dropFirst(3).prefix(3)
        let thirdPart = phoneNumber.dropFirst(6)
        
        return "\(firstPart)-\(secondPart)-\(thirdPart)"
    }
    
    // Get background color based on blood group
    private func getBloodGroupColor(_ bloodGroup: String) -> Color {
        switch bloodGroup.uppercased() {
        case "A+", "A-":
            return .blue
        case "B+", "B-":
            return .green
        case "AB+", "AB-":
            return .purple
        case "O+", "O-":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    AllBloodDonorsView()
} 