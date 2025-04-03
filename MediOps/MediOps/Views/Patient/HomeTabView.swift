//
//  HomeTabView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI
import Foundation

// Supported languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case tamil = "ta"
    case urdu = "ur"
    case kannada = "kn"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        case .tamil: return "தமிழ் (Tamil)"
        case .urdu: return "اردو (Urdu)"
        case .kannada: return "ಕನ್ನಡ (Kannada)"
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
            "blood_donate": "Blood Donation",
            "profile": "Profile",
            "welcome": "Welcome",
            "logout": "Logout",
            "edit": "Edit",
            "cancel": "Cancel",
            "save": "Save",
            "done": "Done",
            "yes_logout": "Yes, Logout",
            "are_you_sure_logout": "Are you sure you want to logout?",
            "coming_soon": "Coming Soon",
            "try_again": "Try Again",
            "error": "Error",
            "ok": "OK",
            "continue": "Continue",
            "change": "Change",
            
            // Profile screen
            "patient_profile": "Patient Profile",
            "personal_information": "Personal Information",
            "address": "Address",
            "phone_number": "Phone Number",
            "blood_group": "Blood Group",
            "language": "Language",
            "unknown": "Unknown",
            "not_provided": "Not Provided",
            
            // Home screen
            "hospitals": "Hospitals",
            "upcoming_appointments": "Upcoming Appointments",
            "no_appointments": "No upcoming appointments",
            "view_all": "View All",
            "search_hospitals": "Search Hospitals",
            "search_by_doctor": "Search by doctor's name",
            "search_results": "Search Results",
            "no_hospitals_found": "No hospitals found",
            "no_lab_reports": "No lab reports available",
            
            // Appointment history
            "appointment_history": "Appointment History",
            "no_appointment_history": "No appointment history",
            "completed_appointments": "Completed Appointments",
            "missed_appointments": "Missed Appointments",
            "cancelled_appointments": "Cancelled Appointments",
            
            // Appointment booking
            "doctors": "Doctors",
            "no_active_doctors": "No Active Doctors Found",
            "no_matching_doctors": "No Matching Doctors",
            "try_adjusting_search": "Try adjusting your search or filters.",
            "book_appointment": "Book Appointment",
            "consultation_fee": "Consultation Fee",
            "review_and_pay": "Review & Pay",
            "appointment": "Appointment",
            "patient_info": "Patient Info",
            "premium_appointment": "Premium Appointment",
            "payment_details": "Payment Details",
            "consultation_fees": "Consultation Fees",
            "booking_fee": "Booking Fee",
            "premium_fee": "Premium Fee",
            "total_pay": "Total Pay",
            "pay": "Pay",
            "confirm_payment": "Confirm Payment",
            "pay_with": "Pay with",
            "bill_details": "Bill Details",
            "swipe_to_pay": "Swipe to Pay",
            "processing": "Processing...",
            "slots": "Slots",
            "select_date": "Select Date",
            "loading_slots": "Loading available slots...",
            "no_available_slots": "No available slots for this date. Please select another date or doctor.",
            "no_doctor_availability": "This doctor doesn't have any availability schedule set up yet.",
            "invalid_availability_data": "Invalid availability data format",
            "error_fetching_availability": "Error fetching doctor availability",
            "user_id_not_found": "User ID not found",
            "patient_verification_failed": "Could not verify patient record",
            "medical_consultation": "Medical consultation",
            "error_creating_appointment": "Error creating appointment",
            
            // Appointment
            "appointment_details": "Appointment Details",
            "appointment_date": "Appointment Date",
            "appointment_time": "Appointment Time",
            "booking_confirmed": "Thank you, your booking is confirmed.",
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
            "coming_soon": "जल्द आ रहा है",
            "try_again": "फिर से प्रयास करें",
            "error": "त्रुटि",
            "ok": "ठीक है",
            "continue": "जारी रखें",
            "change": "बदलें",
            
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
            "search_by_doctor": "डॉक्टर के नाम से खोजें",
            "search_results": "खोज परिणाम",
            "no_hospitals_found": "कोई अस्पताल नहीं मिला",
            "no_lab_reports": "कोई लैब रिपोर्ट उपलब्ध नहीं है",
            
            // Appointment history
            "appointment_history": "अपॉइंटमेंट इतिहास",
            "no_appointment_history": "कोई अपॉइंटमेंट इतिहास नहीं",
            "completed_appointments": "पूर्ण अपॉइंटमेंट",
            "missed_appointments": "छूटे हुए अपॉइंटमेंट",
            "cancelled_appointments": "रद्द किए गए अपॉइंटमेंट",
            
            // Appointment booking
            "doctors": "डॉक्टर्स",
            "no_active_doctors": "कोई सक्रिय डॉक्टर नहीं मिले",
            "no_matching_doctors": "कोई मिलते जुलते डॉक्टर नहीं मिले",
            "try_adjusting_search": "अपनी खोज या फिल्टर को समायोजित करने का प्रयास करें",
            "book_appointment": "अपॉइंटमेंट बुक करें",
            "consultation_fee": "परामर्श शुल्क",
            "review_and_pay": "समीक्षा और भुगतान",
            "appointment": "अपॉइंटमेंट",
            "patient_info": "रोगी की जानकारी",
            "premium_appointment": "प्रीमियम अपॉइंटमेंट",
            "payment_details": "भुगतान विवरण",
            "consultation_fees": "परामर्श शुल्क",
            "booking_fee": "बुकिंग शुल्क",
            "premium_fee": "प्रीमियम शुल्क",
            "total_pay": "कुल भुगतान",
            "pay": "भुगतान करें",
            "confirm_payment": "भुगतान की पुष्टि करें",
            "pay_with": "भुगतान विधि",
            "bill_details": "बिल विवरण",
            "swipe_to_pay": "भुगतान के लिए स्वाइप करें",
            "processing": "प्रोसेसिंग हो रही है",
            "slots": "स्लॉट्स",
            "select_date": "तारीख चुनें",
            "loading_slots": "उपलब्ध स्लॉट्स लोड हो रहे हैं...",
            "no_available_slots": "इस तारीख के लिए कोई उपलब्ध स्लॉट्स नहीं हैं। कृपया दूसरी तारीख या डॉक्टर चुनें।",
            "no_doctor_availability": "इस डॉक्टर की कोई उपलब्धता अनुसूची अभी तक सेट नहीं की गई है।",
            "invalid_availability_data": "अवैध उपलब्धता डेटा प्रारूप",
            "error_fetching_availability": "डॉक्टर उपलब्धता प्राप्त करने में त्रुटि",
            "user_id_not_found": "उपयोगकर्ता आईडी नहीं मिली",
            "patient_verification_failed": "रोगी रिकॉर्ड सत्यापित नहीं किया जा सका",
            "medical_consultation": "चिकित्सा परामर्श",
            "error_creating_appointment": "अपॉइंटमेंट बनाने में त्रुटि",
            
            // Appointment
            "appointment_details": "अपॉइंटमेंट विवरण",
            "appointment_date": "अपॉइंटमेंट की तारीख",
            "appointment_time": "अपॉइंटमेंट का समय",
            "booking_confirmed": "धन्यवाद, आपकी बुकिंग की पुष्टि हो गई है।",
            "email_receipt": "कृपया रसीद और बुकिंग विवरण के लिए अपना ईमेल देखें।",
        ],
        
        // Tamil
        "ta": [
            "home": "முகப்பு",
            "history": "வரலாறு",
            "lab_reports": "ஆய்வக அறிக்கைகள்",
            "blood_donate": "இரத்த தானம்",
            "profile": "சுயவிவரம்",
            "welcome": "வரவேற்கிறோம்",
            "logout": "வெளியேறு",
            "edit": "திருத்து",
            "cancel": "ரத்து செய்",
            "save": "சேமி",
            "done": "முடிந்தது",
            "yes_logout": "ஆம், வெளியேறு",
            "are_you_sure_logout": "நீங்கள் வெளியேற விரும்புகிறீர்களா?",
            "coming_soon": "விரைவில் வருகிறது",
            "try_again": "மீண்டும் முயற்சிக்கவும்",
            "error": "பிழை",
            "ok": "சரி",
            "continue": "தொடரவும்",
            "change": "மாற்றவும்",
            
            // Profile screen
            "patient_profile": "நோயாளி சுயவிவரம்",
            "personal_information": "தனிப்பட்ட தகவல்",
            "address": "முகவரி",
            "phone_number": "தொலைபேசி எண்",
            "blood_group": "இரத்த வகை",
            "language": "மொழி",
            "unknown": "தெரியாதது",
            "not_provided": "வழங்கப்படவில்லை",
            
            // Home screen
            "search_results": "தேடல் முடிவுகள்",
            "no_hospitals_found": "மருத்துவமனைகள் எதுவும் இல்லை",
            "search_hospitals": "மருத்துவமனைகளைத் தேடுங்கள்",
            "search_by_doctor": "மருத்துவர் பெயரால் தேடுங்கள்",
            "no_lab_reports": "ஆய்வக அறிக்கைகள் இல்லை",
            "hospitals": "மருத்துவமனைகள்",
            "upcoming_appointments": "வரவிருக்கும் சந்திப்புகள்",
            "no_appointments": "வரவிருக்கும் சந்திப்புகள் இல்லை",
            "view_all": "அனைத்தையும் காண்க",
            
            // Appointment history
            "appointment_history": "சந்திப்பு வரலாறு",
            "no_appointment_history": "சந்திப்பு வரலாறு இல்லை",
            "completed_appointments": "முடிந்த சந்திப்புகள்",
            "missed_appointments": "தவறிய சந்திப்புகள்",
            "cancelled_appointments": "ரத்து செய்யப்பட்ட சந்திப்புகள்",
            
            // Appointment booking
            "doctors": "மருத்துவர்கள்",
            "no_active_doctors": "செயலில் உள்ள மருத்துவர்கள் இல்லை",
            "no_matching_doctors": "பொருந்தும் மருத்துவர்கள் இல்லை",
            "try_adjusting_search": "உங்கள் தேடலை அல்லது வடிகட்டிகளை சரிசெய்ய முயற்சிக்கவும்",
            "book_appointment": "சந்திப்பை பதிவு செய்க",
            "consultation_fee": "ஆலோசனை கட்டணம்",
            "review_and_pay": "சரிபார்த்து செலுத்துங்கள்",
            "appointment": "சந்திப்பு",
            "patient_info": "நோயாளி தகவல்",
            "premium_appointment": "பிரீமியம் சந்திப்பு",
            "payment_details": "கட்டண விவரங்கள்",
            "consultation_fees": "ஆலோசனை கட்டணம்",
            "booking_fee": "பதிவு கட்டணம்",
            "premium_fee": "பிரீமியம் கட்டணம்",
            "total_pay": "மொத்தம் செலுத்த",
            "pay": "செலுத்து",
            "confirm_payment": "கட்டணத்தை உறுதிப்படுத்தவும்",
            "pay_with": "செலுத்தும் முறை",
            "bill_details": "பில் விவரங்கள்",
            "swipe_to_pay": "செலுத்த ஸ்வைப் செய்யவும்",
            "processing": "செயலாக்கப்படுகிறது",
            "slots": "இடங்கள்",
            "select_date": "தேதியைத் தேர்ந்தெடுக்கவும்",
            "loading_slots": "கிடைக்கக்கூடிய இடங்களை ஏற்றுகிறது...",
            "no_available_slots": "இந்த தேதிக்கு கிடைக்கக்கூடிய இடங்கள் இல்லை. வேறு தேதி அல்லது மருத்துவரைத் தேர்ந்தெடுக்கவும்.",
            "no_doctor_availability": "இந்த மருத்துவர் இன்னும் எந்த கிடைக்கும் அட்டவணையையும் அமைக்கவில்லை.",
            "invalid_availability_data": "தவறான கிடைக்கும் தரவு வடிவம்",
            "error_fetching_availability": "மருத்துவர் கிடைப்பதை பெறுவதில் பிழை",
            
            // Appointment
            "booking_confirmed": "நன்றி, உங்கள் பதிவு உறுதிப்படுத்தப்பட்டது.",
            "email_receipt": "ரசீது மற்றும் பதிவு விவரங்களுக்கு உங்கள் மின்னஞ்சலைப் பாருங்கள்.",
            "appointment_details": "சந்திப்பு விவரங்கள்",
            "appointment_date": "சந்திப்பு தேதி",
            "appointment_time": "சந்திப்பு நேரம்",
            "user_id_not_found": "பயனர் ஐடி கிடைக்கவில்லை",
            "patient_verification_failed": "நோயாளி பதிவு சரிபார்க்க முடியவில்லை",
            "medical_consultation": "மருத்துவ ஆலோசனை",
            "error_creating_appointment": "அப்பாய்ன்ட்மென்ட் உருவாக்குவதில் பிழை",
        ],
        
        // Urdu
        "ur": [
            "home": "ہوم",
            "history": "تاریخ",
            "lab_reports": "لیب رپورٹس",
            "blood_donate": "خون کا عطیہ",
            "profile": "پروفائل",
            "welcome": "خوش آمدید",
            "logout": "لاگ آؤٹ",
            "edit": "ترمیم",
            "cancel": "منسوخ",
            "save": "محفوظ کریں",
            "done": "ہو گیا",
            "yes_logout": "ہاں، لاگ آؤٹ کریں",
            "are_you_sure_logout": "کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟",
            "coming_soon": "جلد آ رہا ہے",
            "search_results": "تلاش کے نتائج",
            "no_hospitals_found": "کوئی ہسپتال نہیں ملا",
            "search_hospitals": "ہسپتال تلاش کریں",
            "search_by_doctor": "ڈاکٹر کے نام سے تلاش کریں",
            "no_lab_reports": "کوئی لیب رپورٹ دستیاب نہیں ہے",
            "appointment_history": "اپائنٹمنٹ کی تاریخ",
            "no_appointment_history": "کوئی اپائنٹمنٹ تاریخ نہیں",
            "completed_appointments": "مکمل اپائنٹمنٹس",
            "missed_appointments": "چھوٹی ہوئی اپائنٹمنٹس",
            "cancelled_appointments": "منسوخ شدہ اپائنٹمنٹس",
            "hospitals": "ہسپتال",
            "upcoming_appointments": "آنے والی اپوائنٹمنٹس",
            "no_appointments": "کوئی آنے والی اپوائنٹمنٹ نہیں",
            "view_all": "سب دیکھیں",
            "doctors": "ڈاکٹرز",
            "no_active_doctors": "کوئی متحرک ڈاکٹر نہیں ملے",
            "no_matching_doctors": "کوئی میل کھاتے ڈاکٹر نہیں ملے",
            "try_adjusting_search": "اپنی تلاش یا فلٹرز کو ایڈجسٹ کرنے کی کوشش کریں",
            "book_appointment": "اپوائنٹمنٹ بک کریں",
            "consultation_fee": "مشاورت فیس",
            "review_and_pay": "جائزہ اور ادائیگی",
            "appointment": "اپوائنٹمنٹ",
            "patient_info": "مریض کی معلومات",
            "premium_appointment": "پریمیم اپوائنٹمنٹ",
            "payment_details": "ادائیگی کی تفصیلات",
            "consultation_fees": "مشاورت فیس",
            "booking_fee": "بکنگ فیس",
            "premium_fee": "پریمیم فیس",
            "total_pay": "کل ادائیگی",
            "pay": "ادائیگی",
            "confirm_payment": "ادائیگی کی تصدیق کریں",
            "pay_with": "ادائیگی کا ذریعہ",
            "bill_details": "بل کی تفصیلات",
            "swipe_to_pay": "ادائیگی کے لیے سوائپ کریں",
            "processing": "کارروائی جاری ہے",
            "slots": "سلاٹس",
            "booking_confirmed": "شکریہ، آپ کی بکنگ کی تصدیق ہو گئی ہے۔",
            "email_receipt": "براہ کرم رسید اور بکنگ کی تفصیلات کے لیے اپنا ای میل چیک کریں۔",
            "appointment_details": "اپوائنٹمنٹ کی تفصیلات",
            "appointment_date": "اپوائنٹمنٹ کی تاریخ",
            "appointment_time": "اپوائنٹمنٹ کا وقت",
            "error": "خرابی",
            "ok": "ٹھیک ہے",
            "continue": "جاری رکھیں",
            "change": "تبدیل کریں",
            "select_date": "تاریخ منتخب کریں",
            "loading_slots": "دستیاب سلاٹس لوڈ ہو رہے ہیں...",
            "no_available_slots": "اس تاریخ کے لیے کوئی دستیاب سلاٹس نہیں ہیں۔ براہ کرم کوئی دوسری تاریخ یا ڈاکٹر منتخب کریں۔",
            "no_doctor_availability": "اس ڈاکٹر کی کوئی دستیابی شیڈول ابھی تک مرتب نہیں کی گئی ہے۔",
            "invalid_availability_data": "غلط دستیابی ڈیٹا فارمیٹ",
            "error_fetching_availability": "ڈاکٹر کی دستیابی حاصل کرنے میں خرابی",
            "user_id_not_found": "صارف کی شناخت نہیں ملی",
            "patient_verification_failed": "مریض کا ریکارڈ تصدیق نہیں کیا جا سکا",
            "medical_consultation": "طبی مشاورت",
            "error_creating_appointment": "اپائنٹمنٹ بنانے میں خرابی",
            
            // Profile screen
            "patient_profile": "مریض کا پروفائل",
            "personal_information": "ذاتی معلومات",
            "address": "پتہ",
            "phone_number": "فون نمبر",
            "blood_group": "بلڈ گروپ",
            "language": "زبان",
            "unknown": "نامعلوم",
            "not_provided": "فراہم نہیں کیا گیا",
        ],
        
        // Kannada
        "kn": [
            "home": "ಮುಖಪುಟ",
            "history": "ಇತಿಹಾಸ",
            "lab_reports": "ಲ್ಯಾಬ್ ವರದಿಗಳು",
            "blood_donate": "ರಕ್ತದಾನ",
            "profile": "ಪ್ರೊಫೈಲ್",
            "welcome": "ಸ್ವಾಗತ",
            "logout": "ಲಾಗ್ ಔಟ್",
            "edit": "ಸಂಪಾದಿಸಿ",
            "cancel": "ರದ್ದುಮಾಡಿ",
            "save": "ಉಳಿಸಿ",
            "done": "ಮುಗಿದಿದೆ",
            "yes_logout": "ಹೌದು, ಲಾಗ್ ಔಟ್",
            "are_you_sure_logout": "ನೀವು ಖಚಿತವಾಗಿಯೂ ಲಾಗ್ ಔಟ್ ಮಾಡಲು ಬಯಸುವಿರಾ?",
            "coming_soon": "ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ",
            "try_again": "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ",
            "error": "ದೋಷ",
            "ok": "ಸರಿ",
            "continue": "ಮುಂದುವರಿಸಿ",
            "change": "ಬದಲಾಯಿಸಿ",
            
            // Profile screen
            "patient_profile": "ರೋಗಿಯ ಪ್ರೊಫೈಲ್",
            "personal_information": "ವೈಯಕ್ತಿಕ ಮಾಹಿತಿ",
            "address": "ವಿಳಾಸ",
            "phone_number": "ಫೋನ್ ಸಂಖ್ಯೆ",
            "blood_group": "ರಕ್ತ ಗುಂಪು",
            "language": "ಭಾಷೆ",
            "unknown": "ಅಜ್ಞಾತ",
            "not_provided": "ಒದಗಿಸಿಲ್ಲ",
            "appointment_time": "ಅಪಾಯಿಂಟ್ಮೆಂಟ್ ಸಮಯ",
            "user_id_not_found": "ಬಳಕೆದಾರ ಐಡಿ ಕಂಡುಬಂದಿಲ್ಲ",
            "patient_verification_failed": "ರೋಗಿಯ ದಾಖಲೆಯನ್ನು ಪರಿಶೀಲಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ",
            "medical_consultation": "ವೈದ್ಯಕೀಯ ಸಮಾಲೋಚನೆ",
            "error_creating_appointment": "ಅಪಾಯಿಂಟ್ಮೆಂಟ್ ರಚಿಸುವಲ್ಲಿ ದೋಷ",
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
            // We don't need right-to-left layout as we only support English and Indian languages
            .environment(\.layoutDirection, .leftToRight)
    }
}

