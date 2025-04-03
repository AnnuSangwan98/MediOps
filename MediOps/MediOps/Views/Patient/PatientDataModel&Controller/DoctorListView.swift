import SwiftUI

struct DoctorListView: View {
    let hospital: HospitalModel
    @StateObject private var viewModel = DoctorViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    @State private var selectedSpeciality: String?
    @State private var refreshID = UUID() // For UI refresh on theme change
    
    var specialities: [String] {
        Array(Set(viewModel.doctors.map { $0.specialization })).sorted()
    }
    
    var body: some View {
        ZStack {
            // Apply themed background
            if themeManager.isPatient {
                themeManager.currentTheme.background
                    .ignoresSafeArea()
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        TextField("Search by doctor's name", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    }
                    .padding()
                    .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
                    .cornerRadius(10)
                    .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .gray.opacity(0.1), radius: 5)
                    
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
                                                    themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal : 
                                                    themeManager.isPatient ? themeManager.currentTheme.background.opacity(0.7) : Color.gray.opacity(0.1)
                                            )
                                            .foregroundColor(
                                                (selectedSpeciality == speciality || 
                                                 (speciality == "All" && selectedSpeciality == nil)) ?
                                                    .white : 
                                                    themeManager.isPatient ? themeManager.currentTheme.primaryText : .black
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
                
                Text("Doctors")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .tint(themeManager.isPatient ? themeManager.currentTheme.accentColor : nil)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 100)
                } else if let error = viewModel.error {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .orange)
                        
                        Text("Error Loading Doctors")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .red)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await viewModel.loadDoctors(for: hospital)
                            }
                        }) {
                            Text("Try Again")
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
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
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        
                        Text("No Active Doctors Found")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .gray)
                        
                        Text("There are currently no active doctors at \(hospital.hospitalName).")
                            .font(.subheadline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 100)
                    .frame(maxWidth: .infinity)
                } else if filteredDoctors.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        
                        Text("No Matching Doctors")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .gray)
                        
                        Text("Try adjusting your search or filters.")
                            .font(.subheadline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    }
                    .padding(.vertical, 100)
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredDoctors) { doctor in
                                DoctorCard(doctor: doctor, themeManager: themeManager)
                                    .padding(.horizontal)
                            }
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
        .onAppear {
            // Setup theme change listener
            setupThemeChangeListener()
        }
        .id(refreshID) // Force refresh when ID changes
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
    
    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Generate new ID to force view refresh
            refreshID = UUID()
        }
    }
}

struct DoctorCard: View {
    let doctor: HospitalDoctor
    @State private var showAppointment = false
    var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Doctor avatar
                Circle()
                    .fill(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    
                    Text("\(doctor.specialization) (\(doctor.experience) years Exp)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    
                    HStack {
                        Text("Rs.\(Int(doctor.consultationFee))")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                        Text("Consultation Fee")
                            .font(.caption)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    }
                }
                
                Spacer()
            }
            
            NavigationLink(destination: 
                AppointmentView(doctor: doctor)
                    // Apply theme to destination
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    .environmentObject(themeManager),
                isActive: $showAppointment
            ) {
                EmptyView()
            }
            .hidden()
            
            Button(action: {
                showAppointment = true
            }) {
                Text("Book Appointment")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(themeManager.isPatient ? themeManager.currentTheme.accentColor : Color.teal)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
        .cornerRadius(10)
        .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .gray.opacity(0.1), radius: 5)
    }
}
