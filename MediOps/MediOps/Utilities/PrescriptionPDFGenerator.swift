import UIKit
import PDFKit

class PrescriptionPDFGenerator {
    private let prescription: Prescription
    private let appointment: Appointment
    private let hospital: HospitalModel
    private let doctor: HospitalDoctor
    
    init(prescription: Prescription, appointment: Appointment, hospital: HospitalModel, doctor: HospitalDoctor) {
        self.prescription = prescription
        self.appointment = appointment
        self.hospital = hospital
        self.doctor = doctor
    }
    
    func generatePDF() -> Data? {
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let format = UIGraphicsPDFRendererFormat()
        let metadata = [
            kCGPDFContextCreator: "MediOps",
            kCGPDFContextAuthor: doctor.name
        ]
        format.documentInfo = metadata as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let headerFont = UIFont.boldSystemFont(ofSize: 16.0)
            let subHeaderFont = UIFont.boldSystemFont(ofSize: 14.0)
            let regularFont = UIFont.systemFont(ofSize: 12.0)
            
            // Add borders to the page
            let borderRect = CGRect(x: 20, y: 20, width: pageWidth - 40, height: pageHeight - 40)
            UIColor.lightGray.setStroke()
            let path = UIBezierPath(rect: borderRect)
            path.lineWidth = 1
            path.stroke()
            
            // Hospital Info
            let hospitalTitle = hospital.hospitalName as NSString
            let hospitalAttrs: [NSAttributedString.Key: Any] = [.font: titleFont]
            let hospitalSize = hospitalTitle.size(withAttributes: hospitalAttrs)
            hospitalTitle.draw(at: CGPoint(x: (pageWidth - hospitalSize.width) / 2, y: 40), withAttributes: hospitalAttrs)
            
            let hospitalAddress = hospital.hospitalAddress as NSString
            let addressAttrs: [NSAttributedString.Key: Any] = [.font: regularFont]
            let addressSize = hospitalAddress.size(withAttributes: addressAttrs)
            hospitalAddress.draw(at: CGPoint(x: (pageWidth - addressSize.width) / 2, y: 70), withAttributes: addressAttrs)
            
            let contactInfo = "Contact: \(hospital.contactNumber) | Emergency: \(hospital.emergencyContactNumber)" as NSString
            let contactAttrs: [NSAttributedString.Key: Any] = [.font: regularFont]
            let contactSize = contactInfo.size(withAttributes: contactAttrs)
            contactInfo.draw(at: CGPoint(x: (pageWidth - contactSize.width) / 2, y: 90), withAttributes: contactAttrs)
            
            // License information
            let licenseInfo = "License No.: \(hospital.licence) | Accreditation: \(hospital.hospitalAccreditation)" as NSString
            let licenseAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10)]
            let licenseSize = licenseInfo.size(withAttributes: licenseAttrs)
            licenseInfo.draw(at: CGPoint(x: (pageWidth - licenseSize.width) / 2, y: 110), withAttributes: licenseAttrs)
            
            // Draw horizontal line
            drawLine(context: context, startX: 40, endX: pageWidth - 40, y: 130)
            
            // Doctor Info
            let doctorTitle = "Doctor Information" as NSString
            doctorTitle.draw(at: CGPoint(x: 40, y: 150), withAttributes: [.font: headerFont])
            
            let doctorInfo = """
            Name: \(doctor.name)
            Specialization: \(doctor.specialization)
            Qualification: \(doctor.qualifications.joined(separator: ", "))
            Experience: \(doctor.experience) years
            """ as NSString
            doctorInfo.draw(at: CGPoint(x: 40, y: 175), withAttributes: [.font: regularFont])
            
            // Appointment info
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            
            let appointmentTitle = "Appointment Details" as NSString
            appointmentTitle.draw(at: CGPoint(x: 300, y: 150), withAttributes: [.font: headerFont])
            
            let appointmentInfo = """
            Date: \(dateFormatter.string(from: appointment.date))
            Time: \(formatTimeRange(appointment.time))
            ID: \(appointment.id)
            """ as NSString
            appointmentInfo.draw(at: CGPoint(x: 300, y: 175), withAttributes: [.font: regularFont])
            
            // Draw horizontal line
            drawLine(context: context, startX: 40, endX: pageWidth - 40, y: 240)
            
            // Medications
            let medicationsTitle = "Medications" as NSString
            medicationsTitle.draw(at: CGPoint(x: 40, y: 260), withAttributes: [.font: headerFont])
            
            var yPos = 285.0
            for medication in prescription.medications {
                let medName = "• \(medication.medicineName) - \(medication.dosage)" as NSString
                medName.draw(at: CGPoint(x: 40, y: yPos), withAttributes: [.font: subHeaderFont])
                yPos += 20
                
                let medDetails = "Frequency: \(medication.frequency) | Timing: \(medication.timing)" as NSString
                medDetails.draw(at: CGPoint(x: 60, y: yPos), withAttributes: [.font: regularFont])
                yPos += 25
            }
            
            // Lab Tests
            if let labTests = prescription.labTests, !labTests.isEmpty {
                let labTestsTitle = "Lab Tests" as NSString
                labTestsTitle.draw(at: CGPoint(x: 40, y: yPos + 10), withAttributes: [.font: headerFont])
                
                yPos += 35
                for test in labTests {
                    let testText = "• \(test.testName)" as NSString
                    testText.draw(at: CGPoint(x: 40, y: yPos), withAttributes: [.font: regularFont])
                    yPos += 20
                }
                
                yPos += 10
            }
            
            // Precautions and advice
            if let precautions = prescription.precautions, !precautions.isEmpty {
                let precautionsTitle = "Doctor's Advice" as NSString
                precautionsTitle.draw(at: CGPoint(x: 40, y: yPos), withAttributes: [.font: headerFont])
                
                yPos += 25
                let adviceRect = CGRect(x: 40, y: yPos, width: pageWidth - 80, height: 100)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                
                let precautionsText = precautions as NSString
                precautionsText.draw(in: adviceRect, withAttributes: [
                    .font: regularFont,
                    .paragraphStyle: paragraphStyle
                ])
                
                yPos += 110
            }
            
            // Additional notes
            if let additionalNotes = prescription.additionalNotes, !additionalNotes.isEmpty {
                let notesTitle = "Additional Notes" as NSString
                notesTitle.draw(at: CGPoint(x: 40, y: yPos), withAttributes: [.font: headerFont])
                
                yPos += 25
                let notesRect = CGRect(x: 40, y: yPos, width: pageWidth - 80, height: 100)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                
                let notesText = additionalNotes as NSString
                notesText.draw(in: notesRect, withAttributes: [
                    .font: regularFont,
                    .paragraphStyle: paragraphStyle
                ])
            }
            
            // Footer with doctor's signature
            let signatureY = pageHeight - 100
            drawLine(context: context, startX: 400, endX: 520, y: signatureY)
            
            let signatureText = "Doctor's Signature" as NSString
            signatureText.draw(at: CGPoint(x: 430, y: signatureY + 10), withAttributes: [.font: regularFont])
            
            // Date of generation
            let dateText = "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))" as NSString
            dateText.draw(at: CGPoint(x: 40, y: pageHeight - 40), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
        }
    }
    
    private func drawLine(context: UIGraphicsPDFRendererContext, startX: CGFloat, endX: CGFloat, y: CGFloat) {
        let line = UIBezierPath()
        line.move(to: CGPoint(x: startX, y: y))
        line.addLine(to: CGPoint(x: endX, y: y))
        line.lineWidth = 1
        UIColor.lightGray.setStroke()
        line.stroke()
    }
    
    private func formatTimeRange(_ time: Date) -> String {
        // Check if we have the slot_time and slot_end_time values directly
        if let startTimeStr = appointment.startTime, !startTimeStr.isEmpty {
            // If we have an end time, use the complete range
            if let endTimeStr = appointment.endTime, !endTimeStr.isEmpty {
                return "\(formatTimeString(startTimeStr)) to \(formatTimeString(endTimeStr))"
            }
            // If we only have start time, calculate end time (1 hour later)
            return "\(formatTimeString(startTimeStr)) to \(calculateEndTime(from: startTimeStr))"
        }
        
        // Fall back to using the time field
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: time)
        
        // Calculate end time (1 hour after start time)
        if let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: time) {
            let endTimeString = formatter.string(from: endTime)
            return "\(startTime) to \(endTimeString)"
        }
        
        return startTime
    }
    
    private func formatTimeString(_ timeStr: String) -> String {
        // Handle "HH:MM:SS" format with seconds
        let components = timeStr.components(separatedBy: ":")
        if components.count >= 2 {
            let hour = Int(components[0]) ?? 0
            let minute = Int(components[1]) ?? 0
            
            let period = hour >= 12 ? "PM" : "AM"
            let hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return String(format: "%d:%02d %@", hour12, minute, period)
        }
        
        // Already formatted or other format, return as is
        return timeStr
    }
    
    private func calculateEndTime(from startTimeStr: String) -> String {
        // Parse the start time
        let components = startTimeStr.components(separatedBy: ":")
        if components.count == 2,
           let hour = Int(components[0]),
           let minute = Int(components[1]) {
            
            let nextHour = (hour + 1) % 24
            let period = nextHour >= 12 ? "PM" : "AM"
            let hour12 = nextHour > 12 ? nextHour - 12 : (nextHour == 0 ? 12 : nextHour)
            return String(format: "%d:%02d %@", hour12, minute, period)
        }
        
        // If we can't parse it, just add "+1 hour"
        return startTimeStr + " +1 hour"
    }
} 