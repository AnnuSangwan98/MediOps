import SwiftUI
import PDFKit

struct PatientLabReportCard: View {
    let report: PatientLabReport
    @State private var showPdfViewer = false
    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false
    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var refreshID = UUID() // For UI refresh on theme change
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.patientName)
                        .font(.headline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .primary)
                    Text("Patient ID: \(report.patientId)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                }
                Spacer()
                
                Text(formatDate(report.uploadedAt))
                    .font(.caption)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
            }
            
            if let summary = report.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            Button(action: {
                handleViewReport()
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .blue)
                    Text("View Report")
                        .font(.caption)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .blue)
                    if isGeneratingPDF {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isGeneratingPDF)
        }
        .padding()
        .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
        .cornerRadius(12)
        .shadow(color: themeManager.isPatient ? themeManager.currentTheme.accentColor.opacity(0.1) : .gray.opacity(0.1), radius: 5)
        .sheet(isPresented: $showPdfViewer) {
            if let pdfData = pdfData {
                PDFViewerSheet(pdfData: pdfData, report: report)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Listen for theme changes
            setupThemeChangeListener()
        }
        .id(refreshID) // Force refresh when ID changes
    }
    
    private func handleViewReport() {
        if report.fileUrl.starts(with: "generated_pdf") {
            isGeneratingPDF = true
            // Generate PDF
            generatePDF()
        } else {
            // Load PDF from URL
            loadPDFFromURL()
        }
    }
    
    private func generatePDF() {
        let pdfData = LabReportPDFGenerator.generatePDF(for: report)
        self.pdfData = pdfData
        self.isGeneratingPDF = false
        self.showPdfViewer = true
    }
    
    private func loadPDFFromURL() {
        guard let url = URL(string: report.fileUrl) else {
            errorMessage = "Invalid URL"
            showError = true
            return
        }
        
        isGeneratingPDF = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isGeneratingPDF = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    showError = true
                    return
                }
                
                self.pdfData = data
                self.showPdfViewer = true
            }
        }.resume()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Setup listener for theme changes
    private func setupThemeChangeListener() {
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { _ in
            // Generate new ID to force view refresh
            refreshID = UUID()
        }
    }
}

struct PDFViewerSheet: View {
    let pdfData: Data
    let report: PatientLabReport
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("Lab Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(
                            item: pdfData,
                            preview: SharePreview(
                                "Lab Report - \(report.patientName)",
                                image: Image(systemName: "doc.text")
                            )
                        )
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}

enum LabReportPDFGenerator {
    static func generatePDF(for report: PatientLabReport) -> Data {
        // Create a PDF renderer with A4 page size
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Create PDF context
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate PDF data
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
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
            
            // Draw patient details
            let patientTitle = "Patient Details"
            patientTitle.draw(at: CGPoint(x: 50, y: 100), withAttributes: subheaderAttributes)
            
            let nameText = "Name: \(report.patientName)"
            nameText.draw(at: CGPoint(x: 50, y: 130), withAttributes: textAttributes)
            
            let idText = "Patient ID: \(report.patientId)"
            idText.draw(at: CGPoint(x: 50, y: 150), withAttributes: textAttributes)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateText = "Report Date: \(dateFormatter.string(from: report.uploadedAt))"
            dateText.draw(at: CGPoint(x: 50, y: 170), withAttributes: textAttributes)
            
            if let summary = report.summary {
                let summaryTitle = "Summary"
                summaryTitle.draw(at: CGPoint(x: 50, y: 200), withAttributes: subheaderAttributes)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .natural
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]
                
                let summaryRect = CGRect(x: 50, y: 230, width: pageWidth - 100, height: 200)
                summary.draw(in: summaryRect, withAttributes: summaryAttributes)
            }
        }
        
        return pdfData
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "normal":
            return .green
        case "abnormal":
            return .orange
        case "critical":
            return .red
        default:
            return .gray
        }
    }
}
