import SwiftUI
import PDFKit

struct PrescriptionDetailView: View {
    let appointment: Appointment
    @StateObject private var controller = PrescriptionController()
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
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
                                .foregroundColor(.teal.opacity(0.5))
                            
                            Text("No prescription found")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            Text("The prescription details for this appointment are not available")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Prescription Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateAndSharePDF()
                }) {
                    Image(systemName: "arrow.down.doc")
                        .foregroundColor(.teal)
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
            
            Text(hospital.hospitalAddress)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 30) {
                Label(hospital.contactNumber, systemImage: "phone.fill")
                Label(hospital.emergencyContactNumber, systemImage: "cross.case.fill")
            }
            .font(.subheadline)
            .foregroundColor(.teal)
            
            Divider()
            
            HStack(spacing: 20) {
                Text("License No.: \(hospital.licence)")
                Text("Accreditation: \(hospital.hospitalAccreditation)")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func doctorInformationCard(doctor: HospitalDoctor) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Doctor Information")
                .font(.title3)
                .foregroundColor(.teal)
            
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
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func medicationsCard(medications: [MedicationItem]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Medications Header
            HStack {
                Image(systemName: "pills.circle.fill")
                    .foregroundColor(.teal)
                Text("Medications")
                    .font(.title2)
                    .foregroundColor(.teal)
            }
            .padding(.bottom, 5)
            
            // Medications List
            ForEach(medications) { medication in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(medication.medicineName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(medication.dosage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.teal.opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 40) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.gray)
                            Text(medication.frequency)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                            Text(medication.timing)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.gray.opacity(0.1), radius: 5)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
    
    private func labTestsCard(tests: [LabTestItem]?) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Lab Tests Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundColor(.teal)
                Text("Lab Tests")
                    .font(.title2)
                    .foregroundColor(.teal)
            }
            .padding(.bottom, 5)
            
            // Lab Tests List
            if let tests = tests {
                ForEach(tests) { test in
                    HStack {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(.teal)
                        Text(test.testName)
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
    
    private func doctorAdviceCard(precautions: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // Doctor's Advice Header
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(.teal)
                Text("Doctor's Advice")
                    .font(.title2)
                    .foregroundColor(.teal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 5)
            
            // CHANGE: Show both precautions and additional notes with left alignment
            if let prescription = controller.prescription {
                if !precautions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Precautions:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(precautions)
                            .font(.body)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                }
                
                if let additionalNotes = prescription.additionalNotes, !additionalNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                        Text(additionalNotes)
                            .font(.body)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                }
                
                if precautions.isEmpty && (prescription.additionalNotes ?? "").isEmpty {
                    Text("No specific advice given")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func generateAndSharePDF() {
        guard let hospital = controller.hospital,
              let doctor = controller.doctor,
              let prescription = controller.prescription else {
            return
        }
        
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let format = UIGraphicsPDFRendererFormat()
        let metadata = [
            kCGPDFContextCreator: "MediOps",
            kCGPDFContextAuthor: doctor.name
        ]
        format.documentInfo = metadata as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let headerFont = UIFont.boldSystemFont(ofSize: 16.0)
            let regularFont = UIFont.systemFont(ofSize: 12.0)
            
            // Hospital Info
            let hospitalTitle = hospital.hospitalName as NSString
            hospitalTitle.draw(at: CGPoint(x: 50, y: 50), withAttributes: [.font: titleFont])
            
            let hospitalAddress = hospital.hospitalAddress as NSString
            hospitalAddress.draw(at: CGPoint(x: 50, y: 80), withAttributes: [.font: regularFont])
            
            // Doctor Info
            let doctorTitle = "Doctor Information" as NSString
            doctorTitle.draw(at: CGPoint(x: 50, y: 120), withAttributes: [.font: headerFont])
            
            let doctorInfo = """
            Name: \(doctor.name)
            Specialization: \(doctor.specialization)
            Qualification: \(doctor.qualifications.joined(separator: ", "))
            Experience: \(doctor.experience) years
            """ as NSString
            doctorInfo.draw(at: CGPoint(x: 50, y: 150), withAttributes: [.font: regularFont])
            
            // Medications
            let medicationsTitle = "Medications" as NSString
            medicationsTitle.draw(at: CGPoint(x: 50, y: 250), withAttributes: [.font: headerFont])
            
            var yPos = 280.0
            for medication in prescription.medications {
                let medicationText = "\(medication.medicineName): \(medication.dosage) - \(medication.frequency) - \(medication.timing)" as NSString
                medicationText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
                yPos += 20
            }
            
            // Lab Tests
            if let labTests = prescription.labTests {
                let labTestsTitle = "Lab Tests" as NSString
                labTestsTitle.draw(at: CGPoint(x: 50, y: yPos + 20), withAttributes: [.font: headerFont])
                
                yPos += 50
                for test in labTests {
                    let testText = "• \(test.testName)" as NSString
                    testText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
                    yPos += 20
                }
            }
            
            // Precautions
            if let precautions = prescription.precautions {
                let precautionsTitle = "Doctor's Advice" as NSString
                precautionsTitle.draw(at: CGPoint(x: 50, y: yPos + 20), withAttributes: [.font: headerFont])
                
                yPos += 50
                let precautionsText = precautions as NSString
                precautionsText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
            }
        }
        
        showShareSheet = true
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
                .frame(width: 120, alignment: .leading)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
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
