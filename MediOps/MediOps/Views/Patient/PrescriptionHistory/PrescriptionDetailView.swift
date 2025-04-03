import SwiftUI
import PDFKit

struct PrescriptionDetailView: View {
    let appointment: Appointment
    @StateObject private var controller = PrescriptionController()
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if controller.isLoading {
                    ProgressView()
                } else if let prescription = controller.prescription {
                    // Hospital Card
                    if let hospital = controller.hospital {
                        hospitalCard(hospital: hospital)
                    }
                    
                    // Doctor Information
                    if let doctor = controller.doctor {
                        doctorInformationCard(doctor: doctor)
                    }
                    
                    // Medications
                    medicationsCard(medications: prescription.medications)
                    
                    // Lab Tests
                    if let labTests = prescription.labTests {
                        labTestsCard(tests: labTests)
                    }
                    
                    // Doctor's Advice
                    if let precautions = prescription.precautions {
                        doctorAdviceCard(precautions: precautions)
                    }
                    
                    // Signature Section
                    signatureSection
                } else {
                    Text("No prescription found")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("Prescription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
            
            // Draw content
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
            for (name, details) in prescription.medications {
                let medicationText = "\(name): \(details)" as NSString
                medicationText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
                yPos += 20
            }
            
            // Lab Tests
            if let labTests = prescription.labTests {
                let labTestsTitle = "Lab Tests" as NSString
                labTestsTitle.draw(at: CGPoint(x: 50, y: yPos + 20), withAttributes: [.font: headerFont])
                
                yPos += 50
                for (test, description) in labTests {
                    let testText = "• \(test): \(description)" as NSString
                    testText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
                    yPos += 20
                }
            }
            
            // Precautions/Doctor's Advice
            if let precautions = prescription.precautions {
                let precautionsTitle = "Doctor's Advice" as NSString
                precautionsTitle.draw(at: CGPoint(x: 50, y: yPos + 20), withAttributes: [.font: headerFont])
                
                yPos += 50
                let precautionsText = precautions as NSString
                precautionsText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [.font: regularFont])
            }
            
            // Footer
            let footerText = "This prescription is electronically generated and does not require a signature." as NSString
            footerText.draw(at: CGPoint(x: 50, y: pageHeight - 100), withAttributes: [.font: regularFont])
            
            let signatureText = "Doctor's Signature" as NSString
            signatureText.draw(at: CGPoint(x: pageWidth - 150, y: pageHeight - 50), withAttributes: [.font: regularFont])
        }
        
        showShareSheet = true
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
    
    private func medicationsCard(medications: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Medications")
                .font(.title3)
                .foregroundColor(.teal)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Medicine")
                    Spacer()
                    Text("Dosage")
                    Spacer()
                    Text("Frequency")
                    Spacer()
                    Text("Timing")
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(Color.teal)
                .foregroundColor(.white)
                
                // Medications List
                ForEach(medications.sorted(by: { $0.key < $1.key }), id: \.key) { name, details in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(name)
                                Text("Brand Name")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(details)
                        }
                        .padding()
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func labTestsCard(tests: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cross.case.fill")
                Text("Lab Tests")
            }
            .font(.title3)
            .foregroundColor(.teal)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(tests.sorted(by: { $0.key < $1.key }), id: \.key) { name, description in
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(.teal)
                        Text(name)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func doctorAdviceCard(precautions: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                Text("Doctor's Advice")
            }
            .font(.title3)
            .foregroundColor(.teal)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(precautions.components(separatedBy: "\n"), id: \.self) { precaution in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(precaution)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private var signatureSection: some View {
        VStack(spacing: 20) {
            Text("This prescription is electronically generated and does not require a signature.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Image(systemName: "signature")
                .font(.largeTitle)
                .foregroundColor(.teal)
            
            Text("Doctor's Signature")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.1), radius: 5)
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
