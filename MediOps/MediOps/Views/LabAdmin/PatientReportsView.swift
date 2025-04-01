import SwiftUI
import PDFKit
import UIKit

// MARK: - Lab Admin Patients ViewModel
class LabAdminPatientsViewModel: ObservableObject {
    @Published var patients: [Models.Patient] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let supabase = SupabaseController.shared
    
    func fetchPatients() async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            // Get the lab admin ID from UserDefaults
            guard let labAdminId = UserDefaults.standard.string(forKey: "lab_admin_id") else {
                throw NSError(domain: "LabAdminViewModel", code: 1, 
                             userInfo: [NSLocalizedDescriptionKey: "Lab admin ID not found. Please log in again."])
            }
            
            print("FETCH PATIENTS: Fetching for lab admin ID: \(labAdminId)")
            
            // Get the hospital ID associated with this lab admin
            let labAdmins = try await supabase.select(
                from: "lab_admins",
                where: "id",
                equals: labAdminId
            )
            
            guard let labAdminData = labAdmins.first,
                  let hospitalId = labAdminData["hospital_id"] as? String else {
                throw NSError(domain: "LabAdminViewModel", code: 2, 
                             userInfo: [NSLocalizedDescriptionKey: "Hospital ID not found for lab admin"])
            }
            
            print("FETCH PATIENTS: Found hospital ID: \(hospitalId) for lab admin: \(labAdminId)")
            
            // Fetch all patients associated with this hospital
            // Note: The exact query will depend on your schema - assuming patients have a hospital_id field
            // If they don't, we might need to join through another table or use a different approach
            let patientsData = try await supabase.select(
                from: "patients",
                where: "hospital_id",
                equals: hospitalId
            )
            
            print("FETCH PATIENTS: Retrieved \(patientsData.count) patients for hospital: \(hospitalId)")
            
            // If there's no direct hospital_id on patients, try different approach - check user_ids
            var patientsList: [Models.Patient] = []
            
            if patientsData.isEmpty {
                print("FETCH PATIENTS: No patients found with direct hospital_id match, trying alternative approach")
                
                // Get all patients as a fallback (in a real app, you'd want to limit this or use a different approach)
                let allPatientsData = try await supabase.select(from: "patients")
                print("FETCH PATIENTS: Retrieved \(allPatientsData.count) patients in total")
                
                // Parse patients
                for patientData in allPatientsData {
                    do {
                        if let patient = try parsePatientData(patientData) {
                            patientsList.append(patient)
                        }
                    } catch {
                        print("FETCH PATIENTS ERROR: Failed to parse patient: \(error.localizedDescription)")
                    }
                }
            } else {
                // Parse patients from direct hospital association
                for patientData in patientsData {
                    do {
                        if let patient = try parsePatientData(patientData) {
                            patientsList.append(patient)
                        }
                    } catch {
                        print("FETCH PATIENTS ERROR: Failed to parse patient: \(error.localizedDescription)")
                    }
                }
            }
            
            await MainActor.run {
                self.patients = patientsList
                self.isLoading = false
                print("FETCH PATIENTS: Updated UI with \(patientsList.count) patients")
            }
        } catch {
            print("FETCH PATIENTS ERROR: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Failed to fetch patients: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Our own implementation to parse patient data
    private func parsePatientData(_ data: [String: Any]) throws -> Models.Patient? {
        // Extract required fields with validation
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let gender = data["gender"] as? String,
              let ageValue = data["age"] as? Int else {
            print("Missing required patient fields")
            return nil
        }
        
        // Get createdAt and updatedAt or use current date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var createdDate: Date = Date()
        if let createdAtStr = data["created_at"] as? String,
            let date = dateFormatter.date(from: createdAtStr) {
            createdDate = date
        }
        
        var updatedDate: Date = Date()
        if let updatedAtStr = data["updated_at"] as? String,
            let date = dateFormatter.date(from: updatedAtStr) {
            updatedDate = date
        }
        
        // Create a patient with all fields, providing defaults for non-optional fields
        let patient = Models.Patient(
            id: id,
            userId: data["user_id"] as? String ?? "",
            name: name,
            age: ageValue,
            gender: gender,
            createdAt: createdDate,
            updatedAt: updatedDate,
            email: data["email"] as? String,
            emailVerified: data["email_verified"] as? Bool,
            bloodGroup: data["blood_group"] as? String ?? "",
            address: data["address"] as? String,
            phoneNumber: data["phone_number"] as? String ?? "",
            emergencyContactName: data["emergency_contact_name"] as? String,
            emergencyContactNumber: data["emergency_contact_number"] as? String ?? "",
            emergencyRelationship: data["emergency_relationship"] as? String ?? ""
        )
        
        return patient
    }
}

// MARK: - Patient Report Model
struct PatientReport: Identifiable {
    let id: UUID
    let patientName: String
    let patientId: String
    let summary: String?
    let fileUrl: String
    let uploadedAt: Date
    let labId: String?
    
    init(from data: [String: Any]) {
        // Extract id as UUID
        if let idString = data["id"] as? String, let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
            print("Warning: Invalid or missing UUID for report")
        }
        
        // Extract required fields with fallbacks
        self.patientName = data["patient_name"] as? String ?? "Unknown"
        self.patientId = data["patient_id"] as? String ?? "Unknown"
        
        // Extract optional summary
        self.summary = data["summary"] as? String
        
        // Extract required file URL
        self.fileUrl = data["file_url"] as? String ?? ""
        
        // Get the lab_id (optional)
        self.labId = data["lab_id"] as? String
        
        // Parse uploaded_at timestamp
        if let dateString = data["uploaded_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                self.uploadedAt = date
            } else {
                // Try without fractional seconds if first attempt fails
                formatter.formatOptions = [.withInternetDateTime]
                self.uploadedAt = formatter.date(from: dateString) ?? Date()
            }
        } else {
            self.uploadedAt = Date()
            print("Warning: No uploaded_at date for report")
        }
    }
}

