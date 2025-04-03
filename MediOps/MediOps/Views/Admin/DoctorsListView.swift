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
    @State private var doctorToDelete: UIDoctor?
    @State private var showDeleteConfirmation = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
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
                                AdminDoctorCard(
                                    doctor: doctor,
                                    onEdit: { editDoctor(doctor) },
                                    onDelete: {
                                        doctorToDelete = doctor
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await fetchDoctors()
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
                // Refresh the list after adding a doctor
                Task {
                    await fetchDoctors()
                }
            }
        }
        .sheet(isPresented: $showEditDoctor) {
            if let doctor = doctorToEdit {
                EditDoctorView(doctor: doctor) { updatedDoctor in
                    // Refresh the list after editing a doctor
                    Task {
                        await fetchDoctors()
                    }
                }
            }
        }
        // Error alert
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        // Delete confirmation alert
        .alert("Delete Doctor", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let doctor = doctorToDelete {
                    confirmDeleteDoctor(doctor)
                }
            }
        } message: {
            Text("Are you sure you want to delete this doctor? This action cannot be undone.")
        }
        // Success message alert
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .task {
            await fetchDoctors()
        }
    }
    
    private func fetchDoctors() async {
        isLoading = true
        do {
            // Get hospital ID from UserDefaults (saved during login)
            guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                print("FETCH DOCTORS ERROR: No hospital ID found in UserDefaults")
                errorMessage = "Failed to fetch doctors: Hospital ID not found. Please login again."
                showError = true
                isLoading = false
                return
            }
            
            print("FETCH DOCTORS: Using hospital ID from UserDefaults: \(hospitalId)")
            
            // Fetch doctors for the specific hospital ID from Supabase
            let fetchedDoctors = try await adminController.getDoctorsByHospitalAdmin(hospitalAdminId: hospitalId)
            print("FETCH DOCTORS: Successfully retrieved \(fetchedDoctors.count) doctors")
                
            // Filter only active doctors
            let activeDoctors = fetchedDoctors.filter { $0.doctorStatus == "active" }
            print("FETCH DOCTORS: Filtered to \(activeDoctors.count) active doctors for hospital \(hospitalId)")
            
            // Map to UI models
            await MainActor.run {
                doctors = activeDoctors.map { doctor in
                    print("FETCH DOCTORS: Processing doctor ID: \(doctor.id), Name: \(doctor.name)")
                    return UIDoctor(
                        id: doctor.id,
                        fullName: doctor.name,
                        specialization: doctor.specialization,
                        email: doctor.email,
                        phone: doctor.contactNumber ?? "",
                        gender: .male, // Default gender
                        dateOfBirth: doctor.dateOfBirth ?? Date(), // Use actual DOB from Supabase with fallback
                        experience: doctor.experience,
                        qualification: doctor.qualifications.joined(separator: ", "),
                        license: doctor.licenseNo,
                        address: doctor.addressLine,
                        maxAppointments: doctor.maxAppointments
                    )
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("FETCH DOCTORS ERROR: \(error.localizedDescription)")
                errorMessage = "Failed to fetch doctors: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func editDoctor(_ doctor: UIDoctor) {
        doctorToEdit = doctor
        showEditDoctor = true
    }
    
    private func confirmDeleteDoctor(_ doctor: UIDoctor) {
        isLoading = true
        
        Task {
            do {
                // Call the AdminController to mark the doctor as inactive
                try await adminController.deleteDoctor(id: doctor.id)
                
                await MainActor.run {
                    // Remove from UI list
                    withAnimation {
                        if let index = doctors.firstIndex(where: { $0.id == doctor.id }) {
                            doctors.remove(at: index)
                        }
                    }
                    
                    // Show success message
                    successMessage = "Doctor successfully removed"
                    showSuccessMessage = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete doctor: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

struct AdminDoctorCard: View {
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

