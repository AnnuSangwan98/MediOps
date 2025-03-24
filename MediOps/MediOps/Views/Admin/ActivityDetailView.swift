import SwiftUI

struct ActivityDetailView: View {
    let activity: UIActivity
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Activity Information")) {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(typeString)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(activity.title)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(activity.timestamp, style: .date)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(statusString)
                            .foregroundColor(statusColor)
                    }
                }
                
                if let doctor = activity.doctorDetails {
                    Section(header: Text("Doctor Details")) {
                        DetailRow(label: "Name", value: doctor.fullName)
                        DetailRow(label: "Specialization", value: doctor.specialization)
                        DetailRow(label: "Email", value: doctor.email)
                        DetailRow(label: "Phone", value: doctor.phone)
                    }
                }
                
                if let labAdmin = activity.labAdminDetails {
                    Section(header: Text("Lab Admin Details")) {
                        DetailRow(label: "Name", value: labAdmin.fullName)
                        DetailRow(label: "Email", value: labAdmin.email)
                        DetailRow(label: "Phone", value: labAdmin.phone)
                    }
                }
                
                // New section for hospital details
                if let hospital = activity.hospitalDetails {
                    Section(header: Text("Hospital Details")) {
                        DetailRow(label: "Name", value: hospital.name)
                        DetailRow(label: "Admin Name", value: hospital.adminName)
                        DetailRow(label: "License", value: hospital.licenseNumber)
                        DetailRow(label: "Address", value: "\(hospital.street), \(hospital.city), \(hospital.state) \(hospital.zipCode)")
                        DetailRow(label: "Email", value: hospital.email)
                        DetailRow(label: "Phone", value: hospital.phone)
                    }
                }
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var typeString: String {
        switch activity.type {
        case .doctorAdded:
            return "Doctor Added"
        case .labAdminAdded:
            return "Lab Admin Added"
        case .hospitalAdded:
            return "Hospital Added"
        }
    }
    
    private var statusString: String {
        switch activity.status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .completed:
            return "Completed"
        }
    }
    
    private var statusColor: Color {
        switch activity.status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .completed:
            return .blue
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ActivityDetailView(activity: UIActivity(
        type: .hospitalAdded,
        title: "New Hospital: City General Hospital",
        timestamp: Date(),
        status: .pending,
        doctorDetails: nil,
        labAdminDetails: nil,
        hospitalDetails: UIHospital(
            name: "City General Hospital",
            adminName: "John Doe",
            licenseNumber: "AB12345",
            street: "123 Main St",
            city: "Mumbai",
            state: "Maharashtra",
            zipCode: "400001",
            phone: "+919876543210",
            email: "admin@cityhospital.com"
        )
    ))
} 