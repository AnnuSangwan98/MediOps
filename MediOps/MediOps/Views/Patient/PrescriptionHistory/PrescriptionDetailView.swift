import SwiftUI
import PDFKit

// Add ShareSheet definition at the top
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
                } else if let error = controller.error {
                    ErrorView(error: error)
                } else if let prescription = controller.prescription {
                    // Hospital Card
                    if let hospital = controller.hospital {
                        HospitalHeaderView(hospital: hospital)
                    }
                    
                    // Doctor Information
                    if let doctor = controller.doctor {
                        DoctorInfoView(doctor: doctor)
                    }
                    
                    // Medications
                    MedicationsView(medications: prescription.medications)
                    
                    // Lab Tests
                    if let labTests = prescription.labTests {
                        LabTestsView(tests: labTests)
                    }
                    
                    // Doctor's Advice
                    if let precautions = prescription.precautions {
                        DoctorAdviceView(precautions: precautions)
                    }
                    
                    // Signature Section
                    SignatureView()
                } else {
                    Text("No prescription found")
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Prescription")
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
    
    private func generateAndSharePDF() {
        guard let prescription = controller.prescription,
              let hospital = controller.hospital,
              let doctor = controller.doctor else {
            return
        }

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size in points
        
        let pdfMetaData = [
            kCGPDFContextCreator: "MediOps",
            kCGPDFContextAuthor: doctor.name,
            kCGPDFContextTitle: "Medical Prescription"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let drawContext = context.cgContext
            
            // Set up fonts
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let regularFont = UIFont.systemFont(ofSize: 12)
            
            // Colors
            let tealColor = UIColor.systemTeal.cgColor
            drawContext.setStrokeColor(tealColor)
            
            // Draw hospital header
            var yPosition: CGFloat = 50
            
            let hospitalName = hospital.hospitalName as NSString
            hospitalName.draw(at: CGPoint(x: 50, y: yPosition),
                            withAttributes: [.font: titleFont])
            
            yPosition += 30
            let address = hospital.hospitalAddress as NSString
            address.draw(at: CGPoint(x: 50, y: yPosition),
                       withAttributes: [.font: regularFont])
            
            // Draw doctor info
            yPosition += 50
            let doctorHeader = "Doctor Information" as NSString
            doctorHeader.draw(at: CGPoint(x: 50, y: yPosition),
                            withAttributes: [.font: headerFont])
            
            yPosition += 30
            let doctorInfo = """
            Name: \(doctor.name)
            Specialization: \(doctor.specialization)
            Qualification: \(doctor.qualifications.joined(separator: ", "))
            Experience: \(doctor.experience) years
            """ as NSString
            doctorInfo.draw(at: CGPoint(x: 50, y: yPosition),
                          withAttributes: [.font: regularFont])
            
            // Draw medications
            yPosition += 100
            let medicationsHeader = "Medications" as NSString
            medicationsHeader.draw(at: CGPoint(x: 50, y: yPosition),
                                withAttributes: [.font: headerFont])
            
            yPosition += 30
            for (medicine, details) in prescription.medications {
                let medicationText = "\(medicine): \(details)" as NSString
                medicationText.draw(at: CGPoint(x: 50, y: yPosition),
                                 withAttributes: [.font: regularFont])
                yPosition += 20
            }
            
            // Draw lab tests if available
            if let labTests = prescription.labTests {
                yPosition += 30
                let labTestsHeader = "Lab Tests" as NSString
                labTestsHeader.draw(at: CGPoint(x: 50, y: yPosition),
                                 withAttributes: [.font: headerFont])
                
                yPosition += 30
                for (test, description) in labTests {
                    let testText = "\(test): \(description)" as NSString
                    testText.draw(at: CGPoint(x: 50, y: yPosition),
                                withAttributes: [.font: regularFont])
                    yPosition += 20
                }
            }
            
            // Draw precautions if available
            if let precautions = prescription.precautions {
                yPosition += 30
                let precautionsHeader = "Doctor's Advice" as NSString
                precautionsHeader.draw(at: CGPoint(x: 50, y: yPosition),
                                    withAttributes: [.font: headerFont])
                
                yPosition += 30
                let precautionsText = precautions as NSString
                precautionsText.draw(at: CGPoint(x: 50, y: yPosition),
                                  withAttributes: [.font: regularFont])
            }
            
            // Draw signature
            yPosition = pageRect.height - 100
            let signatureText = "Doctor's Signature" as NSString
            signatureText.draw(at: CGPoint(x: pageRect.width - 150, y: yPosition),
                             withAttributes: [.font: regularFont])
            
            // Draw footer
            yPosition += 30
            let footerText = "This prescription is electronically generated and does not require a signature." as NSString
            footerText.draw(at: CGPoint(x: 50, y: yPosition),
                          withAttributes: [.font: regularFont])
        }
        
        showShareSheet = true
    }
}

struct HospitalHeaderView: View {
    let hospital: HospitalModel
    
    var body: some View {
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
            
            HStack(spacing: 20) {
                Text("License No.: \(hospital.licence)")
                Text("Accreditation: \(hospital.hospitalAccreditation)")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.teal.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct DoctorInfoView: View {
    let doctor: HospitalDoctor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Doctor Information")
                .font(.title3)
                .foregroundColor(.teal)
            
            InfoRow(title: "Name", value: doctor.name)
            InfoRow(title: "Specialization", value: doctor.specialization)
            InfoRow(title: "Qualification", value: doctor.qualifications.joined(separator: ", "))
            InfoRow(title: "Experience", value: "\(doctor.experience) years")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct MedicationsView: View {
    let medications: [String: String]
    
    var body: some View {
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
                            Text(name)
                                .fontWeight(.medium)
                            Spacer()
                            Text(details)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        Text("Brand Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.teal.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct LabTestsView: View {
    let tests: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cross.case.fill")
                Text("Lab Tests")
            }
            .font(.title3)
            .foregroundColor(.teal)
            
            ForEach(tests.sorted(by: { $0.key < $1.key }), id: \.key) { name, description in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundColor(.teal)
                    VStack(alignment: .leading) {
                        Text(name)
                            .fontWeight(.medium)
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct DoctorAdviceView: View {
    let precautions: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                Text("Doctor's Advice")
            }
            .font(.title3)
            .foregroundColor(.teal)
            
            ForEach(precautions.components(separatedBy: "\n"), id: \.self) { precaution in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(precaution)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.teal.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct SignatureView: View {
    var body: some View {
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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.orange.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}
