import Foundation

enum WeekDay: String, CaseIterable, Identifiable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var id: String { self.rawValue }
    
    var isWeekend: Bool {
        self == .saturday || self == .sunday
    }
}

struct DoctorSlot: Identifiable, Codable {
    let id: String
    let doctorId: String
    let day: WeekDay
    let startTime: Date
    let endTime: Date
    let isAvailable: Bool
    
    static func generateUniqueID() -> String {
        return "SLOT" + UUID().uuidString.prefix(8)
    }
}

class DoctorSlotViewModel: ObservableObject {
    @Published var slots: [DoctorSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseController.shared
    
    func addSlot(doctorId: String, day: WeekDay, startTime: Date, endTime: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newSlot = DoctorSlot(
                id: DoctorSlot.generateUniqueID(),
                doctorId: doctorId,
                day: day,
                startTime: startTime,
                endTime: endTime,
                isAvailable: true
            )
            
            // TODO: Add API call to save slot
            
            await MainActor.run {
                slots.append(newSlot)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func fetchSlots(for doctorId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Add API call to fetch slots
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
} 