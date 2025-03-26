import SwiftUI

struct HospitalCard: View {
    let hospital: HospitalModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hospital Image
            if let imageUrl = hospital.hospitalProfileImage {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 150)
                .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "building.2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(hospital.hospitalName)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.gray)
                    Text("\(hospital.hospitalCity), \(hospital.hospitalState)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.teal)
                    Text("\(hospital.numberOfDoctors) Doctors")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.teal)
                    Text("\(hospital.numberOfAppointments) Appointments")
                        .font(.subheadline)
                }
                
                Text(hospital.departments.joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

