import SwiftUI

struct EditDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var specialization: AddDoctorView.Specialization
    @State private var email: String
    @State private var phoneNumber: String
    @State private var gender: UIDoctor.Gender
    @State private var dateOfBirth: Date
    @State private var experience: Int
    @State private var qualification: String
    @State private var license: String
    @State private var address: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var hospitalId = UserDefaults.standard.string(forKey: "hospital_id") ?? ""
    
    // Doctor availability slots
    @State private var selectedWeekdaySlots: Set<String> = []
    @State private var selectedWeekendSlots: Set<String> = []
    @State private var isLoadingSlots = false
    @State private var availabilityError = ""
    
    // Add reference to AdminController
    private let adminController = AdminController.shared
    
    let doctor: UIDoctor
    let onUpdate: (UIDoctor) -> Void
    
    init(doctor: UIDoctor, onUpdate: @escaping (UIDoctor) -> Void) {
        self.doctor = doctor
        self.onUpdate = onUpdate
        
        // Initialize state variables with doctor's current data
        _fullName = State(initialValue: doctor.fullName)
        _specialization = State(initialValue: AddDoctorView.Specialization.allCases.first(where: { $0.rawValue == doctor.specialization }) ?? .generalMedicine)
        _email = State(initialValue: doctor.email)
        _phoneNumber = State(initialValue: doctor.phone.replacingOccurrences(of: "+91", with: ""))
        _gender = State(initialValue: doctor.gender)
        _dateOfBirth = State(initialValue: doctor.dateOfBirth)
        _experience = State(initialValue: doctor.experience)
        _qualification = State(initialValue: doctor.qualification)
        _license = State(initialValue: doctor.license)
        _address = State(initialValue: doctor.address)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !specialization.rawValue.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !qualification.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Doctor Information")) {
                    HStack {
                        Text("Doctor ID:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(doctor.id)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    Picker("Specialization", selection: $specialization) {
                        ForEach(AddDoctorView.Specialization.allCases, id: \.id) { specialization in
                            Text(specialization.rawValue)
                                .tag(specialization)
                        }
                    }
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(UIDoctor.Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth",
                              selection: $dateOfBirth,
                              in: ...Date(),
                              displayedComponents: .date)
                }
                
                Section(header: Text("Professional Information")) {
                    TextField("Qualification", text: $qualification)
                    
                    TextField("License Number", text: $license)
                        .onChange(of: license) { _, newValue in
                            license = newValue.uppercased()
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    TextField("Address", text: $address)
                }
                
                // Availability Schedule Section
                Section(header: HStack {
                    Text("Availability Schedule")
                    Spacer()
                    if isLoadingSlots {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }) {
                    if !availabilityError.isEmpty {
                        Text(availabilityError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Weekday slots
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekday Slots (MON-FRI)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 5)
                        
                        // Morning slots
                        HStack {
                            Text("Morning")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "9:00-10:00", isSelected: selectedWeekdaySlots.contains("9:00-10:00"), isWeekend: false) {
                                        toggleSlot("9:00-10:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekdaySlots.contains("10:00-11:00"), isWeekend: false) {
                                        toggleSlot("10:00-11:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekdaySlots.contains("11:00-12:00"), isWeekend: false) {
                                        toggleSlot("11:00-12:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots
                        HStack {
                            Text("Afternoon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "1:00-2:00", isSelected: selectedWeekdaySlots.contains("1:00-2:00"), isWeekend: false) {
                                        toggleSlot("1:00-2:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "2:00-3:00", isSelected: selectedWeekdaySlots.contains("2:00-3:00"), isWeekend: false) {
                                        toggleSlot("2:00-3:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "3:00-4:00", isSelected: selectedWeekdaySlots.contains("3:00-4:00"), isWeekend: false) {
                                        toggleSlot("3:00-4:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                        
                        // Evening slots
                        HStack {
                            Text("Evening")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "4:00-5:00", isSelected: selectedWeekdaySlots.contains("4:00-5:00"), isWeekend: false) {
                                        toggleSlot("4:00-5:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "5:00-6:00", isSelected: selectedWeekdaySlots.contains("5:00-6:00"), isWeekend: false) {
                                        toggleSlot("5:00-6:00", in: &selectedWeekdaySlots)
                                    }
                                    
                                    TimeSlotButton(time: "6:00-7:00", isSelected: selectedWeekdaySlots.contains("6:00-7:00"), isWeekend: false) {
                                        toggleSlot("6:00-7:00", in: &selectedWeekdaySlots)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Divider()
                    
                    // Weekend slots
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weekend Slots (SAT-SUN)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 5)
                        
                        // Morning slots
                        HStack {
                            Text("Morning")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "9:00-10:00", isSelected: selectedWeekendSlots.contains("9:00-10:00"), isWeekend: true) {
                                        toggleSlot("9:00-10:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekendSlots.contains("10:00-11:00"), isWeekend: true) {
                                        toggleSlot("10:00-11:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekendSlots.contains("11:00-12:00"), isWeekend: true) {
                                        toggleSlot("11:00-12:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                        
                        // Afternoon slots
                        HStack {
                            Text("Afternoon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TimeSlotButton(time: "1:00-2:00", isSelected: selectedWeekendSlots.contains("1:00-2:00"), isWeekend: true) {
                                        toggleSlot("1:00-2:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "2:00-3:00", isSelected: selectedWeekendSlots.contains("2:00-3:00"), isWeekend: true) {
                                        toggleSlot("2:00-3:00", in: &selectedWeekendSlots)
                                    }
                                    
                                    TimeSlotButton(time: "3:00-4:00", isSelected: selectedWeekendSlots.contains("3:00-4:00"), isWeekend: true) {
                                        toggleSlot("3:00-4:00", in: &selectedWeekendSlots)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Edit Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateDoctor()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                // Fetch doctor's availability schedule when the view appears
                fetchDoctorSchedule()
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25)
    }
    
    private func fetchDoctorSchedule() {
        isLoadingSlots = true
        availabilityError = ""
        
        Task {
            do {
                let (weekdaySlots, weekendSlots) = try await adminController.getDoctorSchedule(
                    doctorId: doctor.id, 
                    hospitalId: hospitalId
                )
                
                await MainActor.run {
                    self.selectedWeekdaySlots = weekdaySlots
                    self.selectedWeekendSlots = weekendSlots
                    isLoadingSlots = false
                }
            } catch {
                await MainActor.run {
                    availabilityError = "Could not load availability: \(error.localizedDescription)"
                    isLoadingSlots = false
                }
            }
        }
    }
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        if slots.contains(time) {
            slots.remove(time)
        } else {
            slots.insert(time)
        }
    }
    
    private func updateDoctor() {
        isLoading = true
        
        // Create the updated UIDoctor object for the UI
        let updatedDoctor = UIDoctor(
            id: doctor.id,
            fullName: fullName,
            specialization: specialization.rawValue,
            email: email,
            phone: "+91\(phoneNumber)",
            gender: gender,
            dateOfBirth: dateOfBirth,
            experience: experience,
            qualification: qualification,
            license: license,
            address: address
        )
        
        // Save to Supabase
        Task {
            do {
                // Parse qualifications from comma-separated string to array
                let qualificationsArray = qualification.split(separator: ",").map { 
                    String($0.trimmingCharacters(in: .whitespaces)) 
                }
                
                // Update doctor in Supabase
                try await adminController.updateDoctor(
                    doctorId: doctor.id, 
                    name: fullName,
                    specialization: specialization.rawValue,
                    qualifications: qualificationsArray,
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    email: email,
                    contactNumber: phoneNumber
                )
                
                // Update the doctor's availability schedule
                try await adminController.updateDoctorSchedule(
                    doctorId: doctor.id,
                    hospitalId: hospitalId,
                    weekdaySlots: selectedWeekdaySlots,
                    weekendSlots: selectedWeekendSlots
                )
                
                // Update UI on success
                await MainActor.run {
                    // Call the update callback
                    onUpdate(updatedDoctor)
                    
                    // Show success message
                    alertMessage = "Doctor information and availability updated successfully"
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to update doctor: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
}

// Time Slot Button Component is already defined in AddDoctorView.swift 