// Extension for View to easily apply localization modifiers
extension View {
    func localizedLayout() -> some View {
        self.modifier(LocalizedViewModifier())
    }
}

// Define the missing ActiveSheet enum
enum ActiveSheet: Identifiable {
    case doctorList(hospital: HospitalModel)
    case patientProfile
    case addVitals
    
    var id: Int {
        switch self {
        case .doctorList: return 0
        case .patientProfile: return 1
        case .addVitals: return 2
        }
    }
}

struct HomeTabView: View {
    @ObservedObject var hospitalVM = HospitalViewModel.shared
    @StateObject var appointmentManager = AppointmentManager.shared
    @StateObject private var labReportManager = LabReportManager.shared
    @State private var showProfile = false
    @State private var showAddVitals = false
    @State private var selectedHospital: HospitalModel?
    @State private var activeSheet: ActiveSheet?
    @State private var coordinateSpace = UUID()
    @State private var profileController = PatientProfileController()
    @State private var selectedTab = 0
    @AppStorage("current_user_id") private var currentUserId: String?
    @AppStorage("userId") private var userId: String?
    @State private var selectedHistoryType = 0
    @ObservedObject private var translationManager = TranslationManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Apply background gradient to the main container
            LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                homeTab
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("home".localized)
                    }
                    .tag(0)
                    .onAppear {
                        // Refresh appointments each time home tab appears
                        if selectedTab == 0 {
                            print("📱 Home tab appeared - refreshing appointments")
                            appointmentManager.refreshAppointments()
                        }
                    }
                
                historyTab
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                        Text("history".localized)
                    }
                    .tag(1)
                
                labReportsTab
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "doc.text.fill" : "doc.text")
                        Text("lab_reports".localized)
                    }
                    .tag(2)
                
                bloodDonateTab
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "drop.fill" : "drop")
                        Text("blood_donate".localized)
                    }
                    .tag(3)
            }
            .accentColor(.teal)
            .onAppear {
                // Configure navigation bar appearance
                configureNavigationBar()
                
                // Customize the TabView appearance
                UITabBar.appearance().backgroundColor = UIColor.systemBackground
                UITabBar.appearance().backgroundImage = UIImage()
                
                print("📱 HomeTabView appeared with currentUserId: \(currentUserId ?? "nil") and userId: \(userId ?? "nil")")
                
                // Ensure user IDs are synchronized
                if let currentId = currentUserId, userId == nil {
                    print("📱 Synchronizing userId with currentUserId: \(currentId)")
                    userId = currentId
                } else if let id = userId, currentUserId == nil {
                    print("📱 Synchronizing currentUserId with userId: \(id)")
                    currentUserId = id
                }
                
                // If no userId is available, use a test ID
                if userId == nil && currentUserId == nil {
                    let testUserId = "USER_\(Int(Date().timeIntervalSince1970))"
                    print("⚠️ No user ID found. Setting test ID: \(testUserId)")
                    userId = testUserId
                    currentUserId = testUserId
                    UserDefaults.standard.synchronize()
                }
                
                // Load profile data for debugging
                Task {
                    if let id = userId ?? currentUserId {
                        print("📱 HomeTabView: Loading profile with user ID: \(id)")
                        await profileController.loadProfile(userId: id)
                        if let patient = profileController.patient {
                            print("📱 Successfully loaded profile for: \(patient.name)")
                            
                            // Fix appointment times when profile is loaded
                            print("🔧 Running appointment time fix")
                            try? await fixAppointmentTimes(for: patient.id)
                        } else if let error = profileController.error {
                            print("📱 Error loading profile: \(error.localizedDescription)")
                            
                            // Try creating a test patient if loading failed
                            print("📱 Attempting to create test patient...")
                            let success = await profileController.createAndInsertTestPatientInSupabase()
                            if success {
                                print("✅ Test patient created and loaded successfully")
                            } else {
                                print("❌ Failed to create test patient")
                            }
                        } else {
                            print("📱 No profile data loaded")
                        }
                    } else {
                        print("❌ HomeTabView: No user ID available for profile loading")
                    }
                }
                
                // Initial refresh of appointments
                appointmentManager.refreshAppointments()
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .localizedLayout()
    }
    
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Apply consistent background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header section
                    headerSection
                        .padding(.top, 8)
                    
                    // Divider
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    // Main content with simplified layout
                    ScrollView {
                        VStack(spacing: 20) {
                            if !hospitalVM.searchText.isEmpty {
                                // Simple search bar
                                searchAndFilterSection
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                searchResultsSection
                                    .padding(.top, 5)
                            } else {
                                searchAndFilterSection
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                upcomingAppointmentsSection
                                    .padding(.top, 5)
                                
                                // Show all hospitals with simplified styling
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("hospitals".localized)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                    
                                    if hospitalVM.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.2)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else if let error = hospitalVM.error {
                                        Text("Error loading hospitals: \(error.localizedDescription)")
                                            .foregroundColor(.red)
                                            .font(.callout)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                            .padding(.horizontal)
                                    } else if !hospitalVM.hospitals.isEmpty {
                                        ForEach(hospitalVM.hospitals) { hospital in
                                            NavigationLink {
                                                DoctorListView(hospital: hospital)
                                            } label: {
                                                HospitalCard(hospital: hospital)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .padding(.horizontal)
                                        }
                                    } else {
                                        Text("no_hospitals_found".localized)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.white)
                                            )
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.bottom, 30)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                    .refreshable {
                        await refreshHospitals()
                    }
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .bottom)
            .task {
                print("🔄 Home tab task started - refreshing hospitals")
                await refreshHospitals()
                
                if let userId = userId {
                    print("🔄 Fetching appointments for user ID: \(userId)")
                    try? await hospitalVM.fetchAppointments(for: userId)
                    
                    // Load patient profile data
                    if profileController.patient == nil {
                        print("🔄 Loading patient profile data")
                        await profileController.loadProfile(userId: userId)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                PatientProfileView(profileController: profileController)
            }
        }
    }
    
    // Helper function to refresh hospitals and cities
    private func refreshHospitals() async {
        // Check Supabase connectivity first
        let supabase = SupabaseController.shared
        let isConnected = await supabase.checkConnectivity()
        
        if isConnected {
            // Fetch hospitals and cities
            await hospitalVM.fetchHospitals()
            await hospitalVM.fetchAvailableCities()
            
            if !hospitalVM.hospitals.isEmpty {
                // Add test doctors to hospitals if needed
                await hospitalVM.addTestDoctorsToHospitals()
                
                // Update doctor counts for all hospitals
                await hospitalVM.updateDoctorCounts()
                
                // Ensure doctor counts are reflected immediately
                await MainActor.run {
                    // Force UI refresh for hospital cards
                    let updatedHospitals = hospitalVM.hospitals
                    hospitalVM.hospitals = []
                    
                    // Reapply the updated hospitals after a tiny delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.hospitalVM.hospitals = updatedHospitals
                    }
                }
            }
        } else {
            await MainActor.run {
                hospitalVM.error = NSError(
                    domain: "HospitalViewModel",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot connect to server. Please check your internet connection and try again."]
                )
            }
        }
    }
    
    private var historyTab: some View {
        NavigationStack {
            ZStack {
                // Consistent background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                List {
                    // Filter appointments by status
                    let completedAppointments = appointmentManager.appointments.filter { $0.status == .completed }
                    let cancelledAppointments = appointmentManager.appointments.filter { $0.status == .cancelled }
                    let missedAppointments = appointmentManager.appointments.filter { $0.status == .missed }
                    
                    if completedAppointments.isEmpty && cancelledAppointments.isEmpty && missedAppointments.isEmpty {
                        Text("No appointment history")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        if !completedAppointments.isEmpty {
                            Section(header: Text("Completed Appointments").foregroundColor(.teal)) {
                                ForEach(completedAppointments) { appointment in
                                    NavigationLink(destination: PrescriptionDetailView(appointment: appointment)) {
                                        AppointmentHistoryCard(appointment: appointment)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
                                    .listRowBackground(Color.green.opacity(0.1))
                                }
                            }
                        }
                        
                        if !missedAppointments.isEmpty {
                            Section(header: Text("Missed Appointments").foregroundColor(.teal)) {
                                ForEach(missedAppointments) { appointment in
                                    AppointmentHistoryCard(appointment: appointment, isMissed: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.orange.opacity(0.1))
                                }
                            }
                        }
                        
                        if !cancelledAppointments.isEmpty {
                            Section(header: Text("Cancelled Appointments").foregroundColor(.teal)) {
                                ForEach(cancelledAppointments) { appointment in
                                    AppointmentHistoryCard(appointment: appointment, isCancelled: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.red.opacity(0.1))
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden) // Hide default list background
                .refreshable {
                    print("🔄 Manually refreshing appointments history")
                    appointmentManager.refreshAppointments()
                }
            }
            .navigationTitle("history".localized)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                print("📱 History tab appeared - refreshing appointments")
                appointmentManager.refreshAppointments()
            }
        }
    }
    
    private var labReportsTab: some View {
        NavigationStack {
            ZStack {
                // Consistent background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                labReportsSection
                    .scrollContentBackground(.hidden) // Hide default list background if this contains a List
            }
            .navigationTitle("lab_reports".localized)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var bloodDonateTab: some View {
        NavigationStack {
            ZStack {
                // Consistent background gradient
                LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.1), Color.white]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                // Content will go here when implemented
                VStack {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.teal)
                        
                    Text("blood_donate".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("coming_soon".localized)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
            }
            .navigationTitle("blood_donate".localized)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.teal.opacity(0.1), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // Simplified header section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("welcome".localized)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                if let patientName = profileController.patient?.name {
                    Text(patientName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                } else {
                    Text("Patient")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            Spacer()
            
            Button(action: {
                // Create and initialize the profile controller before showing the sheet
                let controller = PatientProfileController()
                
                // Preload the patient data
                if let userId = UserDefaults.standard.string(forKey: "userId") ?? 
                       UserDefaults.standard.string(forKey: "current_user_id") {
                    Task {
                        await controller.loadProfile(userId: userId)
                        
                        // Show the profile after we've attempted to load data
                        DispatchQueue.main.async {
                            self.profileController = controller
                            self.showProfile = true
                        }
                    }
                } else {
                    // If no user ID, still show the profile with the empty controller
                    self.profileController = controller
                    self.showProfile = true
                }
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.teal)
            }
        }
        .padding(.horizontal)
    }

    // Update the searchAndFilterSection to use localized text
    private var searchAndFilterSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("search_hospitals".localized, text: $hospitalVM.searchText)
                    .foregroundColor(.primary)
                
                if !hospitalVM.searchText.isEmpty {
                    Button(action: {
                        hospitalVM.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }

    // Update the upcomingAppointmentsSection to use localized text
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("upcoming_appointments".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: AppointmentHistoryView()) {
                    Text("view_all".localized)
                        .foregroundColor(.teal)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            if appointmentManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if appointmentManager.upcomingAppointments.isEmpty {
                Text("no_appointments".localized)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(appointmentManager.upcomingAppointments) { appointment in
                            AppointmentCard(appointment: appointment)
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // Simplified search results section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("search_results".localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal)

            if hospitalVM.filteredHospitals.isEmpty {
                Text("no_hospitals_found".localized)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                    .padding(.horizontal)
            } else {
                ForEach(hospitalVM.filteredHospitals) { hospital in
                    NavigationLink {
                        DoctorListView(hospital: hospital)
                    } label: {
                        HospitalCard(hospital: hospital)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
    }

    private var labReportsSection: some View {
        List {
            if labReportManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else if let error = labReportManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else if labReportManager.labReports.isEmpty {
                Text("no_lab_reports".localized)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(labReportManager.labReports) { report in
                    PatientLabReportCard(report: report)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .scrollContentBackground(.hidden) // Hide default list background
        .refreshable {
            if let userId = userId {
                // First get the patient's PAT ID from patients table
                Task {
                    do {
                        // Use either method to fetch patient ID
                        struct PatientIds: Codable {
                            var patient_id: String
                        }

                        let patient: [PatientIds] = try await SupabaseController.shared.client
                            .from("patients")
                            .select("patient_id")
                            .eq("user_id", value: userId)
                            .execute()
                            .value

                        if !patient.isEmpty {
                            labReportManager.fetchLabReports(for: patient[0].patient_id)
                        } else {
                            print("❌ No patient found with user ID: \(userId)")
                        }
                    } catch {
                        print("❌ Error getting patient ID: \(error)")
                    }
                }
            }
        }
    }
    
    // Pull-to-refresh control
    struct RefreshControl: View {
        var coordinateSpace: CoordinateSpace
        var onRefresh: () -> Void
        
        @State private var isRefreshing = false
        
        var body: some View {
            GeometryReader { geometry in
                if geometry.frame(in: coordinateSpace).minY > 50 {
                    Spacer()
                        .onAppear {
                            if !isRefreshing {
                                isRefreshing = true
                                onRefresh()
                                
                                // Reset after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isRefreshing = false
                                }
                            }
                        }
                } else if geometry.frame(in: coordinateSpace).minY < 1 {
                    Spacer()
                        .onAppear {
                            isRefreshing = false
                        }
                }
                
                HStack {
                    Spacer()
                    if isRefreshing {
                        ProgressView()
                    } else if geometry.frame(in: coordinateSpace).minY > 20 {
                        Text("Release to refresh")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if geometry.frame(in: coordinateSpace).minY > 5 {
                        Text("Pull to refresh")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .frame(height: geometry.frame(in: coordinateSpace).minY > 0 ? geometry.frame(in: coordinateSpace).minY : 0)
                .offset(y: -10)
            }
            .frame(height: 50)
        }
    }

    // Helper function to fix appointment times
    private func fixAppointmentTimes(for patientId: String) async throws {
        print("🔧 TIMEFIXER: Starting fix for patient ID: \(patientId)")
        let supabase = SupabaseController.shared
        
        // Get all appointments for this patient
        let appointments = try await supabase.select(
            from: "appointments",
            where: "patient_id",
            equals: patientId
        )
        
        print("🔍 TIMEFIXER: Found \(appointments.count) appointments to check")
        
        var fixedCount = 0
        for data in appointments {
            guard let id = data["id"] as? String,
                  let slotId = data["availability_slot_id"] as? Int else {
                print("⚠️ TIMEFIXER: Skipping appointment without ID or slot ID")
                continue
            }
            
            let hasValidStartTime = data["slot_time"] as? String != nil && !(data["slot_time"] as? String)!.isEmpty
            let hasValidEndTime = data["slot_end_time"] as? String != nil && !(data["slot_end_time"] as? String)!.isEmpty
            
            // Only fix appointments with missing or empty time slots
            if !hasValidStartTime || !hasValidEndTime {
                print("🔧 TIMEFIXER: Fixing time slots for appointment \(id)")
                do {
                    // Generate time slots based on slot ID
                    let baseHour = 9 + (slotId % 8) // This gives hours between 9 and 16 (9 AM to 4 PM)
                    let startTime = String(format: "%02d:00", baseHour)
                    let endTime = String(format: "%02d:00", baseHour + 1)
                    
                    // Update the appointment with generated times
                    let updateResult = try await supabase.update(
                        table: "appointments",
                        id: id,
                        data: [
                            "slot_time": startTime,
                            "slot_end_time": endTime
                        ]
                    )
                    
                    print("✅ TIMEFIXER: Updated appointment \(id) with times \(startTime)-\(endTime)")
                    fixedCount += 1
                } catch {
                    print("❌ TIMEFIXER: Error fixing time slots: \(error.localizedDescription)")
                }
            }
        }
        
        print("🎉 TIMEFIXER: Fixed time slots for \(fixedCount) appointments")
        
        // Refresh the appointments list if we fixed any
        if fixedCount > 0 {
            try await hospitalVM.fetchAppointments(for: patientId)
        }
    }

    // Helper debugging function to check doctor counts
    private func debugHospitalDoctorCounts() async {
        print("🔍 DEBUG: Checking hospital doctor counts directly...")
        
        let supabase = SupabaseController.shared
        
        // Check each hospital in the view model
        for hospital in hospitalVM.hospitals {
            do {
                let sqlQuery = """
                SELECT COUNT(*) as doctor_count 
                FROM doctors 
                WHERE hospital_id = '\(hospital.id)'
                """
                
                let results = try await supabase.executeSQL(sql: sqlQuery)
                
                if let firstResult = results.first, let count = firstResult["doctor_count"] as? Int {
                    print("🏥 Hospital: \(hospital.hospitalName) - SQL count: \(count), Model count: \(hospital.numberOfDoctors)")
                    
                    // If counts don't match, print a warning
                    if count != hospital.numberOfDoctors {
                        print("⚠️ Mismatch in doctor counts for \(hospital.hospitalName)!")
                    }
                } else {
                    print("❌ Could not get doctor count from SQL for \(hospital.hospitalName)")
                }
            } catch {
                print("❌ Error checking doctor count for \(hospital.hospitalName): \(error.localizedDescription)")
            }
        }
    }

    // Add this method to handle navigation Bar appearance consistently
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.teal.opacity(0.1))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.teal)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct AppointmentHistoryCard: View {
    let appointment: Appointment
    var isCancelled: Bool = false
    var isMissed: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                    Text(appointment.doctor.specialization)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    // Always use English for these statuses as requested
                    Text(isCancelled ? "Cancelled" : isMissed ? "Missed" : "Completed")
                        .font(.caption)
                        .foregroundColor(isCancelled ? .red : isMissed ? .orange : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isCancelled ? Color.red.opacity(0.1) : isMissed ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.teal)
                Text(appointment.date.formatted(date: .long, time: .omitted))
                Spacer()
                Image(systemName: "clock")
                    .foregroundColor(.teal)
                let endTime = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.time)!
                Text("\(appointment.time.formatted(date: .omitted, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .teal.opacity(0.1), radius: 5)
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}

// MARK: - HospitalSearchBar Component
struct HospitalSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.teal)
            TextField("Search hospitals...", text: $searchText)
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.teal)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .teal.opacity(0.2), radius: 3)
        )
    }
}
