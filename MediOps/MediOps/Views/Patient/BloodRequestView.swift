import SwiftUI

struct BloodRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasActiveRequest: Bool
    @State private var selectedDate = Date()
    @State private var selectedBloodGroup = "A+"
    @State private var showRequestSuccess = false
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Request Blood")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    // Terms and Guidelines
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Important Guidelines")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            GuidelineRow(text: "Request must be genuine and for medical purposes only")
                            GuidelineRow(text: "Required documentation may be needed at the donation center")
                            GuidelineRow(text: "Request will be matched with available donors")
                            GuidelineRow(text: "Emergency requests will be prioritized")
                            GuidelineRow(text: "Keep your contact information updated")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Blood Group Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Required Blood Group")
                            .font(.headline)
                        
                        Picker("Blood Group", selection: $selectedBloodGroup) {
                            ForEach(bloodGroups, id: \.self) { group in
                                Text(group).tag(group)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.vertical)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Required Date")
                            .font(.headline)
                        
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    
                    // Request Button
                    Button(action: {
                        showRequestSuccess = true
                    }) {
                        Text("Submit Request")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRequestSuccess) {
                RequestSuccessView(hasActiveRequest: $hasActiveRequest, dismiss: dismiss)
            }
        }
    }
}

struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.red)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct RequestSuccessView: View {
    @Binding var hasActiveRequest: Bool
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Request Submitted!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your blood request has been submitted successfully. We will notify you when a matching donor is found.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button("Done") {
                hasActiveRequest = true
                dismiss()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    BloodRequestView(hasActiveRequest: .constant(false))
} 