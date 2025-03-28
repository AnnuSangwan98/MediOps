import SwiftUI

struct DoctorsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddDoctor = false
    @State private var showEditDoctor = false
    @State private var doctorToEdit: UIDoctor?
    @Binding var doctors: [UIDoctor]
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let adminController = AdminController.shared
    private let userController = UserController.shared
    
    init(doctors: Binding<[UIDoctor]>) {
        _doctors = doctors
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Spacer()
                    
                    Text("Doctors")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Doctors List
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading doctors...")
                                .padding()
                        } else if doctors.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No doctors added yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Tap + to add a new doctor")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding()
                        } else {
                            ForEach(doctors) { doctor in
                                DoctorCard(
                                    doctor: doctor,
                                    onEdit: { editDoctor(doctor) },
                                    onDelete: {
                                        deleteDoctor(doctor)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddDoctor = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.teal)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAddDoctor) {
            AddDoctorView { activity in
                if let doctor = activity.doctorDetails {
                    doctors.append(doctor)
                }
            }
        }
        .sheet(isPresented: $showEditDoctor) {
            if let doctor = doctorToEdit {
                EditDoctorView(doctor: doctor) { updatedDoctor in
                    if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
                        doctors[index] = updatedDoctor
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await fetchDoctors()
        }
    }
    
    private func fetchDoctors() async {
        isLoading = true
        do {
            // Try to get the current user and their hospital admin ID
            var hospitalAdminId: String? = nil
            
            if let currentUser = try? await userController.getCurrentUser() {
                print("FETCH DOCTORS: Current user ID: \(currentUser.id), role: \(currentUser.role.rawValue)")
                
                // If user is a hospital admin, use their ID directly
                if currentUser.role == .hospitalAdmin {
                    hospitalAdminId = currentUser.id
                    print("FETCH DOCTORS: User is a hospital admin, using ID: \(hospitalAdminId ?? "unknown")")
                } else {
                    // For other roles, try to get their associated hospital admin
                    do {
                        let hospitalAdmin = try await adminController.getHospitalAdminByUserId(userId: currentUser.id)
                        hospitalAdminId = hospitalAdmin.id
                        print("FETCH DOCTORS: Retrieved hospital admin ID: \(hospitalAdminId ?? "unknown")")
                    } catch {
                        print("FETCH DOCTORS WARNING: \(error.localizedDescription)")
                    }
                }
            }
            
            // If we couldn't determine the hospital admin ID, use a fallback
            if hospitalAdminId == nil {
                hospitalAdminId = "HOS001" // Fallback ID
                print("FETCH DOCTORS: Using fallback hospital admin ID: \(hospitalAdminId!)")
            }
            
            // Fetch the doctors
            print("FETCH DOCTORS: Requesting doctors for hospital admin: \(hospitalAdminId!)")
            let fetchedDoctors = try await adminController.getDoctorsByHospitalAdmin(hospitalAdminId: hospitalAdminId!)
            print("FETCH DOCTORS: Successfully retrieved \(fetchedDoctors.count) doctors")
            
            // Map to UI models
            doctors = fetchedDoctors.map { doctor in
                print("FETCH DOCTORS: Processing doctor ID: \(doctor.id), Name: \(doctor.name)")
                return UIDoctor(
                    id: doctor.id,
                    fullName: doctor.name,
                    specialization: doctor.specialization,
                    email: doctor.email,
                    phone: doctor.contactNumber ?? "",
                    gender: .male, // Default gender
                    dateOfBirth: Date(), // Default date
                    experience: doctor.experience,
                    qualification: doctor.qualifications.joined(separator: ", "),
                    license: doctor.licenseNo,
                    address: doctor.addressLine
                )
            }
        } catch {
            print("FETCH DOCTORS ERROR: \(error.localizedDescription)")
            errorMessage = "Failed to fetch doctors: \(error.localizedDescription)"
            showError = true
        }
        isLoading = false
    }
    
    private func editDoctor(_ doctor: UIDoctor) {
        doctorToEdit = doctor
        showEditDoctor = true
    }
    
    private func deleteDoctor(_ doctor: UIDoctor) {
        // TODO: Implement deletion through Supabase
        withAnimation {
            if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
                doctors.remove(at: index)
            }
        }
    }
}

struct DoctorCard: View {
    let doctor: UIDoctor
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.fullName)
                        .font(.headline)
                    Text(doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
            
            HStack {
                Image(systemName: "phone.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(doctor.phone.isEmpty ? "No phone" : doctor.phone)
                    .font(.caption)
                Spacer()
                Image(systemName: "envelope.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(doctor.email.isEmpty ? "No email" : doctor.email)
                    .font(.caption)
            }
            
            Text("License: \(doctor.license.isEmpty ? "Unknown" : doctor.license)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
} 

