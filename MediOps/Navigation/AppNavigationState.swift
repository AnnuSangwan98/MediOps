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

enum UserRole: String {
    case none = "none"
    case patient = "patient"
    case doctor = "doctor"
    case admin = "admin"
}

class AppNavigationState: ObservableObject {
    @Published var currentView: AppView = .roleSelection
    @Published var isLoggedIn: Bool = false
    @Published private(set) var userRole: UserRole = .none
    
    func signIn(as role: UserRole) {
        self.userRole = role
        self.isLoggedIn = true
        
        switch role {
        case .patient:
            self.currentView = .patientHome
        case .doctor:
            self.currentView = .doctorHome
        case .admin:
            self.currentView = .adminHome
        case .none:
            self.currentView = .roleSelection
        }
    }
    
    func signOut() {
        self.userRole = .none
        self.isLoggedIn = false
        self.currentView = .roleSelection
    }
    
    func selectRole(_ role: UserRole) {
        switch role {
        case .patient:
            self.currentView = .patientLogin
        case .doctor:
            self.currentView = .doctorLogin
        case .admin:
            self.currentView = .adminLogin
        case .none:
            self.currentView = .roleSelection
        }
    }
} 