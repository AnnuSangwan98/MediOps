import SwiftUI

struct LabReportsHistoryView: View {
    @StateObject private var labReportManager = LabReportManager.shared
    @State private var debugMessage: String = ""
    
    var body: some View {
        VStack {
            // Debug section
            if !debugMessage.isEmpty {
                Text(debugMessage)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Group {
                if labReportManager.isLoading {
                    ProgressView("Loading reports...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = labReportManager.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            fetchReports()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if labReportManager.labReports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No Lab Reports")
                            .font(.headline)
                        Text("Your lab reports will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("Fetch Reports") {
                            fetchReports()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(labReportManager.labReports, id: \.id) { report in
                                PatientLabReportCard(report: report)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .onAppear(perform: fetchReports)
        .refreshable {
            fetchReports()
        }
    }
    
    private func fetchReports() {
        // We'll directly fetch reports for PAT001
        labReportManager.fetchLabReports(for: "PAT001")
    }
}

#Preview {
    LabReportsHistoryView()
}
