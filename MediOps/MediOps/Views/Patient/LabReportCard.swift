import SwiftUI

struct LabReportCard: View {
    let report: LabReport
    
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
            
            Link(destination: URL(string: report.fileUrl)!) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("View Report")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

//#Preview {
//    LabReportCard(report: LabReport(
//        id: UUID().uuidString,
//        patientName: "John Doe",
//        patientId: "PAT001",
//        summary: "Annual Health Checkup Report",
//        fileUrl: "https://example.com/report",
//        uploadedAt: Date()
//    ))
//    .padding()
//}
