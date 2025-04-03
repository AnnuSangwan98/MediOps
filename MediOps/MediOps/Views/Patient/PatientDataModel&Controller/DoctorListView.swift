import SwiftUI

struct DoctorListView: View {
    let hospital: HospitalModel
    @StateObject private var viewModel = DoctorViewModel()
    @State private var searchText = ""
    @State private var selectedSpeciality: String?
    @ObservedObject private var translationManager = TranslationManager.shared
    
    var specialities: [String] {
        Array(Set(viewModel.doctors.map { $0.specialization })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Search and Filter Section
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("search_by_doctor".localized, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.1), radius: 5)
                
                // Only show speciality filter if we have doctors
                if !viewModel.doctors.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["All"] + specialities, id: \.self) { speciality in
                                Button(action: {
                                    if speciality == "All" {
                                        selectedSpeciality = nil
                                    } else {
                                        selectedSpeciality = speciality
                                    }
                                }) {
                                    Text(speciality)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            (selectedSpeciality == speciality || 
                                             (speciality == "All" && selectedSpeciality == nil)) ?
                                                Color.teal : Color.gray.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            (selectedSpeciality == speciality || 
                                             (speciality == "All" && selectedSpeciality == nil)) ?
                                                .white : .black
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
            
            Text("doctors".localized)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 100)
            } else if let error = viewModel.error {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("error".localized)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await viewModel.loadDoctors(for: hospital)
                        }
                    }) {
                        Text("try_again".localized)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.teal)
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.doctors.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("no_active_doctors".localized)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("There are currently no active doctors at \(hospital.hospitalName).")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 100)
                .frame(maxWidth: .infinity)
            } else if filteredDoctors.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("no_matching_doctors".localized)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("try_adjusting_search".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 100)
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(filteredDoctors) { doctor in
                            DoctorCard(doctor: doctor)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle(hospital.hospitalName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDoctors(for: hospital)
        }
    }
    
    private var filteredDoctors: [HospitalDoctor] {
        var doctors = viewModel.doctors.map { doctor in
            // Convert LocalDoctor model to HospitalDoctor model
            return HospitalDoctor(
                id: doctor.id,
                hospitalId: doctor.hospitalId,
                name: doctor.name,
                specialization: doctor.specialization,
                qualifications: doctor.qualifications,
                licenseNo: doctor.licenseNo,
                experience: doctor.experience,
                email: doctor.email,
                contactNumber: doctor.contactNumber,
                doctorStatus: doctor.doctorStatus,
                rating: doctor.rating,
                consultationFee: doctor.consultationFee
            )
        }
        
        if !searchText.isEmpty {
            doctors = doctors.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let speciality = selectedSpeciality {
            doctors = doctors.filter { $0.specialization == speciality }
        }
        
        return doctors
    }
}

struct DoctorCard: View {
    let doctor: HospitalDoctor
    @State private var showAppointment = false
    @ObservedObject private var translationManager = TranslationManager.shared
    
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
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("\(doctor.specialization) (\(doctor.experience) years Exp)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Rs.\(Int(doctor.consultationFee))")
                            .font(.headline)
                            .foregroundColor(.black)
                        Text("consultation_fee".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            NavigationLink(destination: AppointmentView(doctor: doctor), isActive: $showAppointment) {
                EmptyView()
            }
            .hidden()
            
            Button(action: {
                showAppointment.toggle()
            }) {
                Text("book_appointment".localized)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
