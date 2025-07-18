import SwiftUI

// MARK: - Test Report Model
struct TestReport: Identifiable {
    let id: String
    var patientName: String
    var testType: String
    var date: Date
    var status: ReportStatus
    var results: String?
    var normalRange: String?
    var remarks: String?
    
    enum ReportStatus: String {
        case pending = "Pending"
        case completed = "Completed"
    }
}

// MARK: - Test Report Card
struct TestReportCard: View {
    let report: TestReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.patientName)
                            .font(.headline)
                        Text("Test ID: \(report.id)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(report.status.rawValue)
                        .font(.caption)
                        .foregroundColor(report.status == .completed ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((report.status == .completed ? Color.green : Color.orange).opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.testType)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(report.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Test Report Detail View
struct TestReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let report: TestReport
    @State private var updatedReport: TestReport
    @State private var showAlert = false
    var onUpdate: (TestReport) -> Void
    
    init(report: TestReport, onUpdate: @escaping (TestReport) -> Void) {
        self.report = report
        self._updatedReport = State(initialValue: report)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Test Information")) {
                    HStack {
                        Text("Test ID")
                        Spacer()
                        Text(updatedReport.id)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Patient Name")
                        Spacer()
                        Text(updatedReport.patientName)
                            .foregroundColor(.gray)
                    }
                    
                    if updatedReport.status == .pending {
                        TextField("Enter Test Type", text: $updatedReport.testType)
                    } else {
                        HStack {
                            Text("Test Type")
                            Spacer()
                            Text(updatedReport.testType)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(updatedReport.date, style: .date)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(updatedReport.status.rawValue)
                            .foregroundColor(updatedReport.status == .completed ? .green : .orange)
                    }
                }
                
                if updatedReport.status == .pending {
                    Section(header: Text("Test Results")) {
                        TextField("Enter test results", text: Binding(
                            get: { updatedReport.results ?? "" },
                            set: { updatedReport.results = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Normal range", text: Binding(
                            get: { updatedReport.normalRange ?? "" },
                            set: { updatedReport.normalRange = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Additional remarks", text: Binding(
                            get: { updatedReport.remarks ?? "" },
                            set: { updatedReport.remarks = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Section {
                        Button(action: {
                            if !updatedReport.testType.isEmpty {
                                var completedReport = updatedReport
                                completedReport.status = .completed
                                onUpdate(completedReport)
                                showAlert = true
                            } else {
                                showAlert = true
                            }
                        }) {
                            Text("Mark as Completed")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.blue)
                    }
                } else {
                    Section(header: Text("Test Results")) {
                        if let results = updatedReport.results {
                            HStack {
                                Text("Results")
                                Spacer()
                                Text(results)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let normalRange = updatedReport.normalRange {
                            HStack {
                                Text("Normal Range")
                                Spacer()
                                Text(normalRange)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let remarks = updatedReport.remarks {
                            HStack {
                                Text("Remarks")
                                Spacer()
                                Text(remarks)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Test Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if updatedReport.status == .pending {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if !updatedReport.testType.isEmpty {
                                onUpdate(updatedReport)
                                showAlert = true
                            } else {
                                showAlert = true
                            }
                        }
                    }
                }
            }
            .alert(updatedReport.status == .completed ? "Report Completed" :
                   !updatedReport.testType.isEmpty ? "Report Saved" : "Missing Information",
                   isPresented: $showAlert) {
                Button("OK") {
                    if updatedReport.status == .completed || !updatedReport.testType.isEmpty {
                        dismiss()
                    }
                }
            } message: {
                Text(updatedReport.status == .completed ? "The test report has been marked as completed." :
                     !updatedReport.testType.isEmpty ? "The test report has been saved successfully." :
                     "Please enter the test type before saving.")
            }
        }
    }
}

struct LabDashboardView: View {
    @State private var searchText = ""
    @State private var selectedReport: TestReport?
    @State private var showReportDetail = false
    @State private var reports: [TestReport]
    
    init() {
        // Initialize with dummy data
        let dummyReports = [
            TestReport(id: "T001", patientName: "John Doe", testType: "",
                      date: Date(), status: .pending),
            TestReport(id: "T002", patientName: "Jane Smith", testType: "X-Ray",
                      date: Date().addingTimeInterval(-86400), status: .completed),
            TestReport(id: "T003", patientName: "Mike Johnson", testType: "",
                      date: Date().addingTimeInterval(-172800), status: .pending),
            TestReport(id: "T004", patientName: "Sarah Wilson", testType: "CT Scan",
                      date: Date().addingTimeInterval(-259200), status: .completed)
        ]
        _reports = State(initialValue: dummyReports)
    }
    
    var filteredReports: [TestReport] {
        if searchText.isEmpty {
            return reports
        } else {
            return reports.filter { report in
                report.patientName.lowercased().contains(searchText.lowercased()) ||
                report.id.lowercased().contains(searchText.lowercased()) ||
                report.testType.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome, Lab")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Laboratory Dashboard")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        Button(action: {
                            // TODO: Implement profile action
                        }) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.teal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by patient name, test ID or type", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        // Test Reports
                        DashboardCard(
                            title: "Test Reports",
                            icon: "doc.text",
                            color: .blue
                        )
                        
                        // Sample Collection
                        DashboardCard(
                            title: "Sample Collection",
                            icon: "cross.case",
                            color: .green
                        )
                        
                        // Test Results
                        DashboardCard(
                            title: "Test Results",
                            icon: "checkmark.circle",
                            color: .purple
                        )
                        
                        // Analytics
                        DashboardCard(
                            title: "Analytics",
                            icon: "chart.bar",
                            color: .orange
                        )
                    }
                    .padding()
                    
                    // Recent Tests
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Tests")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if filteredReports.isEmpty {
                            Text("No tests found")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.1), radius: 5)
                        } else {
                            ForEach(filteredReports) { report in
                                TestReportCard(report: report) {
                                    selectedReport = report
                                    showReportDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showReportDetail) {
            if let report = selectedReport {
                TestReportDetailView(report: report) { updatedReport in
                    // Update the report in the reports array
                    if let index = reports.firstIndex(where: { $0.id == updatedReport.id }) {
                        reports[index] = updatedReport
                    }
                }
            }
        }
    }
}

#Preview {
    LabDashboardView()
}
