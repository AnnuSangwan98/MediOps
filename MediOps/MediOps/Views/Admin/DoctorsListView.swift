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
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.teal)
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .gray.opacity(0.2), radius: 3)
                    }
                    
                    Spacer()
                    
                    Text("Doctors")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Refresh button
                    Button(action: { 
                        Task {
                            await fetchDoctors()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.teal)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Status bar
                if !doctors.isEmpty {
                    HStack {
                        Text("\(doctors.count) doctor\(doctors.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Doctors List
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading doctors...")
                                .padding(.top, 40)
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
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text(doctorToDelete != nil ? "Deleting \(doctorToDelete!.fullName)..." : "Loading...")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        .padding(25)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    )
                    .allowsHitTesting(true)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            Button("Cancel", role: .cancel) {
                doctorToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let doctor = doctorToDelete {
                    confirmDeleteDoctor(doctor)
                }
            }
        } message: {
            if let doctor = doctorToDelete {
                Text("Are you sure you want to delete \(doctor.fullName)?\n\nEmail: \(doctor.email)\n\nThis action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this doctor? This action cannot be undone.")
            }
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
                        gender: .male,
                        dateOfBirth: doctor.dateOfBirth ?? Date(),
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
                    doctorToDelete = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete doctor: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                    doctorToDelete = nil
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
        VStack(alignment: .leading, spacing: 12) {
            // Doctor header with avatar
            HStack(spacing: 12) {
                // Avatar/Icon
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "stethoscope")
                        .font(.system(size: 22))
                        .foregroundColor(.teal)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.fullName)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action buttons with clear icons
                HStack(spacing: 12) {
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Edit \(doctor.fullName)")
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Delete \(doctor.fullName)")
                }
            }
            
            Divider()
            
            // Contact information
            VStack(spacing: 8) {
                HStack {
                    Label {
                        Text(doctor.email)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 12))
                    }
                    Spacer()
                }
                
                HStack {
                    Label {
                        Text(doctor.phone.isEmpty ? "No phone" : doctor.phone)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } icon: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 12))
                    }
                    Spacer()
                }
                
                if !doctor.address.isEmpty {
                    HStack {
                        Label {
                            Text(doctor.address)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } icon: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.teal)
                                .font(.system(size: 12))
                        }
                        Spacer()
                    }
                }
            }
            
            // License display
            HStack {
                Spacer()
                Text("License: \(doctor.license)")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 