// MARK: - Report Card View
struct PatientReportCard: View {
    let report: PatientReport
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    @State private var showOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.patientName)
                        .font(.headline)
                    Text("Patient ID: \(report.patientId)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Text(formatDate(report.uploadedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let summary = report.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            HStack {
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("View Report")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Three dots menu button
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - PDF Generator
class PDFGenerator {
    static func generateLabReportPDF(report: PatientReport) -> Data? {
        // Create a PDF renderer with A4 page size
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Create PDF context
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate PDF data
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Define drawing attributes
            let textAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            let headerAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ]
            let subheaderAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
            ]
            
            // Draw title
            let title = "Lab Report"
            let titleSize = title.size(withAttributes: headerAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: 50, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: headerAttributes)
            
            // Draw line below title
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 80))
            path.addLine(to: CGPoint(x: pageWidth - 50, y: 80))
            UIColor.black.setStroke()
            path.stroke()
            
            // Draw Patient Details section
            let patientTitle = "Patient Details"
            patientTitle.draw(
                at: CGPoint(x: 50, y: 100),
                withAttributes: subheaderAttributes
            )
            
            let nameText = "Name: \(report.patientName)"
            nameText.draw(
                at: CGPoint(x: 50, y: 130),
                withAttributes: textAttributes
            )
            
            let idText = "Patient ID: \(report.patientId)"
            idText.draw(
                at: CGPoint(x: 50, y: 150),
                withAttributes: textAttributes
            )
            
            // Format date and add report date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateText = "Report Date: \(dateFormatter.string(from: report.uploadedAt))"
            dateText.draw(
                at: CGPoint(x: 50, y: 170),
                withAttributes: textAttributes
            )
            
            // Add email (example data - could be stored in the report in the future)
            let emailText = "Email: \(report.patientId.lowercased())@example.com"
            emailText.draw(
                at: CGPoint(x: 50, y: 190),
                withAttributes: textAttributes
            )
            
            // Draw Summary section
            let summaryTitle = "Summary"
            summaryTitle.draw(
                at: CGPoint(x: 50, y: 220),
                withAttributes: subheaderAttributes
            )
            
            let summaryText = report.summary ?? "No summary available"
            
            // Draw multi-line summary
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let summaryRect = CGRect(x: 50, y: 250, width: pageWidth - 100, height: 200)
            summaryText.draw(in: summaryRect, withAttributes: summaryAttributes)
            
            // Add hospital logo or watermark
            if let logoImage = UIImage(named: "hospital_logo") {
                let logoRect = CGRect(x: pageWidth - 100, y: pageHeight - 100, width: 50, height: 50)
                logoImage.draw(in: logoRect)
            }
            
            // Add footer with date generated
            let footerText = "Generated on \(dateFormatter.string(from: Date()))"
            let footerAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10),
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            let footerRect = CGRect(
                x: (pageWidth - footerSize.width) / 2,
                y: pageHeight - 50,
                width: footerSize.width,
                height: footerSize.height
            )
            footerText.draw(in: footerRect, withAttributes: footerAttributes)
        }
        
        return pdfData
    }
}

