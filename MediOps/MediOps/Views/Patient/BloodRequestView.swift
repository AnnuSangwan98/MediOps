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
                            in: Date()...Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
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
                print("🏥 Loading patient profile...")
                // Load patient profile when view appears
                if let userId = UserDefaults.standard.string(forKey: "current_user_id") {
                    print("🏥 Found user ID in UserDefaults: \(userId)")
                    Task {
                        do {
                            await profileController.loadProfile(userId: userId)
                            if profileController.patient != nil {
                                print("✅ Successfully loaded patient profile")
                            } else {
                                print("❌ Failed to load patient profile - patient is nil")
                                errorMessage = "Unable to load patient profile"
                                showError = true
                            }
                        }
                    }
                } else {
                    print("❌ No user ID found in UserDefaults")
                    errorMessage = "No user ID found. Please log in again."
                    showError = true
                }
            }
        }
    }
    
    private func submitRequest() async {
        guard let patient = profileController.patient else {
            print("❌ No patient profile loaded")
            errorMessage = "Unable to load patient profile"
            showError = true
            return
        }
        
        print("🩸 Starting blood request submission")
        print("🩸 Patient ID: \(patient.id)")
        print("🩸 Blood Group: \(selectedBloodType)")
        print("🩸 Required Date: \(selectedDate)")
        
        isLoading = true
        do {
            let success = await BloodDonationController.shared.createBloodDonationRequest(
                patientId: patient.id,
                bloodGroup: selectedBloodType
            )
            
            if success {
                print("✅ Blood request created successfully")
                await MainActor.run {
                    isLoading = false
                    hasActiveRequest = true
                    dismiss()
                }
            } else {
                print("❌ Failed to create blood request")
                await MainActor.run {
                    errorMessage = "Failed to create blood request. Please try again."
                    showError = true
                    isLoading = false
                }
            }
        } catch {
            print("❌ Error in submitRequest: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "An error occurred: \(error.localizedDescription)"
                showError = true
            }
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
