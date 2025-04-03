import SwiftUI
import Foundation

// Supported languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case spanish = "es"
    case french = "fr"
    case arabic = "ar"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        case .spanish: return "Español (Spanish)"
        case .french: return "Français (French)"
        case .arabic: return "العربية (Arabic)"
        }
    }
}

// Translation Manager to handle localization
class TranslationManager: ObservableObject {
    static let shared = TranslationManager()
    
    @AppStorage("app_language") var selectedLanguage: String = AppLanguage.english.rawValue
    
    // All translations are stored in this dictionary
    private var translations: [String: [String: String]] = [
        // English (default)
        "en": [
            // Common UI elements
            "home": "Home",
            "history": "History",
            "lab_reports": "Lab Reports",
            "blood_donate": "Blood Donate",
            "profile": "Profile",
            "welcome": "Welcome",
            "logout": "Logout",
            "edit": "Edit",
            "cancel": "Cancel",
            "save": "Save",
            "done": "Done",
            "yes_logout": "Yes, Logout",
            "are_you_sure_logout": "Are you sure you want to log out?",
            
            // Profile screen
            "patient_profile": "Patient Profile",
            "personal_information": "Personal Information",
            "address": "Address",
            "phone_number": "Phone Number",
            "blood_group": "Blood Group",
            "language": "Language",
            "unknown": "Unknown",
            "not_provided": "Not provided",
            
            // Home screen
            "hospitals": "Hospitals",
            "upcoming_appointments": "Upcoming Appointments",
            "no_appointments": "No upcoming appointments",
            "view_all": "View All",
            "search_hospitals": "Search hospitals",
            
            // Appointment
            "appointment_details": "Appointment Details",
            "appointment_date": "Appointment Date",
            "appointment_time": "Appointment Time",
            "booking_confirmed": "Thanks, your booking has been confirmed.",
            "email_receipt": "Please check your email for receipt and booking details.",
        ],
        
        // Hindi
        "hi": [
            // Common UI elements
            "home": "होम",
            "history": "इतिहास",
            "lab_reports": "लैब रिपोर्ट",
            "blood_donate": "रक्तदान",
            "profile": "प्रोफाइल",
            "welcome": "स्वागत है",
            "logout": "लॉग आउट",
            "edit": "संपादित करें",
            "cancel": "रद्द करें",
            "save": "सहेजें",
            "done": "हो गया",
            "yes_logout": "हां, लॉग आउट करें",
            "are_you_sure_logout": "क्या आप लॉग आउट करना चाहते हैं?",
            
            // Profile screen
            "patient_profile": "रोगी प्रोफाइल",
            "personal_information": "व्यक्तिगत जानकारी",
            "address": "पता",
            "phone_number": "फोन नंबर",
            "blood_group": "रक्त समूह",
            "language": "भाषा",
            "unknown": "अज्ञात",
            "not_provided": "प्रदान नहीं किया गया",
            
            // Home screen
            "hospitals": "अस्पताल",
            "upcoming_appointments": "आगामी अपॉइंटमेंट",
            "no_appointments": "कोई आगामी अपॉइंटमेंट नहीं",
            "view_all": "सभी देखें",
            "search_hospitals": "अस्पताल खोजें",
            
            // Appointment
            "appointment_details": "अपॉइंटमेंट विवरण",
            "appointment_date": "अपॉइंटमेंट की तारीख",
            "appointment_time": "अपॉइंटमेंट का समय",
            "booking_confirmed": "धन्यवाद, आपकी बुकिंग की पुष्टि हो गई है।",
            "email_receipt": "कृपया रसीद और बुकिंग विवरण के लिए अपना ईमेल देखें।",
        ],
        
        // Spanish
        "es": [
            // Common UI elements
            "home": "Inicio",
            "history": "Historial",
            "lab_reports": "Informes de Laboratorio",
            "blood_donate": "Donar Sangre",
            "profile": "Perfil",
            "welcome": "Bienvenido",
            "logout": "Cerrar Sesión",
            "edit": "Editar",
            "cancel": "Cancelar",
            "save": "Guardar",
            "done": "Listo",
            "yes_logout": "Sí, Cerrar Sesión",
            "are_you_sure_logout": "¿Estás seguro de que quieres cerrar sesión?",
            
            // Profile screen
            "patient_profile": "Perfil del Paciente",
            "personal_information": "Información Personal",
            "address": "Dirección",
            "phone_number": "Número de Teléfono",
            "blood_group": "Grupo Sanguíneo",
            "language": "Idioma",
            "unknown": "Desconocido",
            "not_provided": "No proporcionado",
            
            // Home screen
            "hospitals": "Hospitales",
            "upcoming_appointments": "Próximas Citas",
            "no_appointments": "No hay citas próximas",
            "view_all": "Ver Todo",
            "search_hospitals": "Buscar hospitales",
            
            // Appointment
            "appointment_details": "Detalles de la Cita",
            "appointment_date": "Fecha de la Cita",
            "appointment_time": "Hora de la Cita",
            "booking_confirmed": "Gracias, su reserva ha sido confirmada.",
            "email_receipt": "Por favor revise su correo electrónico para el recibo y los detalles de la reserva.",
        ],
        
        // French
        "fr": [
            // Common UI elements
            "home": "Accueil",
            "history": "Historique",
            "lab_reports": "Rapports de Laboratoire",
            "blood_donate": "Don de Sang",
            "profile": "Profil",
            "welcome": "Bienvenue",
            "logout": "Déconnexion",
            "edit": "Modifier",
            "cancel": "Annuler",
            "save": "Enregistrer",
            "done": "Terminé",
            "yes_logout": "Oui, Se Déconnecter",
            "are_you_sure_logout": "Êtes-vous sûr de vouloir vous déconnecter?",
            
            // Profile screen
            "patient_profile": "Profil du Patient",
            "personal_information": "Informations Personnelles",
            "address": "Adresse",
            "phone_number": "Numéro de Téléphone",
            "blood_group": "Groupe Sanguin",
            "language": "Langue",
            "unknown": "Inconnu",
            "not_provided": "Non fourni",
            
            // Home screen
            "hospitals": "Hôpitaux",
            "upcoming_appointments": "Rendez-vous à Venir",
            "no_appointments": "Aucun rendez-vous à venir",
            "view_all": "Voir Tout",
            "search_hospitals": "Rechercher des hôpitaux",
            
            // Appointment
            "appointment_details": "Détails du Rendez-vous",
            "appointment_date": "Date du Rendez-vous",
            "appointment_time": "Heure du Rendez-vous",
            "booking_confirmed": "Merci, votre réservation a été confirmée.",
            "email_receipt": "Veuillez vérifier votre e-mail pour le reçu et les détails de la réservation.",
        ],
        
        // Arabic
        "ar": [
            // Common UI elements
            "home": "الرئيسية",
            "history": "السجل",
            "lab_reports": "تقارير المختبر",
            "blood_donate": "التبرع بالدم",
            "profile": "الملف الشخصي",
            "welcome": "مرحباً",
            "logout": "تسجيل الخروج",
            "edit": "تعديل",
            "cancel": "إلغاء",
            "save": "حفظ",
            "done": "تم",
            "yes_logout": "نعم، تسجيل الخروج",
            "are_you_sure_logout": "هل أنت متأكد أنك تريد تسجيل الخروج؟",
            
            // Profile screen
            "patient_profile": "ملف المريض",
            "personal_information": "المعلومات الشخصية",
            "address": "العنوان",
            "phone_number": "رقم الهاتف",
            "blood_group": "فصيلة الدم",
            "language": "اللغة",
            "unknown": "غير معروف",
            "not_provided": "غير متوفر",
            
            // Home screen
            "hospitals": "المستشفيات",
            "upcoming_appointments": "المواعيد القادمة",
            "no_appointments": "لا توجد مواعيد قادمة",
            "view_all": "عرض الكل",
            "search_hospitals": "البحث عن مستشفيات",
            
            // Appointment
            "appointment_details": "تفاصيل الموعد",
            "appointment_date": "تاريخ الموعد",
            "appointment_time": "وقت الموعد",
            "booking_confirmed": "شكراً، تم تأكيد حجزك.",
            "email_receipt": "يرجى التحقق من بريدك الإلكتروني للحصول على الإيصال وتفاصيل الحجز.",
        ],
    ]
    
    // Get translation for a key in the currently selected language
    func localized(_ key: String) -> String {
        // Get translations for selected language
        guard let languageDict = translations[selectedLanguage] else {
            // Fallback to English if selected language not available
            return translations["en"]?[key] ?? key
        }
        
        // Return translation if available, otherwise fallback to English or the key itself
        return languageDict[key] ?? translations["en"]?[key] ?? key
    }
    
    // Change the app language
    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language.rawValue
    }
    
    // Get current language as AppLanguage enum
    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .english
    }
}

// Extension for String to easily get localized version
extension String {
    var localized: String {
        TranslationManager.shared.localized(self)
    }
}

// View modifier for applying right-to-left layout for Arabic
struct LocalizedViewModifier: ViewModifier {
    @ObservedObject private var translationManager = TranslationManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, translationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
    }
}

// Extension for View to easily apply localization modifiers
extension View {
    func localizedLayout() -> some View {
        self.modifier(LocalizedViewModifier())
    }
} 