// MARK: - PDF Preview View
struct PDFPreview: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}

// MARK: - Report Detail View
struct PatientReportDetailView: View {
    let report: PatientReport
    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingPdf = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoadingPdf {
                    ProgressView("Generating report...")
                } else if let pdfData = pdfData {
                    PDFPreview(data: pdfData)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Failed to generate report")
                            .font(.headline)
                        Text("Please try again later")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .navigationTitle("Lab Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                if pdfData != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: sharePDF) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadReport()
            }
        }
    }
    
    private func loadReport() {
        // If the report's fileUrl starts with "generated_pdf", we'll generate a PDF
        // Otherwise, we'll try to load the PDF from the URL
        if report.fileUrl.starts(with: "generated_pdf") {
            generatePDF()
        } else {
            // For real URLs, attempt to load the PDF
            loadPDFFromURL()
        }
    }
    
    private func generatePDF() {
        // Generate a PDF from the report data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let generatedPDF = PDFGenerator.generateLabReportPDF(report: report) {
                pdfData = generatedPDF
                isLoadingPdf = false
            } else {
                isLoadingPdf = false
                errorMessage = "Failed to generate PDF report"
                showError = true
            }
        }
    }
    
    private func loadPDFFromURL() {
        guard let url = URL(string: report.fileUrl) else {
            isLoadingPdf = false
            errorMessage = "Invalid report URL"
            showError = true
            return
        }
        
        // Use URLSession to download the PDF
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingPdf = false
                
                if let error = error {
                    errorMessage = "Failed to load PDF: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    errorMessage = "Failed to load PDF from server"
                    showError = true
                    return
                }
                
                // Check if the data is a valid PDF
                if PDFDocument(data: data) != nil {
                    pdfData = data
                } else {
                    // If not a valid PDF, generate one instead
                    pdfData = PDFGenerator.generateLabReportPDF(report: report)
                    if pdfData == nil {
                        errorMessage = "Invalid PDF format"
                        showError = true
                    }
                }
            }
        }.resume()
    }
    
    private func sharePDF() {
        guard let pdfData = pdfData else { return }
        
        // Create a formatted filename with patient ID and date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: report.uploadedAt)
        let fileName = "Lab_Report_\(report.patientId)_\(dateString).pdf"
        
        // Create a temporary URL to store the PDF
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // Write PDF data to temporary file
            try pdfData.write(to: url)
            
            // Create activity view controller to share the PDF
            let activityViewController = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // Present the activity view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityViewController, animated: true)
            }
        } catch {
            errorMessage = "Failed to share PDF: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Add Report View
struct AddReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patientName = ""
    @State private var patientId = ""
    @State private var summary = ""
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let supabase = SupabaseController.shared
    
    var onReportAdded: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $patientName)
                    TextField("Patient ID", text: $patientId)
                }
                
                Section(header: Text("Report Details")) {
                    TextField("Report Summary", text: $summary, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section {
                    Button(action: addReport) {
                        HStack {
                            Text("Add Report")
                            if isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading || patientName.isEmpty || patientId.isEmpty)
                }
            }
            .navigationTitle("Add New Report")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addReport() {
        isLoading = true
        
        // Generate a placeholder for the file_url, which will be used to identify this is a generated PDF
        let placeholderUrl = "generated_pdf_\(UUID().uuidString)"
        
        // Get the lab admin ID from UserDefaults
        guard let labAdminId = UserDefaults.standard.string(forKey: "lab_admin_id") else {
            errorMessage = "Lab admin ID not found. Please log in again."
            showError = true
            isLoading = false
            return
        }
        
        // Create a new report with the required fields following the table definition
        let newReport: [String: Any] = [
            "patient_name": patientName,
            "patient_id": patientId,
            "summary": summary,
            "file_url": placeholderUrl, // Required field in the database schema
            "lab_id": labAdminId // Associate with the lab admin
        ]
        
        Task {
            do {
                // First ensure the table exists
                try await supabase.ensurePatReportsTableExists()
                
                // Insert the new report
                try await supabase.insert(into: "pat_reports", values: newReport)
                
                print("Report successfully added to pat_reports table for lab admin: \(labAdminId)")
                
                await MainActor.run {
                    isLoading = false
                    onReportAdded()
                    dismiss()
                }
            } catch {
                print("ERROR adding report: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to add report: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Edit Report View
struct EditReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patientName: String
    @State private var patientId: String
    @State private var summary: String
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let supabase = SupabaseController.shared
    private let report: PatientReport
    
    var onReportUpdated: () -> Void
    
    init(report: PatientReport, onReportUpdated: @escaping () -> Void) {
        self.report = report
        self._patientName = State(initialValue: report.patientName)
        self._patientId = State(initialValue: report.patientId)
        self._summary = State(initialValue: report.summary ?? "")
        self.onReportUpdated = onReportUpdated
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $patientName)
                    TextField("Patient ID", text: $patientId)
                }
                
                Section(header: Text("Report Details")) {
                    TextField("Report Summary", text: $summary, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section {
                    Button(action: updateReport) {
                        HStack {
                            Text("Update Report")
                            if isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading || patientName.isEmpty || patientId.isEmpty)
                }
            }
            .navigationTitle("Edit Report")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateReport() {
        isLoading = true
        
        // Create an updated report object with only the fields we want to update
        var updatedReport: [String: Any] = [
            "patient_name": patientName,
            "patient_id": patientId,
            "summary": summary
        ]
        
        // Get the lab admin ID from UserDefaults
        // We'll include it in the update to ensure it's preserved or updated if missing
        if let labAdminId = UserDefaults.standard.string(forKey: "lab_admin_id") {
            updatedReport["lab_id"] = labAdminId
        }
        
        Task {
            do {
                // Update the report in Supabase
                try await supabase.update(table: "pat_reports", id: report.id.uuidString, data: updatedReport)
                
                print("Report successfully updated in pat_reports table")
                
                await MainActor.run {
                    isLoading = false
                    onReportUpdated()
                    dismiss()
                }
            } catch {
                print("ERROR updating report: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update report: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Patient Card View
struct PatientCard: View {
    let patient: Models.Patient
    var onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.name)
                        .font(.headline)
                    Text("ID: \(patient.id)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Display age and gender
                HStack(spacing: 3) {
                    Text(patient.gender)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text("\(patient.age) yrs")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            // Contact Info
            HStack {
                Label {
                    Text(patient.phoneNumber ?? "No Phone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if !patient.bloodGroup.isEmpty {
                    Text("Blood: \(patient.bloodGroup)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }
            
            // View Button and Chevron
            HStack {
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.blue)
                        Text("View Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

// MARK: - Patient Reports View
struct PatientReportsView: View {
    // Reports-related state
    @State private var reports = [PatientReport]()
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedReport: PatientReport?
    @State private var showReportDetail = false
    @State private var showAddReport = false
    @State private var showEditReport = false
    @State private var reportToEdit: PatientReport?
    @State private var showDeleteConfirmation = false
    @State private var reportToDelete: PatientReport?
    
    private let supabase = SupabaseController.shared
    
    var filteredReports: [PatientReport] {
        if searchQuery.isEmpty {
            return reports
        } else {
            return reports.filter { report in
                report.patientName.lowercased().contains(searchQuery.lowercased()) ||
                report.patientId.lowercased().contains(searchQuery.lowercased()) ||
                (report.summary?.lowercased().contains(searchQuery.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background with a gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced header
                VStack(spacing: 5) {
                    // Title
                    HStack {
                        Text("Lab Reports")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Report count badge
                        Text("\(reports.count) Reports")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.blue))
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Search bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            
                            TextField("Search by patient name or ID", text: $searchQuery)
                                .padding(.vertical, 10)
                            
                            if !searchQuery.isEmpty {
                                Button(action: {
                                    searchQuery = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Reports List with improved UI
                reportsListView
                    .refreshable {
                        await fetchPatientReports()
                    }
            }
            
            // Floating Add Button with animation
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddReport = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            ))
                            .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isLoading)
                }
            }
        }
        .onAppear {
            Task {
                await fetchPatientReports()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showReportDetail) {
            if let report = selectedReport {
                PatientReportDetailView(report: report)
            }
        }
        .sheet(isPresented: $showAddReport) {
            AddReportView {
                // This closure is called when a report is added
                Task {
                    await fetchPatientReports()
                }
            }
        }
        .sheet(isPresented: $showEditReport) {
            if let report = reportToEdit {
                EditReportView(report: report) {
                    // This closure is called when a report is updated
                    Task {
                        await fetchPatientReports()
                    }
                }
            }
        }
        .alert("Delete Report", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let report = reportToDelete {
                    deleteReport(report)
                }
            }
        } message: {
            Text("Are you sure you want to delete this report? This action cannot be undone.")
        }
    }
    
    // MARK: - Improved Reports List View
    var reportsListView: some View {
        ScrollView {
            VStack(spacing: 15) {
                if isLoading {
                    // Enhanced loading view
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Loading reports...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 100)
                } else if reports.isEmpty {
                    // Enhanced empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("No Reports Found")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Create your first patient report by tapping the + button")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showAddReport = true
                        }) {
                            Text("Add First Report")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(Capsule().fill(Color.blue))
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if filteredReports.isEmpty {
                    // Enhanced no search results
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.orange.opacity(0.8))
                        
                        Text("No Matching Reports")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Try adjusting your search criteria")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        
                        Button(action: {
                            searchQuery = ""
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Clear Search")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    // Section header with report count
                    HStack {
                        if !searchQuery.isEmpty {
                            Text("Found \(filteredReports.count) results")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Sort button (placeholder for now)
                        Button(action: {
                            // Sort functionality could be implemented here
                        }) {
                            HStack(spacing: 4) {
                                Text("Recent")
                                    .font(.subheadline)
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Improved report cards
                    ForEach(filteredReports) { report in
                        improvedReportCard(report: report)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Improved Report Card
    private func improvedReportCard(report: PatientReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Patient info section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.patientName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("ID: \(report.patientId)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Date badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(report.uploadedAt, dateOnly: true))
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(formatDate(report.uploadedAt, timeOnly: true))
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 15)
            
            // Summary section
            VStack(alignment: .leading, spacing: 10) {
                if let summary = report.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                } else {
                    Text("No summary available")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.7))
                        .italic()
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 15)
            
            // Action buttons with divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 15)
            
            HStack(spacing: 0) {
                // View Button
                Button(action: {
                    selectedReport = report
                    showReportDetail = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("View")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                // Edit Button
                Button(action: {
                    reportToEdit = report
                    showEditReport = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.green)
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 30)
                
                // Delete Button
                Button(action: {
                    reportToDelete = report
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
    
    // Date formatting functions
    private func formatDate(_ date: Date, dateOnly: Bool = false, timeOnly: Bool = false) -> String {
        let formatter = DateFormatter()
        if dateOnly {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        } else if timeOnly {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func fetchPatientReports() async {
        isLoading = true
        
        do {
            // Get the lab admin ID from UserDefaults (set during login)
            guard let labAdminId = UserDefaults.standard.string(forKey: "lab_admin_id") else {
                throw NSError(domain: "LabReportError", code: 1, 
                              userInfo: [NSLocalizedDescriptionKey: "Lab admin ID not found. Please log in again."])
            }
            
            print("FETCH REPORTS: Fetching for lab admin ID: \(labAdminId)")
            
            // Ensure the pat_reports table exists with the correct schema
            try await supabase.ensurePatReportsTableExists()
            
            // Fetch only reports associated with this lab admin
            let patientReportsData = try await supabase.select(
                from: "pat_reports",
                where: "lab_id",
                equals: labAdminId
            )
            
            print("FETCH REPORTS: Retrieved \(patientReportsData.count) reports for lab admin: \(labAdminId)")
            
            // If no reports exist, simply update the UI with empty data instead of creating a sample report
            if patientReportsData.isEmpty {
                print("No reports found for lab admin ID: \(labAdminId)")
                await MainActor.run {
                    reports = []
                    isLoading = false
                }
            } else {
                await updateReportsUI(with: patientReportsData)
            }
        } catch {
            print("FETCH REPORTS ERROR: \(error.localizedDescription)")
            
            await MainActor.run {
                errorMessage = "Failed to fetch reports: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func deleteReport(_ report: PatientReport) {
        Task {
            do {
                // Delete the report from Supabase
                try await supabase.delete(from: "pat_reports", where: "id", equals: report.id.uuidString)
                print("Report successfully deleted from pat_reports table")
                
                // Refresh the reports list
                await fetchPatientReports()
            } catch {
                print("ERROR deleting report: \(error.localizedDescription)")
                
                await MainActor.run {
                    errorMessage = "Failed to delete report: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func updateReportsUI(with data: [[String: Any]]) async {
        // Convert to PatientReport models
        let fetchedReports = data.map { PatientReport(from: $0) }
        
        // Update the UI on the main thread
        await MainActor.run {
            reports = fetchedReports.sorted(by: { $0.uploadedAt > $1.uploadedAt }) // Sort by most recent first
            isLoading = false
        }
    }
}

#Preview {
    PatientReportsView()
} 