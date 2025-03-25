import SwiftUI

struct BloodRequestFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patientName = ""
    @State private var medicalName = ""
    @State private var phoneNumber = ""
    @State private var unitsNeeded = ""
    @State private var selectedBloodGroup = "A+"
    @State private var selectedDistrict = "Pabna"
    @State private var area = ""
    @State private var requestDate = Date()
    @State private var requestTime = Date()
    
    let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    let districts = ["Pabna", "Dhaka", "Chittagong", "Rajshahi", "Khulna"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $patientName)
                    TextField("Medical Name", text: $medicalName)
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                }
                
                Section(header: Text("Blood Requirements")) {
                    TextField("Units Needed", text: $unitsNeeded)
                        .textContentType(.none)
                    
                    Picker("Blood Group", selection: $selectedBloodGroup) {
                        ForEach(bloodGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                }
                
                Section(header: Text("Location Details")) {
                    Picker("District", selection: $selectedDistrict) {
                        ForEach(districts, id: \.self) { district in
                            Text(district).tag(district)
                        }
                    }
                    TextField("Area", text: $area)
                }
                
                Section(header: Text("Request Schedule")) {
                    DatePicker("Date", selection: $requestDate, displayedComponents: .date)
                    DatePicker("Time", selection: $requestTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Request Blood")
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

struct BloodRequestFormView_Previews: PreviewProvider {
    static var previews: some View {
        BloodRequestFormView()
    }
} 