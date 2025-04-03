import SwiftUI
import PDFKit

struct PrescriptionDetailView: View {
    let appointment: Appointment
    @StateObject private var controller = PrescriptionController()
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : Color.teal.opacity(0.1), 
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    if controller.isLoading {
                        ProgressView()
                    } else if let prescription = controller.prescription {
                        if let hospital = controller.hospital {
                            hospitalCard(hospital: hospital)
                        }
                        
                        if let doctor = controller.doctor {
                            doctorInformationCard(doctor: doctor)
                        }
                        
                        medicationsCard(medications: prescription.medications)
                        
                        labTestsCard(tests: prescription.labTests)
                        
                        if let precautions = prescription.precautions {
                            doctorAdviceCard(precautions: precautions)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 50))
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.5) : .teal.opacity(0.5))
                            
                            Text("No prescription found")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            
                            Text("The prescription details for this appointment are not available")
                                .font(.subheadline)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent.opacity(0.8) : .gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Prescription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateAndSharePDF()
                }) {
                    Image(systemName: "arrow.down.doc")
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .task {
            await controller.fetchPrescriptionDetails(for: appointment.id, doctorId: appointment.doctor.id)
        }
    }
    
    private func hospitalCard(hospital: HospitalModel) -> some View {
        VStack(spacing: 12) {
            Text(hospital.hospitalName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
            
            Text(hospital.hospitalAddress)
                .font(.subheadline)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 30) {
                Label(hospital.contactNumber, systemImage: "phone.fill")
                Label(hospital.emergencyContactNumber, systemImage: "cross.case.fill")
            }
            .font(.subheadline)
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            
            ThemedDivider()
            
            HStack(spacing: 20) {
                Text("License No.: \(hospital.licence)")
                Text("Accreditation: \(hospital.hospitalAccreditation)")
            }
            .font(.caption)
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        Color.teal.opacity(0.2), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: themeManager.isPatient ? 
                themeManager.currentTheme.accentColor.opacity(0.15) : 
                .gray.opacity(0.1),
            radius: 5
        )
    }
    
    private func doctorInformationCard(doctor: HospitalDoctor) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Doctor Information")
                .font(.title3)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            
            VStack(spacing: 15) {
                InfoRow(title: "Name", value: doctor.name)
                InfoRow(title: "Specialization", value: doctor.specialization)
                InfoRow(title: "Qualification", value: doctor.qualifications.joined(separator: ", "))
                InfoRow(title: "Experience", value: "\(doctor.experience) years")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        Color.teal.opacity(0.2), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: themeManager.isPatient ? 
                themeManager.currentTheme.accentColor.opacity(0.15) : 
                .gray.opacity(0.1),
            radius: 5
        )
    }
    
    private func medicationsCard(medications: [MedicationItem]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Medications Header
            HStack {
                Image(systemName: "pills.circle.fill")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                Text("Medications")
                    .font(.title2)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            }
            .padding(.bottom, 5)
            
            // Medications List
            ForEach(medications) { medication in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(medication.medicineName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        
                        Spacer()
                        
                        Text(medication.dosage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.8) : Color.teal.opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    ThemedDivider()
                    
                    HStack(spacing: 40) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            Text(medication.frequency)
                                .font(.subheadline)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                            Text(medication.timing)
                                .font(.subheadline)
                                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            themeManager.isPatient ? 
                                themeManager.currentTheme.accentColor.opacity(0.2) : 
                                Color.teal.opacity(0.2), 
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.1) : 
                        Color.gray.opacity(0.1),
                    radius: 5
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        Color.teal.opacity(0.2), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: themeManager.isPatient ? 
                themeManager.currentTheme.accentColor.opacity(0.15) : 
                .gray.opacity(0.1),
            radius: 5
        )
    }
    
    private func labTestsCard(tests: [LabTestItem]?) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Lab Tests Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                Text("Lab Tests")
                    .font(.title2)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            }
            .padding(.bottom, 5)
            
            // Lab Tests List
            if let tests = tests {
                ForEach(tests) { test in
                    HStack {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        Text(test.testName)
                            .font(.body)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        Color.teal.opacity(0.2), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: themeManager.isPatient ? 
                themeManager.currentTheme.accentColor.opacity(0.15) : 
                .gray.opacity(0.1),
            radius: 5
        )
    }
    
    private func doctorAdviceCard(precautions: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Doctor's Advice Header
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                Text("Doctor's Advice")
                    .font(.title2)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
            
            // CHANGE: Show both precautions and additional notes with left alignment
            if let prescription = controller.prescription {
                VStack(alignment: .leading, spacing: 10) {
                    Text(precautions)
                        .font(.body)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let additionalNotes = prescription.additionalNotes, !additionalNotes.isEmpty {
                        ThemedDivider()
                        
                        Text("Additional Notes:")
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        
                        Text(additionalNotes)
                            .font(.body)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    themeManager.isPatient ? 
                        themeManager.currentTheme.accentColor.opacity(0.2) : 
                        Color.teal.opacity(0.2), 
                    lineWidth: 0.5
                )
        )
        .shadow(
            color: themeManager.isPatient ? 
                themeManager.currentTheme.accentColor.opacity(0.15) : 
                .gray.opacity(0.1),
            radius: 5
        )
    }
    
    private func generateAndSharePDF() {
        guard let prescription = controller.prescription,
              let hospital = controller.hospital,
              let doctor = controller.doctor else {
            return
        }
        
        let pdfCreator = PrescriptionPDFGenerator(
            prescription: prescription,
            appointment: appointment,
            hospital: hospital,
            doctor: doctor
        )
        
        if let pdfData = pdfCreator.generatePDF() {
            self.pdfData = pdfData
            self.showShareSheet = true
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.headline)
                .frame(width: 120, alignment: .leading)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .multilineTextAlignment(.trailing)
                .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MedicationData {
    let name: String
    let dosage: String
    let frequency: String
    let duration: String
}

struct LabTestData {
    let test: String
    let reason: String
}

struct HistoryAppointmentData {
    let doctorName: String
    let specialty: String
    let date: String
    let medications: [MedicationData]
    let labTests: [LabTestData]
    let precautions: String
    let additionalNotes: String
}
