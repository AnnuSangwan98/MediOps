import SwiftUI

struct HospitalCard: View {
    let hospital: HospitalModel
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var showMenu = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Hospital icon
                Image(systemName: "building.2")
                    .font(.system(size: 36))
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hospital.hospitalName)
                        .font(.headline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                    
                    Text(hospital.hospitalCity)
                        .font(.subheadline)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    
                    Text("Address")
                        .font(.caption)
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "stethoscope")
                            .font(.caption)
                        Text("\(hospital.numberOfDoctors) Doctors")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                    
                    if hospital.numberOfAppointments > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(hospital.numberOfAppointments) Appointments")
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
                    }
                }
            }
        }
        // Apply the themed card styling
        .themedHospitalCard()
    }
    
    private var fallbackHospitalImage: some View {
        Image(systemName: "building.2.fill")
            .font(.system(size: 40))
            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.tertiaryAccent : .gray)
            .frame(width: 80, height: 80)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

