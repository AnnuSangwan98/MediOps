import Foundation

struct Prescription: Codable {
    let id: String
    let appointmentId: String
    let doctorId: String
    let patientId: String
    let prescriptionDate: String 
    let medications: [String: String]
    let labTests: [String: String]?
    let precautions: String?
    let previousPrescriptionURL: String?
    let labReportsURL: String?
    let additionalNotes: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case doctorId = "doctor_id"
        case patientId = "patient_id"
        case prescriptionDate = "prescription_date"
        case medications
        case labTests = "lab_tests"
        case precautions
        case previousPrescriptionURL = "previous_prescription_url"
        case labReportsURL = "lab_reports_url"
        case additionalNotes = "additional_notes"
        case createdAt = "created_at"
    }
}

extension Prescription {
    var medicationsArray: [MedicationItem] {
        medications.map { MedicationItem(name: $0.key, details: $0.value) }
    }
    
    var labTestsArray: [LabTestItem] {
        (labTests ?? [:]).map { LabTestItem(name: $0.key, description: $0.value) }
    }
}

struct MedicationItem: Identifiable {
    let id = UUID()
    let name: String
    let details: String
}

struct LabTestItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}
