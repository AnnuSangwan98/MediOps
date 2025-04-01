//
//  AddDOctorView.swift
//  MediOps
//
//  Created by Sharvan on 21/03/25.
//

import SwiftUI
// QualificationToggle is defined in SharedComponents.swift

struct AddDoctorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var specialization = Specialization.generalMedicine
    @State private var email = ""
    @State private var phoneNumber = "" // This will store only the 10 digits part
    @State private var gender: UIDoctor.Gender = .male
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var experience = 0
    @State private var selectedQualifications: Set<String> = ["MBBS"] // Default to MBBS
    @State private var license = ""
    @State private var address = "" // Added address state
    @State private var pincode = "" // Add pincode field
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    //@State private var doctorid: String = ""
    @State private var password = "" // Added password for account creation
    @State private var selectedWeekdaySlots: Set<String> = []
    @State private var selectedWeekendSlots: Set<String> = []
    @State private var hospitalId: String = ""
    @State private var doctorId: String = "" // Added to store generated doctor ID
    @State private var showSuccessInfo: Bool = false // To control doctor info display
    
    // Add controllers
    private let adminController = AdminController.shared
    private let userController = UserController.shared
    
    var onSave: (UIActivity) -> Void
    
    // New properties to store the initial time slots
    var initialWeekdaySlots: Set<String>
    var initialWeekendSlots: Set<String>
    var isEditMode: Bool
    
    // Initialize with default empty values for new doctor creation
    init(onSave: @escaping (UIActivity) -> Void) {
        self.onSave = onSave
        self.initialWeekdaySlots = []
        self.initialWeekendSlots = []
        self.isEditMode = false
    }
    
    // Initialize with provided time slots for doctor editing
    init(weekdaySlots: Set<String>, weekendSlots: Set<String>, onSave: @escaping (UIActivity) -> Void) {
        self.onSave = onSave
        self.initialWeekdaySlots = weekdaySlots
        self.initialWeekendSlots = weekendSlots
        self.isEditMode = true
        _selectedWeekdaySlots = State(initialValue: weekdaySlots)
        _selectedWeekendSlots = State(initialValue: weekendSlots)
    }
    
    enum Specialization: String, CaseIterable {
        case generalMedicine = "General medicine"
        case orthopaedics = "Orthopaedics"
        case gynaecology = "Gynaecology"
        case cardiology = "Cardiology"
        case pathologyLaboratory = "Pathology & laboratory"
        
        var id: String { self.rawValue }
    }
    
    // Add allowed qualifications
    private let availableQualifications = ["MBBS", "MD", "MS"]
    
    // Calculate maximum experience based on age
    private var maximumExperience: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        let age = ageComponents.year ?? 0
        return max(0, age - 25) // Experience should be 19 years less than doctor's age
    }

    
    // Add computed property to check if form is valid
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !specialization.rawValue.isEmpty &&
        isValidEmail(email) &&
        phoneNumber.count == 10 &&
        !selectedQualifications.isEmpty &&
        isValidLicense(license) &&
        !address.isEmpty &&
        isValidPincode(pincode) && // Add pincode validation
        hasSlotsSelected // At least one slot must be selected
    }
    
    // Check if any slots are selected
    private var hasSlotsSelected: Bool {
        return !selectedWeekdaySlots.isEmpty || !selectedWeekendSlots.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Doctor Information")) {
                    HStack {
                        Text("Doctor ID:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(doctorId)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .onChange(of: fullName) { _, newValue in
                            // Filter out any numbers from the name
                            fullName = newValue.filter { !$0.isNumber }
                        }
                    
                    Picker("Specialization", selection: $specialization) {
                        ForEach(Specialization.allCases, id: \.id) { specialization in
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
                    .onChange(of: dateOfBirth) { _, _ in
                        // Adjust experience if it exceeds the maximum allowed
                        if experience > maximumExperience {
                            experience = maximumExperience
                        }
                    }
                }
                
                Section(header: Text("Professional Information")) {
                    // Qualifications picker
                    VStack(alignment: .leading) {
                        Text("Qualifications")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(availableQualifications, id: \.self) { qualification in
                                    QualificationToggle(
                                        title: qualification,
                                        isSelected: selectedQualifications.contains(qualification),
                                        action: {
                                            if selectedQualifications.contains(qualification) {
                                                selectedQualifications.remove(qualification)
                                            } else {
                                                selectedQualifications.insert(qualification)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        if selectedQualifications.isEmpty {
                            Text("Select at least one qualification")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    // Updated license field with specific format and 7-character limit
                    TextField("License Number (Format: AB12345)", text: $license)
                        .onChange(of: license) { _, newValue in
                            // Format license to uppercase and limit to 7 characters
                            let uppercased = newValue.uppercased()
                            if uppercased.count > 7 {
                                license = String(uppercased.prefix(7))
                            } else {
                                license = uppercased
                            }
                        }
                    
                    Stepper("Experience: \(experience) years", value: $experience, in: 0...maximumExperience)
                        .onChange(of: experience) { _, newValue in
                            // Enforce the maximum experience constraint
                            if newValue > maximumExperience {
                                experience = maximumExperience
                            }
                        }
                }
                
                Section(header: Text("Availability Schedule")) {
                    VStack(alignment: .leading, spacing: 15) {
                        // Weekdays (MON-FRI) Section
                        Group {
                            Text("Weekdays (MON-FRI)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 5)
                            
                            // Early morning slots (6 AM - 12 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "06:00-07:00", isSelected: selectedWeekdaySlots.contains("06:00-07:00"), isWeekend: false) {
                                            toggleSlot("06:00-07:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "07:00-08:00", isSelected: selectedWeekdaySlots.contains("07:00-08:00"), isWeekend: false) {
                                            toggleSlot("07:00-08:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "08:00-09:00", isSelected: selectedWeekdaySlots.contains("08:00-09:00"), isWeekend: false) {
                                            toggleSlot("08:00-09:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "09:00-10:00", isSelected: selectedWeekdaySlots.contains("09:00-10:00"), isWeekend: false) {
                                            toggleSlot("09:00-10:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Morning slots (10 AM - 2 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekdaySlots.contains("10:00-11:00"), isWeekend: false) {
                                            toggleSlot("10:00-11:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekdaySlots.contains("11:00-12:00"), isWeekend: false) {
                                            toggleSlot("11:00-12:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "12:00-13:00", isSelected: selectedWeekdaySlots.contains("12:00-13:00"), isWeekend: false) {
                                            toggleSlot("12:00-13:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "13:00-14:00", isSelected: selectedWeekdaySlots.contains("13:00-14:00"), isWeekend: false) {
                                            toggleSlot("13:00-14:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Afternoon slots (2 PM - 6 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "14:00-15:00", isSelected: selectedWeekdaySlots.contains("14:00-15:00"), isWeekend: false) {
                                            toggleSlot("14:00-15:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "15:00-16:00", isSelected: selectedWeekdaySlots.contains("15:00-16:00"), isWeekend: false) {
                                            toggleSlot("15:00-16:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "16:00-17:00", isSelected: selectedWeekdaySlots.contains("16:00-17:00"), isWeekend: false) {
                                            toggleSlot("16:00-17:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "17:00-18:00", isSelected: selectedWeekdaySlots.contains("17:00-18:00"), isWeekend: false) {
                                            toggleSlot("17:00-18:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Evening slots (6 PM - 10 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "18:00-19:00", isSelected: selectedWeekdaySlots.contains("18:00-19:00"), isWeekend: false) {
                                            toggleSlot("18:00-19:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "19:00-20:00", isSelected: selectedWeekdaySlots.contains("19:00-20:00"), isWeekend: false) {
                                            toggleSlot("19:00-20:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "20:00-21:00", isSelected: selectedWeekdaySlots.contains("20:00-21:00"), isWeekend: false) {
                                            toggleSlot("20:00-21:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "21:00-22:00", isSelected: selectedWeekdaySlots.contains("21:00-22:00"), isWeekend: false) {
                                            toggleSlot("21:00-22:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Night slots (10 PM - 2 AM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "22:00-23:00", isSelected: selectedWeekdaySlots.contains("22:00-23:00"), isWeekend: false) {
                                            toggleSlot("22:00-23:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "23:00-00:00", isSelected: selectedWeekdaySlots.contains("23:00-00:00"), isWeekend: false) {
                                            toggleSlot("23:00-00:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "00:00-01:00", isSelected: selectedWeekdaySlots.contains("00:00-01:00"), isWeekend: false) {
                                            toggleSlot("00:00-01:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "01:00-02:00", isSelected: selectedWeekdaySlots.contains("01:00-02:00"), isWeekend: false) {
                                            toggleSlot("01:00-02:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                            
                            // Late night slots (2 AM - 6 AM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "02:00-03:00", isSelected: selectedWeekdaySlots.contains("02:00-03:00"), isWeekend: false) {
                                            toggleSlot("02:00-03:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "03:00-04:00", isSelected: selectedWeekdaySlots.contains("03:00-04:00"), isWeekend: false) {
                                            toggleSlot("03:00-04:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "04:00-05:00", isSelected: selectedWeekdaySlots.contains("04:00-05:00"), isWeekend: false) {
                                            toggleSlot("04:00-05:00", in: &selectedWeekdaySlots)
                                        }
                                        
                                        TimeSlotButton(time: "05:00-06:00", isSelected: selectedWeekdaySlots.contains("05:00-06:00"), isWeekend: false) {
                                            toggleSlot("05:00-06:00", in: &selectedWeekdaySlots)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                        
                        // Weekend section (SAT-SUN)
                        Group {
                            Text("Weekends (SAT-SUN)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 5)
                            
                            // Early morning slots (6 AM - 12 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "06:00-07:00", isSelected: selectedWeekendSlots.contains("06:00-07:00"), isWeekend: true) {
                                            toggleSlot("06:00-07:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "07:00-08:00", isSelected: selectedWeekendSlots.contains("07:00-08:00"), isWeekend: true) {
                                            toggleSlot("07:00-08:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "08:00-09:00", isSelected: selectedWeekendSlots.contains("08:00-09:00"), isWeekend: true) {
                                            toggleSlot("08:00-09:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "09:00-10:00", isSelected: selectedWeekendSlots.contains("09:00-10:00"), isWeekend: true) {
                                            toggleSlot("09:00-10:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Morning slots (10 AM - 2 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "10:00-11:00", isSelected: selectedWeekendSlots.contains("10:00-11:00"), isWeekend: true) {
                                            toggleSlot("10:00-11:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "11:00-12:00", isSelected: selectedWeekendSlots.contains("11:00-12:00"), isWeekend: true) {
                                            toggleSlot("11:00-12:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "12:00-13:00", isSelected: selectedWeekendSlots.contains("12:00-13:00"), isWeekend: true) {
                                            toggleSlot("12:00-13:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "13:00-14:00", isSelected: selectedWeekendSlots.contains("13:00-14:00"), isWeekend: true) {
                                            toggleSlot("13:00-14:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Afternoon slots (2 PM - 6 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "14:00-15:00", isSelected: selectedWeekendSlots.contains("14:00-15:00"), isWeekend: true) {
                                            toggleSlot("14:00-15:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "15:00-16:00", isSelected: selectedWeekendSlots.contains("15:00-16:00"), isWeekend: true) {
                                            toggleSlot("15:00-16:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "16:00-17:00", isSelected: selectedWeekendSlots.contains("16:00-17:00"), isWeekend: true) {
                                            toggleSlot("16:00-17:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "17:00-18:00", isSelected: selectedWeekendSlots.contains("17:00-18:00"), isWeekend: true) {
                                            toggleSlot("17:00-18:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Evening slots (6 PM - 10 PM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "18:00-19:00", isSelected: selectedWeekendSlots.contains("18:00-19:00"), isWeekend: true) {
                                            toggleSlot("18:00-19:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "19:00-20:00", isSelected: selectedWeekendSlots.contains("19:00-20:00"), isWeekend: true) {
                                            toggleSlot("19:00-20:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "20:00-21:00", isSelected: selectedWeekendSlots.contains("20:00-21:00"), isWeekend: true) {
                                            toggleSlot("20:00-21:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "21:00-22:00", isSelected: selectedWeekendSlots.contains("21:00-22:00"), isWeekend: true) {
                                            toggleSlot("21:00-22:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Night slots (10 PM - 2 AM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "22:00-23:00", isSelected: selectedWeekendSlots.contains("22:00-23:00"), isWeekend: true) {
                                            toggleSlot("22:00-23:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "23:00-00:00", isSelected: selectedWeekendSlots.contains("23:00-00:00"), isWeekend: true) {
                                            toggleSlot("23:00-00:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "00:00-01:00", isSelected: selectedWeekendSlots.contains("00:00-01:00"), isWeekend: true) {
                                            toggleSlot("00:00-01:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "01:00-02:00", isSelected: selectedWeekendSlots.contains("01:00-02:00"), isWeekend: true) {
                                            toggleSlot("01:00-02:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                            
                            // Late night slots (2 AM - 6 AM)
                            HStack {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        TimeSlotButton(time: "02:00-03:00", isSelected: selectedWeekendSlots.contains("02:00-03:00"), isWeekend: true) {
                                            toggleSlot("02:00-03:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "03:00-04:00", isSelected: selectedWeekendSlots.contains("03:00-04:00"), isWeekend: true) {
                                            toggleSlot("03:00-04:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "04:00-05:00", isSelected: selectedWeekendSlots.contains("04:00-05:00"), isWeekend: true) {
                                            toggleSlot("04:00-05:00", in: &selectedWeekendSlots)
                                        }
                                        
                                        TimeSlotButton(time: "05:00-06:00", isSelected: selectedWeekendSlots.contains("05:00-06:00"), isWeekend: true) {
                                            toggleSlot("05:00-06:00", in: &selectedWeekendSlots)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(10)
                        
                        // Add validation message if no slots selected
                        if selectedWeekdaySlots.isEmpty && selectedWeekendSlots.isEmpty {
                            Text("Please select at least one availability slot")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Updated phone field with prefix
                    HStack {
                        Text("+91")
                            .foregroundColor(.gray)
                        TextField("10-digit Phone Number", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: phoneNumber) { _, newValue in
                                // Keep only digits and limit to 10
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    phoneNumber = String(filtered.prefix(10))
                                } else {
                                    phoneNumber = filtered
                                }
                            }
                    }
                    
                    // Changed to TextField for address
                    TextField("Address", text: $address)
                    
                    // Add pincode field with validation
                    TextField("Pincode (6 digits)", text: $pincode)
                        .keyboardType(.numberPad)
                        .onChange(of: pincode) { _, newValue in
                            // Keep only digits and limit to 6
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered.count > 6 {
                                pincode = String(filtered.prefix(6))
                            } else {
                                pincode = filtered
                            }
                        }
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        isLoading = true
                        Task {
                            await saveDoctor()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                // Load the hospital ID when the view appears
                if let id = UserDefaults.standard.string(forKey: "hospital_id") {
                    hospitalId = id
                    print("Loaded hospital ID: \(id)")
                } else {
                    print("Warning: No hospital ID found in UserDefaults")
                }
                
                // Generate initial password when view appears
                password = generateSecurePassword()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertMessage.starts(with: "Doctor added") ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if !errorMessage.isEmpty {
                            isLoading = false
                        } else if alertMessage.starts(with: "Doctor added") {
                            dismiss()
                        }
                    }
                )
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
        }
    }
    
    private func saveDoctor() async {
        isLoading = true
        
        // Generate a secure password that meets the Supabase constraints
        let securePassword = generateSecurePassword()
        
        Task {
            do {
                // Get hospital ID from UserDefaults
                guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
                    await MainActor.run {
                        alertMessage = "Failed to create doctor: Hospital ID not found. Please login again."
                        showAlert = true
                        isLoading = false
                    }
                    return
                }
                
                self.hospitalId = hospitalId // Update the state variable
                
                print("SAVE DOCTOR: Using hospital ID from UserDefaults: \(hospitalId)")
                
                // Prepare the doctor data
                print("🔄 Creating doctor with email: \(email)")
                let (doctor, _) = try await adminController.createDoctor(
                    email: email,
                    password: securePassword,
                    name: fullName,
                    specialization: specialization.rawValue,
                    hospitalId: hospitalId,
                    qualifications: Array(selectedQualifications),
                    licenseNo: license,
                    experience: experience,
                    addressLine: address,
                    state: "", // Add these fields if needed
                    city: "",
                    pincode: pincode,
                    contactNumber: phoneNumber
                )
                
                print("✅ Doctor created successfully with ID: \(doctor.id)")
                
                // Store the generated doctor ID
                await MainActor.run {
                    self.doctorId = doctor.id
                }
                
                // Save the selected time slots to UserDefaults
                if !doctor.id.isEmpty {
                    saveTimeSlots(doctorId: doctor.id)
                }
                
                // Verify we have a valid doctor ID
                guard !doctor.id.isEmpty else {
                    throw NSError(domain: "AddDoctorView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Doctor was created but no ID was returned"])
                }
                
                // Create doctor schedule using JSON approach
                print("🕒 Creating doctor schedule with \(selectedWeekdaySlots.count) weekday slots and \(selectedWeekendSlots.count) weekend slots for doctor ID: \(doctor.id)")
                
                do {
                    // Create a complete weekly schedule at once
                    try await adminController.addDoctorSchedule(
                        doctorId: doctor.id,
                        hospitalId: hospitalId,
                        weekdaySlots: selectedWeekdaySlots,
                        weekendSlots: selectedWeekendSlots
                    )
                    print("✅ Successfully created doctor schedule")
                } catch {
                    print("⚠️ Failed to create doctor schedule: \(error.localizedDescription)")
                    // Continue anyway since the doctor was created
                }
                
                // Send credentials to the doctor
                await sendDoctorCredentials(email: email, password: securePassword)
                
                // Create a doctor record for the UI
                let uiDoctor = UIDoctor(
                    id: doctor.id,
                    fullName: doctor.name,
                    specialization: doctor.specialization,
                    email: doctor.email,
                    phone: "+91\(phoneNumber)",
                    gender: gender,
                    dateOfBirth: dateOfBirth,
                    experience: experience,
                    qualification: selectedQualifications.joined(separator: ", "),
                    license: license,
                    address: address
                )
                
                // Create an activity for the new doctor
                let activity = UIActivity(
                    id: UUID(),
                    type: .doctorAdded,
                    title: "Added new doctor: \(fullName)",
                    timestamp: Date(),
                    status: .completed,
                    doctorDetails: uiDoctor,
                    labAdminDetails: nil,
                    hospitalDetails: nil
                )
                
                await MainActor.run {
                    showSuccessInfo = true // Show the doctor info section
                    onSave(activity)
                    isLoading = false
                    alertMessage = "Doctor added successfully with ID: \(doctor.id). Availability schedule has been created."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to create doctor: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    // Generate a password that meets the Supabase constraints:
    // - At least 8 characters
    // - At least one uppercase letter
    // - At least one lowercase letter
    // - At least one digit
    // - At least one special character (@$!%*?&)
    private func generateSecurePassword() -> String {
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let specialChars = "@$!%*?&"
        
        // Ensure at least one character from each required category
        var passwordChars: [String] = []
        passwordChars.append(String(uppercaseLetters.randomElement()!))
        passwordChars.append(String(lowercaseLetters.randomElement()!))
        passwordChars.append(String(numbers.randomElement()!))
        passwordChars.append(String(specialChars.randomElement()!))
        
        // Add more random characters to reach at least 8 characters
        let allChars = uppercaseLetters + lowercaseLetters + numbers + specialChars
        let additionalLength = 8 // Will give us a 12-character password
        
        for _ in 0..<additionalLength {
            passwordChars.append(String(allChars.randomElement()!))
        }
        
        // Shuffle and join the characters
        return passwordChars.shuffled().joined()
    }
    
    private func sendDoctorCredentials(email: String, password: String) async {
        guard let url = URL(string: "http://192.168.182.100:8082/send-credentials") else {
            await MainActor.run {
                alertMessage = "Invalid server URL"
                showAlert = true
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60  // Increased timeout to 60 seconds
        
        let emailData: [String: Any] = [
            "to": email,
            "accountType": "doctor",
            "details": [
                "fullName": fullName,
                "specialization": specialization.rawValue,
                "license": license,
                "phone": "+91\(phoneNumber)",
                "qualification": selectedQualifications.joined(separator: ", "),
                "experience": experience,
                "password": password // Include the password in the email
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Credentials email sent successfully")
                } else {
                    await MainActor.run {
                        alertMessage = "Doctor created successfully but failed to send credentials email (Status: \(httpResponse.statusCode))"
                        showAlert = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "Doctor created successfully but failed to send credentials email: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func resetForm() {
        // Don't reset doctorId or showSuccessInfo to keep displaying doctor info
        fullName = ""
        specialization = Specialization.generalMedicine
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = ["MBBS"]
        license = ""
        address = "" // Reset address
        pincode = "" // Reset pincode
        password = generateSecurePassword() // Generate new password
        selectedWeekdaySlots = []
        selectedWeekendSlots = []
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidLicense(_ license: String) -> Bool {
        // Format AB12345: 2 letters followed by 5 digits
        let licenseRegex = #"^[A-Z]{2}\d{5}$"#
        return license.count == 7 && NSPredicate(format: "SELF MATCHES %@", licenseRegex).evaluate(with: license)
    }
    
    // Add validation for pincode (must be exactly 6 digits)
    private func isValidPincode(_ pincode: String) -> Bool {
        let pincodeRegex = #"^[0-9]{6}$"#
        return NSPredicate(format: "SELF MATCHES %@", pincodeRegex).evaluate(with: pincode)
    }
    
    private func toggleSlot(_ time: String, in slots: inout Set<String>) {
        if slots.contains(time) {
            slots.remove(time)
        } else {
            slots.insert(time)
        }
    }
    
    private func createTimeFromString(_ timeString: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Clean up the input time string
        let cleanedTimeString = timeString.trimmingCharacters(in: .whitespaces)
        print("🔍 Processing time string: '\(cleanedTimeString)'")
        
        // Extract hours and minutes
        var hour = 0
        var minute = 0
        
        // Try different parsing approaches for maximum flexibility
        if cleanedTimeString.contains(":") {
            // Format like "9:00" or "10:00"
            let components = cleanedTimeString.components(separatedBy: ":")
            if components.count >= 2,
               let parsedHour = Int(components[0].trimmingCharacters(in: .whitespaces)),
               let parsedMinute = Int(components[1].trimmingCharacters(in: .whitespaces)) {
                hour = parsedHour
                minute = parsedMinute
                print("✅ Parsed time from colon format: \(hour):\(minute)")
            } else {
                print("❌ Failed to parse time with colon: \(cleanedTimeString)")
                return nil
            }
        } else {
            // Try to extract numeric values for hour
            let hourString = cleanedTimeString.prefix(while: { $0.isNumber })
            if let parsedHour = Int(hourString) {
                hour = parsedHour
                minute = 0 // Default minutes to 0
                print("✅ Parsed hour from numeric prefix: \(hour)")
            } else {
                print("❌ Failed to parse hour from string: \(cleanedTimeString)")
                return nil
            }
        }
        
        // Create a date with the specified hour and minute
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        
        guard let result = calendar.date(from: dateComponents) else {
            print("❌ Failed to create date from components: \(dateComponents)")
            return nil
        }
        
        print("✅ Successfully created time: \(result)")
        return result
    }
    
    // Add a test function for availability insertion
    private func testAvailabilityInsertion() async {
        guard !hospitalId.isEmpty, !doctorId.isEmpty else {
            print("❌ Missing hospital ID or doctor ID for test")
            return
        }
        
        print("🔍 Testing schedule insertion with Doctor ID: \(doctorId) and Hospital ID: \(hospitalId)")
        
        // Create test slots
        let morningSlots: Set<String> = ["09:00-10:00", "10:00-11:00"]
        let eveningSlots: Set<String> = ["16:00-17:00"]
        
        do {
            print("🔄 Adding test schedule")
            try await adminController.addDoctorSchedule(
                doctorId: doctorId,
                hospitalId: hospitalId,
                weekdaySlots: morningSlots,
                weekendSlots: eveningSlots
            )
            
            await MainActor.run {
                alertMessage = "Test schedule created successfully!"
                showAlert = true
            }
        } catch {
            print("❌ Test schedule creation failed: \(error.localizedDescription)")
            
            await MainActor.run {
                alertMessage = "Test schedule creation failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    // Add a function to reset the form for a new doctor while preserving hospital ID
    private func resetFormForNewDoctor() {
        fullName = ""
        specialization = Specialization.generalMedicine
        email = ""
        phoneNumber = ""
        gender = .male
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        experience = 0
        selectedQualifications = ["MBBS"]
        license = ""
        address = ""
        pincode = ""
        password = generateSecurePassword() 
        selectedWeekdaySlots = []
        selectedWeekendSlots = []
        
        // Reset doctor information but keep hospital ID
        doctorId = ""
        showSuccessInfo = false
    }
    
    // New helper function to save time slots to UserDefaults
    private func saveTimeSlots(doctorId: String) {
        let weekdaySlotsArray = Array(selectedWeekdaySlots)
        let weekendSlotsArray = Array(selectedWeekendSlots)
        
        if let weekdayData = try? JSONEncoder().encode(weekdaySlotsArray) {
            UserDefaults.standard.set(weekdayData, forKey: "doctor_\(doctorId)_weekday_slots")
        }
        
        if let weekendData = try? JSONEncoder().encode(weekendSlotsArray) {
            UserDefaults.standard.set(weekendData, forKey: "doctor_\(doctorId)_weekend_slots")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    // New helper function to load time slots from UserDefaults
    static func loadTimeSlots(doctorId: String) -> (weekday: Set<String>, weekend: Set<String>) {
        var weekdaySlots: Set<String> = []
        var weekendSlots: Set<String> = []
        
        if let weekdayData = UserDefaults.standard.data(forKey: "doctor_\(doctorId)_weekday_slots"),
           let weekdayArray = try? JSONDecoder().decode([String].self, from: weekdayData) {
            weekdaySlots = Set(weekdayArray)
        }
        
        if let weekendData = UserDefaults.standard.data(forKey: "doctor_\(doctorId)_weekend_slots"),
           let weekendArray = try? JSONDecoder().decode([String].self, from: weekendData) {
            weekendSlots = Set(weekendArray)
        }
        
        return (weekdaySlots, weekendSlots)
    }
}

// Time Slot Button Component
struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    let isWeekend: Bool
    
    // Initialize with default isWeekend = false
    init(time: String, isSelected: Bool, isWeekend: Bool = false, action: @escaping () -> Void) {
        self.time = time
        self.isSelected = isSelected
        self.isWeekend = isWeekend
        self.action = action
    }
    
    // This is a custom button for time slots with better styling
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(minWidth: 120)
                .background(
                    isSelected 
                    ? (isWeekend ? Color.blue : Color.blue)
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected 
                            ? (isWeekend ? Color.blue : Color.blue) 
                            : Color.gray.opacity(0.3), 
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// QualificationToggle has been moved to SharedComponents.swift

// Added an extension to support initializing the view with an existing UIDoctor
extension AddDoctorView {
    static func forEditing(doctor: UIDoctor, onSave: @escaping (UIActivity) -> Void) -> AddDoctorView {
        // Load saved time slots for this doctor
        let (weekdaySlots, weekendSlots) = loadTimeSlots(doctorId: doctor.id)
        
        // Create a new instance with the loaded time slots
        var view = AddDoctorView(weekdaySlots: weekdaySlots, weekendSlots: weekendSlots, onSave: onSave)
        
        // Initialize other fields with the doctor's existing data
        view.doctorId = doctor.id
        view.fullName = doctor.fullName
        view.specialization = Specialization.allCases.first(where: { $0.rawValue == doctor.specialization }) ?? .generalMedicine
        view.email = doctor.email
        view.phoneNumber = doctor.phone.replacingOccurrences(of: "+91", with: "")
        view.gender = doctor.gender
        view.dateOfBirth = doctor.dateOfBirth
        view.experience = doctor.experience
        view.selectedQualifications = Set(doctor.qualification.components(separatedBy: ", "))
        view.license = doctor.license
        view.address = doctor.address
        
        // Load time slots from Supabase when opening edit form
        Task {
            do {
                if let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") {
                    // Create a local function that explicitly calls the AdminController implementation
                    func getAdminControllerSchedule(doctorId: String, hospitalId: String) async throws -> (weekdaySlots: Set<String>, weekendSlots: Set<String>) {
                        return try await AdminController.shared.getDoctorSchedule(doctorId: doctorId, hospitalId: hospitalId)
                    }
                    
                    // Call our local function that has no ambiguity
                    let slots = try await getAdminControllerSchedule(doctorId: doctor.id, hospitalId: hospitalId)
                    
                    await MainActor.run {
                        view.selectedWeekdaySlots = Set(slots.weekdaySlots)
                        view.selectedWeekendSlots = Set(slots.weekendSlots)
                        
                        // Also update UserDefaults to keep them in sync
                        view.saveTimeSlots(doctorId: doctor.id)
                    }
                }
            } catch {
                print("Error loading doctor schedule from Supabase: \(error)")
                // Fallback to UserDefaults data which was already loaded
            }
        }
        
        return view
    }
}

// Add this extension to the AdminController to fetch doctor schedule from Supabase
extension AdminController {
    func getDoctorSchedule(doctorId: String, hospitalId: String) async throws -> (weekdaySlots: [String], weekendSlots: [String]) {
        guard let url = URL(string: "\(self.supabaseURL)/rest/v1/api/doctor/schedule?doctorId=\(doctorId)&hospitalId=\(hospitalId)") else {
            throw NSError(domain: "AdminController", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use the supabase anon key for authorization
        request.setValue(self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(self.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AdminController", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to fetch doctor schedule"])
        }
        
        struct ScheduleResponse: Codable {
            let weekdaySlots: [String]
            let weekendSlots: [String]
        }
        
        let decoder = JSONDecoder()
        let scheduleResponse = try decoder.decode(ScheduleResponse.self, from: data)
        
        return (scheduleResponse.weekdaySlots, scheduleResponse.weekendSlots)
    }
}
