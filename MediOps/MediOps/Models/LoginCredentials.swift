import Foundation

protocol LoginCredentials {
    var id: String { get set }
    var password: String { get set }
    var idPrefix: String { get }
}

struct AdminCredentials: LoginCredentials {
    var id: String
    var password: String
    var idPrefix: String { "HOS" }
}

struct DoctorCredentials: LoginCredentials {
    var id: String
    var password: String
    var idPrefix: String { "DOC" }
}

struct LabCredentials: LoginCredentials {
    var id: String
    var password: String
    var idPrefix: String { "LAB" }
} 