import SwiftUI

struct DoctorListView: View {
    let hospital: HospitalModel
    @StateObject private var viewModel = DoctorViewModel()
    @State private var searchText = ""
    @State private var selectedSpeciality: String?
    @ObservedObject private var translationManager = TranslationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
                        .foregroundColor(themeManager.colors.subtext)
                    TextField("search_by_doctor".localized, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(themeManager.colors.text)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: themeManager.colors.primary.opacity(0.1), radius: 5)
                
                // Speciality filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedSpeciality = nil
                        }) {
                            Text("All")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSpeciality == nil ? themeManager.colors.primary : Color.gray.opacity(0.1))
                                .foregroundColor(selectedSpeciality == nil ? .white : themeManager.colors.text)
                                .cornerRadius(20)
                        }
                        
                        ForEach(specialities, id: \.self) { speciality in
                            Button(action: {
                                selectedSpeciality = speciality
                            }) {
                                Text(speciality)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedSpeciality == speciality ? themeManager.colors.primary : Color.gray.opacity(0.1))
                                    .foregroundColor(selectedSpeciality == speciality ? .white : themeManager.colors.text)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            
            Text("doctors".localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.primary))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 100)
            } else if let error = viewModel.error {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.colors.error)
                    
                    Text("error".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.error)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(themeManager.colors.subtext)
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
                            .background(themeManager.colors.primary)
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
                        .foregroundColor(themeManager.colors.subtext)
                    
                    Text("no_active_doctors".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("There are currently no active doctors at \(hospital.hospitalName).")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.subtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 100)
                .frame(maxWidth: .infinity)
            } else if filteredDoctors.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.colors.subtext)
                    
                    Text("no_matching_doctors".localized)
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("try_adjusting_search".localized)
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.subtext)
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
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Doctor avatar
                Circle()
                    .fill(themeManager.colors.primary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("\(doctor.specialization) (\(doctor.experience) years Exp)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.colors.subtext)
                    
                    HStack {
                        Text("Rs.\(Int(doctor.consultationFee))")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        Text("consultation_fee".localized)
                            .font(.caption)
                            .foregroundColor(themeManager.colors.subtext)
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
                    .background(themeManager.colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: themeManager.colors.primary.opacity(0.2), radius: 5)
    }
}
