import SwiftUI

struct DoctorListView: View {
    let hospitalName: String
    @StateObject private var doctorVM = DoctorViewModel()
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by doctor's name", text: $searchText)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
//                Text("\(doctorVM.doctors.count) Doctors found in")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
                Text("Doctors")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                   
                
                // Doctor list
                LazyVStack(spacing: 15) {
                    ForEach(doctorVM.doctors) { doctor in
                        DoctorCard(doctor: doctor)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(hospitalName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
    }
}

struct DoctorCard: View {
    let doctor: DoctorDetail
    @State private var showAppointment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            
            if doctor.isAvailableNow {
                HStack {
                    Image(systemName: "video.fill")
                    Text("Video Consult")
                }
                .font(.caption)
                .foregroundColor(.green)
            }
            
            HStack {
                Text("$\(Int(doctor.consultationFee))")
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
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
        .sheet(isPresented: $showAppointment) {
            AppointmentView(doctor: doctor)
        }
    }
}
