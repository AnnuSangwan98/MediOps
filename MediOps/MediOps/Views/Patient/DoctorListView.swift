import SwiftUI

struct DoctorListView: View {
    let hospital: HospitalModel
    @ObservedObject private var viewModel = HospitalViewModel.shared
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by doctor's name", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            
            Text("Doctors")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(filteredDoctors) { doctor in
                        DoctorCard(doctor: doctor)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(hospital.hospitalName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.selectedHospital = hospital
            await viewModel.fetchDoctors()
        }
    }
    
    private var filteredDoctors: [Doctor] {
        if searchText.isEmpty {
            return viewModel.doctors
        }
        return viewModel.doctors.filter { doctor in
            doctor.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct DoctorCard: View {
    let doctor: Doctor
    @State private var showAppointment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Doctor avatar
                Circle()
                    .fill(Color.teal)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.headline)
                    
                    Text("\(doctor.specialization)(\(doctor.experience)years Exp)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Rs.\(Int(doctor.consultationFee))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Consultation Fee")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Rating
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", doctor.rating))
                        .font(.headline)
                }
            }
            
            Button(action: {
                showAppointment.toggle()
            }) {
                Text("Book Appointment")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.teal)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .sheet(isPresented: $showAppointment) {
            AppointmentView(doctor: doctor)
        }
    }
}
