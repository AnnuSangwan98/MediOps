import SwiftUI
import struct MediOps.BloodDonor

struct BloodDonationRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBloodGroup = "A+"
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var registeredDonors: [BloodDonor] = []
    @State private var selectedDonors: Set<String> = []
    @State private var isLoadingDonors = true
    
    private let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    private let adminController = AdminController.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Request Details")) {
                    Picker("Blood Group Needed", selection: $selectedBloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .onChange(of: selectedBloodGroup) { newValue in
                        Task {
                            await fetchRegisteredDonors(bloodGroup: newValue)
                        }
                    }
                }
                
                Section(header: Text("Registered Donors")) {
                    if isLoadingDonors {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if registeredDonors.isEmpty {
                        Text("No registered donors found for \(selectedBloodGroup) blood group")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        Text("Select donors to send request:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(registeredDonors) { donor in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(donor.name)
                                        .font(.headline)
                                    Text("Blood Group: \(donor.bloodGroup)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedDonors.contains(donor.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.teal)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedDonors.contains(donor.id) {
                                    selectedDonors.remove(donor.id)
                                } else {
                                    selectedDonors.insert(donor.id)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: sendBloodDonationRequest) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Request")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedDonors.isEmpty ? Color.gray : Color.teal)
                    .cornerRadius(10)
                    .disabled(selectedDonors.isEmpty || isLoading)
                }
            }
            .navigationTitle("Blood Donation Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Blood donation requests sent successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await fetchRegisteredDonors(bloodGroup: selectedBloodGroup)
            }
        }
    }
    
    private func fetchRegisteredDonors(bloodGroup: String? = nil) async {
        isLoadingDonors = true
        selectedDonors.removeAll()
        
        defer { isLoadingDonors = false }
        
        do {
            registeredDonors = try await adminController.getRegisteredBloodDonors(bloodGroup: bloodGroup)
            
            // Auto-select all donors with matching blood group
            for donor in registeredDonors {
                selectedDonors.insert(donor.id)
            }
        } catch {
            errorMessage = "Failed to load blood donors: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func sendBloodDonationRequest() {
        guard !selectedDonors.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await adminController.sendBloodDonationRequest(
                    donorIds: Array(selectedDonors),
                    bloodGroup: selectedBloodGroup
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    BloodDonationRequestView()
} 