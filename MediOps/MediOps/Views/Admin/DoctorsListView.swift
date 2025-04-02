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
                            LazyVStack(spacing: 15) {
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
                            .padding(.vertical, 10)
                        }
                    }
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
        .navigationTitle("Doctors")
        .navigationBarTitleDisplayMode(.inline)
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
                        dateOfBirth: Date(), // Default date
                        experience: doctor.experience,
                        qualification: doctor.qualifications.joined(separator: ", "),
                        license: doctor.licenseNo,
                        address: doctor.addressLine
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

// MARK: - Doctor Card
struct AdminDoctorCard: View {
    let doctor: UIDoctor
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with name and menu
            HStack(alignment: .top, spacing: 12) {
                // Avatar circle
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Text(doctor.fullName.prefix(1))
                            .font(.title3)
                            .foregroundColor(.cyan)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Name
                    Text(doctor.fullName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // Specialization
                    Text(doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Doctor ID with light blue background
                    Text("ID: \(doctor.id)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundColor(.cyan)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // Menu Button
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
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Contact info
            VStack(alignment: .leading, spacing: 8) {
                // Phone
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.cyan)
                    Text(doctor.phone)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                }
                
                // Email
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.cyan)
                    Text(doctor.email)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
} 

