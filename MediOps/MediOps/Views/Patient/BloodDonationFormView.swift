import SwiftUI

struct BloodDonationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var selectedBloodGroup = "A+"
    @State private var donationDate = Date()
    @State private var donationTime = Date()
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                    TextField("Address", text: $address)
                }
                
                Section(header: Text("Blood Information")) {
                    Picker("Blood Group", selection: $selectedBloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                }
                
                Section(header: Text("Donation Schedule")) {
                    DatePicker("Date", selection: $donationDate, displayedComponents: .date)
                    DatePicker("Time", selection: $donationTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Donate Blood")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        // Handle submission
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

struct BloodDonationFormView_Previews: PreviewProvider {
    static var previews: some View {
        BloodDonationFormView()
    }
} 