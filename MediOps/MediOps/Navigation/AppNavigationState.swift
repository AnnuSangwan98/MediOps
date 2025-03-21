import SwiftUI

enum AppView {
    case roleSelection
    case patientLogin
    case doctorLogin
    case adminLogin
    case patientSignup
    case patientDetails
    case patientHome
    case doctorHome
    case adminHome
}

class AppNavigationState: ObservableObject {
    @Published var currentView: AppView = .roleSelection
    @Published var isLoggedIn: Bool = false
    @Published private(set) var userRole: UserRole = .patient
    
    func signIn(as role: UserRole) {
        self.userRole = role
        self.isLoggedIn = true
        
        switch role {
        case .patient:
            self.currentView = .patientHome
        case .doctor:
            self.currentView = .doctorHome
        case .hospitalAdmin, .labAdmin, .superAdmin:
            self.currentView = .adminHome
        }
    }
    
    func signOut() {
        self.userRole = .patient
        self.isLoggedIn = false
        self.currentView = .roleSelection
    }
    
    func selectRole(_ role: UserRole) {
        switch role {
        case .patient:
            self.currentView = .patientLogin
        case .doctor:
            self.currentView = .doctorLogin
        case .hospitalAdmin, .labAdmin, .superAdmin:
            self.currentView = .adminLogin
        }
    }
} 