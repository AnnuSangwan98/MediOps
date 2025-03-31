import SwiftUI

struct BloodRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasActiveRequest: Bool
    @State private var selectedBloodType: String = "A+"
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    @StateObject private var profileController = PatientProfileController()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        RequestInfoRow(title: "Request Status", value: "Will be matched with available donors")
                        RequestInfoRow(title: "Priority", value: "Emergency requests will be prioritized")
                        RequestInfoRow(title: "Contact Info", value: "Keep your contact information updated")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Blood Group Selection
                    VStack(alignment: .leading) {
                        Text("Required Blood Group")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(bloodTypes, id: \.self) { type in
                                    BloodTypeButton(
                                        type: type,
                                        isSelected: selectedBloodType == type,
                                        action: { selectedBloodType = type }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Required Date
                    VStack(alignment: .leading) {
                        Text("Required Date")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            await submitRequest()
                        }
                    }) {
                        ZStack {
                            Text("Submit Request")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .opacity(isLoading ? 0 : 1)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Blood Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Load patient profile when view appears
                if let userId = UserDefaults.standard.string(forKey: "userId") {
                    Task {
                        await profileController.loadProfile(userId: userId)
                    }
                }
            }
        }
    }
    
    private func submitRequest() async {
        guard let patient = profileController.patient else {
            errorMessage = "Unable to load patient profile"
            showError = true
            return
        }
        
        isLoading = true
        do {
            // Check if patient already has an active request
            let hasExisting = try await BloodDonationController.shared.hasActiveRequest(patientId: patient.id)
            if hasExisting {
                errorMessage = "You already have an active blood request"
                showError = true
                isLoading = false
                return
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let requestData: [String: String] = [
                "id": patient.id,
                "blood_type": selectedBloodType,
                "donation_date": dateFormatter.string(from: selectedDate),
                "created_at": dateFormatter.string(from: Date()),
                "updated_at": dateFormatter.string(from: Date())
            ]
            
            // Insert into blood_donation table
            try await SupabaseController.shared.insert(into: "blood_donation", data: requestData)
            
            isLoading = false
            hasActiveRequest = true
            dismiss()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct RequestInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
        }
    }
}

struct BloodTypeButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.red : Color.white)
                .foregroundColor(isSelected ? .white : .red)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 1)
                )
        }
    }
}

#Preview {
    BloodRequestView(hasActiveRequest: .constant(false))
} 