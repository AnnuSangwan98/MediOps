import SwiftUI

struct HospitalCard: View {
    let hospital: HospitalModel
    
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(hospital.hospitalName)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(hospital.hospitalCity)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(hospital.hospitalAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.teal)
                        
                        if hospital.numberOfDoctors > 0 {
                            Text("\(hospital.numberOfDoctors) Doctors")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.teal)
                        } else {
                            Text("No Doctors Available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    private var fallbackHospitalImage: some View {
        Image(systemName: "building.2.fill")
            .font(.system(size: 40))
            .foregroundColor(.gray)
            .frame(width: 80, height: 80)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

