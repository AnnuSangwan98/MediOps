import SwiftUI

struct DoctorListView: View {
    let hospital: HospitalModel
    @StateObject private var viewModel = HospitalViewModel()
    @State private var selectedSpecialization: String?
    
    var body: some View {
        VStack {
            // Specialization picker
            if !hospital.departments.isEmpty {
                Picker("Select Specialization", selection: $selectedSpecialization) {
                    Text("All Specializations").tag(nil as String?)
                    ForEach(hospital.departments, id: \.self) { specialization in
                        Text(specialization).tag(specialization as String?)
                    }
                }
                .pickerStyle(.menu)
                .padding()
            }
            
            // Doctor list
            List(viewModel.doctors) { doctor in
                DoctorRow(doctor: doctor)
                    .onTapGesture {
                        viewModel.selectedDoctor = doctor
                    }
            }
        }
        .navigationTitle("Doctors")
        .task {
            viewModel.selectedHospital = hospital
            viewModel.selectedSpecialization = selectedSpecialization
            await viewModel.fetchDoctors()
        }
        .onChange(of: selectedSpecialization) { newValue in
            viewModel.selectedSpecialization = newValue
            Task {
                await viewModel.fetchDoctors()
            }
        }
    }
}

struct DoctorRow: View {
    let doctor: Doctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(doctor.name)
                .font(.headline)
            Text(doctor.specialization)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(doctor.experience) years experience")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(doctor.qualifications.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
