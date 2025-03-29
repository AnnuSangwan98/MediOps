import SwiftUI
import PDFKit
import UIKit

// MARK: - Patient Report Model
struct PatientReport: Identifiable {
    let id: UUID
    let patientName: String
    let patientId: String
    let summary: String?
    let fileUrl: String
    let uploadedAt: Date
    
    init(from data: [String: Any]) {
        self.id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
        self.patientName = data["patient_name"] as? String ?? "Unknown"
        self.patientId = data["patient_id"] as? String ?? "Unknown"
        self.summary = data["summary"] as? String
        self.fileUrl = data["file_url"] as? String ?? ""
        
        // Parse the date
        if let dateString = data["uploaded_at"] as? String {
            let formatter = ISO8601DateFormatter()
            self.uploadedAt = formatter.date(from: dateString) ?? Date()
        } else {
            self.uploadedAt = Date()
        }
    }
}

// MARK: - Report Card View
struct PatientReportCard: View {
    let report: PatientReport
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("View Report")
                        .font(.caption)
                        .foregroundColor(.blue)
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
        .buttonStyle(PlainButtonStyle())
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
                generatePDF()
            }
        }
    }
    
    private func generatePDF() {
        // Simulate a brief loading time
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
    
    private func sharePDF() {
        guard let pdfData = pdfData else { return }
        
        // Create a temporary URL to store the PDF
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(report.patientName)_Lab_Report.pdf")
        
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
        
        // Generate a dummy URL to maintain compatibility with existing database structure
        let placeholderUrl = "generated_pdf_\(UUID().uuidString)"
        
        let newReport: [String: Any] = [
            "patient_name": patientName,
            "patient_id": patientId,
            "summary": summary,
            "file_url": placeholderUrl // We're not using a real URL anymore
        ]
        
        Task {
            do {
                try await supabase.insert(into: "pat_reports", values: newReport)
                
                await MainActor.run {
                    isLoading = false
                    onReportAdded()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to add report: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Patient Reports View
struct PatientReportsView: View {
    @State private var reports: [PatientReport] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchQuery = ""
    @State private var selectedReport: PatientReport?
    @State private var showReportDetail = false
    @State private var showAddReport = false
    
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
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search and add button
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by patient name or ID", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        showAddReport = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Reports List
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading reports...")
                                .padding()
                        } else if reports.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No reports found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Patient reports will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 5)
                            .padding()
                        } else if filteredReports.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No matching reports")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Try adjusting your search criteria")
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
                            // Reports List
                            ForEach(filteredReports) { report in
                                PatientReportCard(report: report) {
                                    selectedReport = report
                                    showReportDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await fetchPatientReports()
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
    }
    
    private func fetchPatientReports() async {
        isLoading = true
        
        do {
            // Ensure the pat_reports table exists
            try await supabase.ensurePatReportsTableExists()
            
            // Fetch reports from Supabase
            let patientReportsData = try await supabase.select(from: "pat_reports")
            print("FETCH REPORTS: Retrieved \(patientReportsData.count) reports")
            
            // If no reports exist, insert a sample one for testing
            if patientReportsData.isEmpty {
                print("No reports found, adding sample data")
                try await supabase.insertSamplePatientReport()
                // Fetch again after adding sample
                let refreshedData = try await supabase.select(from: "pat_reports")
                await updateReportsUI(with: refreshedData)
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