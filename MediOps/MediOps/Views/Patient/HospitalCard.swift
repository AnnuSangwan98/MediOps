import SwiftUI

struct HospitalCard: View {
    let hospital: HospitalModel
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    @State private var showMenu = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Hospital Image
                if let imageUrl = hospital.hospitalProfileImage,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure(_):
                            fallbackHospitalImage
                        case .empty:
                            fallbackHospitalImage
                        @unknown default:
                            fallbackHospitalImage
                        }
                    }
                } else {
                    fallbackHospitalImage
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Hospital Name and Status
                    HStack {
                        Text(hospital.hospitalName)
                            .font(.headline)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.primaryText : .black)
                        
                        Spacer()
                        
                        // Add menu button if edit/delete functions are provided
                        if onEdit != nil || onDelete != nil {
                            Menu {
                                if let editAction = onEdit {
                                    Button(action: editAction) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                                if let deleteAction = onDelete {
                                    Button(action: deleteAction) {
                                        Label("Delete", systemImage: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    // City/Location
                    Text(hospital.hospitalCity)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Address
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Address")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(hospital.hospitalAddress)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Show number of doctors
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.isPatient ? themeManager.currentTheme.accentColor : .teal)
                        
                        if hospital.numberOfDoctors > 0 {
                            Text("\(hospital.numberOfDoctors) Doctors")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("No Doctors Available")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.isPatient ? themeManager.currentTheme.background : Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
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

