import Foundation

struct LabReport: Identifiable, Codable {
    let id: String
    let patientName: String
    let patientId: String // Format: "PAT001"
    let summary: String?
    let fileUrl: String
    let uploadedAt: Date
    let labId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientName = "patient_name"
        case patientId = "patient_id"
        case summary
        case fileUrl = "file_url"
        case uploadedAt = "uploaded_at"
        case labId = "lab_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.patientName = try container.decode(String.self, forKey: .patientName)
        self.patientId = try container.decode(String.self, forKey: .patientId)
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary)
        self.fileUrl = try container.decode(String.self, forKey: .fileUrl)
        self.labId = try container.decodeIfPresent(String.self, forKey: .labId)
        
        // Handle date decoding
        if let dateString = try? container.decode(String.self, forKey: .uploadedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                self.uploadedAt = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                self.uploadedAt = formatter.date(from: dateString) ?? Date()
            }
        } else {
            self.uploadedAt = Date()
        }
    }
}

class LabReportManager: ObservableObject {
    @Published var labReports: [LabReport] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    static let shared = LabReportManager()
    private let supabase = SupabaseController.shared
    
    private init() {}
    
    func fetchLabReports(for patientId: String) {
        isLoading = true
        error = nil
        print("🔍 Fetching reports for patient_id: \(patientId)")
        
        Task {
            do {
                // Directly query pat_reports table using patient_id
                let data = try await supabase.select(
                    from: "pat_reports",
                    columns: "*",
                    where: "patient_id",
                    equals: patientId
                )
                
                print("📊 Found \(data.count) reports in pat_reports for patient_id: \(patientId)")
                print("Raw data: \(data)")
                
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let reports = try decoder.decode([LabReport].self, from: jsonData)
                
                await MainActor.run {
                    print("✅ Successfully loaded \(reports.count) reports")
                    self.labReports = reports.sorted(by: { $0.uploadedAt > $1.uploadedAt })
                    self.isLoading = false
                }
            } catch {
                print("❌ Error loading reports: \(error)")
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}
