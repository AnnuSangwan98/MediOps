import Foundation
import SwiftUI

@MainActor
class DoctorViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    
    func loadDoctors(for hospital: HospitalModel) async {
        let hospitalViewModel = HospitalViewModel()
        await MainActor.run {
            hospitalViewModel.selectedHospital = hospital
        }
        await hospitalViewModel.fetchDoctors()
        await MainActor.run {
            self.doctors = hospitalViewModel.doctors
        }
    }
}

struct DoctorView: View {
    let doctor: Doctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(doctor.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(doctor.specialization)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.teal)
                Text("\(doctor.experience) years experience")
                    .font(.subheadline)
            }
            
            Text("Qualifications:")
                .font(.subheadline)
                .fontWeight(.medium)
            Text(doctor.qualifications.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let contact = doctor.contactNumber {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.teal)
                    Text(contact)
                        .font(.subheadline)
                }
            }
            
            Text("License No: \(doctor.licenseNo)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}