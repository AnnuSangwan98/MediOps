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

// Dashboard Card for Quick Actions
struct LabDashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Report header
                    VStack(alignment: .center, spacing: 4) {
                        Text("Lab Report")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Divider()
                            .padding(.horizontal, 50)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    // Patient Details section
                    Group {
                        Text("Patient Details")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Name:")
                                    .fontWeight(.semibold)
                                    .frame(width: 100, alignment: .leading)
                                Text(updatedReport.patientName)
                            }
                            
                            HStack {
                                Text("Test ID:")
                                    .fontWeight(.semibold)
                                    .frame(width: 100, alignment: .leading)
                                Text(updatedReport.id)
                            }
                            
                            HStack {
                                Text("Report Date:")
                                    .fontWeight(.semibold)
                                    .frame(width: 100, alignment: .leading)
                                Text(formattedDate(updatedReport.date))
                            }
                            
                            HStack {
                                Text("Test Type:")
                                    .fontWeight(.semibold)
                                    .frame(width: 100, alignment: .leading)
                                if updatedReport.status == .pending && updatedReport.testType.isEmpty {
                                    TextField("Enter Test Type", text: $updatedReport.testType)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                } else {
                                    Text(updatedReport.testType.isEmpty ? "Not specified" : updatedReport.testType)
                                }
                            }
                            
                            HStack {
                                Text("Status:")
                                    .fontWeight(.semibold)
                                    .frame(width: 100, alignment: .leading)
                                Text(updatedReport.status.rawValue)
                                    .foregroundColor(updatedReport.status == .completed ? .green : .orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((updatedReport.status == .completed ? Color.green : Color.orange).opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.1), radius: 4)
                    }
                    
                    // Test Results section
                    if updatedReport.status == .pending {
                        Group {
                            Text("Test Results")
                                .font(.headline)
                                .padding(.bottom, 4)
                                .padding(.top)
                            
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Results")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    TextField("Enter test results", text: Binding(
                                        get: { updatedReport.results ?? "" },
                                        set: { updatedReport.results = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.bottom, 4)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Normal Range")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    TextField("Normal range", text: Binding(
                                        get: { updatedReport.normalRange ?? "" },
                                        set: { updatedReport.normalRange = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.bottom, 4)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Additional Remarks")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    TextField("Additional remarks", text: Binding(
                                        get: { updatedReport.remarks ?? "" },
                                        set: { updatedReport.remarks = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 4)
                            
                            // Action button
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
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                    } else {
                        // Display completed test results
                        Group {
                            Text("Test Results")
                                .font(.headline)
                                .padding(.bottom, 4)
                                .padding(.top)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let results = updatedReport.results, !results.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Results:")
                                            .fontWeight(.semibold)
                                        Text(results)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.bottom, 4)
                                }
                                
                                if let normalRange = updatedReport.normalRange, !normalRange.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Normal Range:")
                                            .fontWeight(.semibold)
                                        Text(normalRange)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.bottom, 4)
                                }
                                
                                if let remarks = updatedReport.remarks, !remarks.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Remarks:")
                                            .fontWeight(.semibold)
                                        Text(remarks)
                                            .padding(.leading, 8)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.1), radius: 4)
                        }
                    }
                    
                    // Footer
                    HStack {
                        Spacer()
                        Text("Generated by MediOps")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.top, 30)
                }
                .padding()
            }
            .navigationTitle("Test Report")
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
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Share functionality would go here
                        }) {
                            Image(systemName: "square.and.arrow.up")
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct LabDashboardView: View {
    @State private var searchText = ""
    @State private var selectedReport: TestReport?
    @State private var showReportDetail = false
    @State private var reports: [TestReport]
    @State private var showLogoutAlert = false
    
    // Lab admin information
    var labAdmin: LabAdmin
    
    init(labAdmin: LabAdmin) {
        self.labAdmin = labAdmin
        
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
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lab Reports")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    Button(action: {
                        showLogoutAlert = true
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
                .padding()
                .background(Color.white.opacity(0.9))
                
                // Reports List
                ScrollView {
                    VStack(spacing: 15) {
                        if filteredReports.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No reports found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Test reports will appear here")
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
                                TestReportCard(report: report) {
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
                    // Simulate refresh
                    // In a real app, you'd fetch fresh data here
                    let updatedReport = TestReport(
                        id: "T\(Int.random(in: 100...999))",
                        patientName: ["John Doe", "Jane Smith", "David Brown", "Emily Davis"].randomElement()!,
                        testType: ["Blood Test", "X-Ray", "CT Scan", "MRI"].randomElement()!,
                        date: Date(),
                        status: [TestReport.ReportStatus.pending, TestReport.ReportStatus.completed].randomElement()!
                    )
                    reports.insert(updatedReport, at: 0)
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
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                // Handle logout - return to login screen
                NavigationUtil.popToRootView()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// Utility to pop to root view
struct NavigationUtil {
    static func popToRootView() {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}

// Preview with a sample lab admin
#Preview {
    let sampleLabAdmin = LabAdmin(
        id: "LAB123",
        hospitalId: "HOS123",
        name: "Lab Technician",
        email: "lab@example.com",
        contactNumber: "1234567890",
        department: "Pathology & Laboratory",
        address: "Hospital Address",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return LabDashboardView(labAdmin: sampleLabAdmin)
}
