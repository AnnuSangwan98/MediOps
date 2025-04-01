import Foundation

// Define the medication and lab test structures
struct MedicationDetails: Codable {
    let dosage: String
    let timing: String
    let frequency: String
    let brandName: String
    let medicineName: String
    
    enum CodingKeys: String, CodingKey {
        case dosage
        case timing
        case frequency
        case brandName = "brand_name"
        case medicineName = "medicine_name"
    }
}

struct LabTestDetails: Codable {
    let testName: String
    let instructions: String
    
    enum CodingKeys: String, CodingKey {
        case testName = "test_name"
        case instructions
    }
}

struct Prescription: Codable {
    let id: String
    let appointmentId: String 
    let doctorId: String
    let patientId: String
    let prescriptionDate: String
    let medications: [MedicationDetails]
    let labTests: [LabTestDetails]?
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

// Extension to convert to display models
extension Prescription {
    var medicationsArray: [MedicationItem] {
        medications.map { medication in
            MedicationItem(
                name: medication.medicineName,
                details: "\(medication.dosage) - \(medication.frequency) (\(medication.timing))"
            )
        }
    }
    
    var labTestsArray: [LabTestItem] {
        (labTests ?? []).map { test in
            LabTestItem(
                name: test.testName,
                description: test.instructions
            )
        }
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
