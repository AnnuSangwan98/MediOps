import Foundation

struct Prescription: Codable {
    let id: String
    let appointmentId: String
    let doctorId: String
    let patientId: String
    let prescriptionDate: String
    let medications: [MedicationItem]
    let labTests: [LabTestItem]?
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
        medications
    }
    
    var labTestsArray: [LabTestItem] {
        labTests ?? []
    }
}

struct MedicationItem: Codable, Identifiable {
    let id = UUID()
    let medicineName: String
    let brandName: String
    let dosage: String
    let frequency: String
    let timing: String
    
    init(medicineName: String, brandName: String, dosage: String, frequency: String, timing: String) {
        self.medicineName = medicineName
        self.brandName = brandName
        self.dosage = dosage
        self.frequency = frequency
        self.timing = timing
    }
    
    enum CodingKeys: String, CodingKey {
        case medicineName = "medicine_name"
        case brandName = "brand_name"
        case dosage
        case frequency
        case timing
    }
}

struct LabTestItem: Codable, Identifiable {
    let id = UUID()
    let testName: String
    let instructions: String
    
    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case instructions
    }
}
