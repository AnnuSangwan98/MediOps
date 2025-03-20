import SwiftUI

struct DoctorListView: View {
    let hospitalName: String
    let hospital: Hospital
    @StateObject private var doctorVM = DoctorViewModel()
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                searchBar
                titleSection
                doctorList
            }
            .padding(.vertical)
        }
        .navigationTitle(hospitalName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            doctorVM.loadDoctors(for: hospital)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search by doctor's name", text: $searchText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var titleSection: some View {
        Text("Doctors")
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal)
    }
    
    private var doctorList: some View {
        LazyVStack(spacing: 15) {
            ForEach(doctorVM.doctors) { doctor in
                DoctorCard(doctor: doctor)
                    .padding(.horizontal)
            }
        }
    }
}

struct DoctorCard: View {
    let doctor: DoctorDetail
    @State private var showAppointment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            doctorHeader
            doctorFooter
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .sheet(isPresented: $showAppointment) {
            AppointmentView(doctor: doctor)
        }
    }
    
    private var doctorHeader: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.teal)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(doctor.name)
                    .font(.headline)
                Text("\(doctor.specialization)(\(doctor.experience)years Exp)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", doctor.rating))
            }
        }
    }
    
    private var doctorFooter: some View {
        HStack {
            Text("Rs.\(Int(doctor.consultationFee))")
                .font(.headline)
            Text("Consultation Fee")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: { showAppointment.toggle() }) {
                Text("Book Appointment")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.teal)
                    .cornerRadius(8)
            }
        }
    }
}
