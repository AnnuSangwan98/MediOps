import SwiftUI

struct HospitalCard: View {
    let hospital: Hospitals
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(hospital.name)
                        .font(.headline)
                    Text(hospital.city)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", hospital.rating))
                }
            }
            
            Text(hospital.address)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "person.2")
                Text("\(hospital.numberOfDoctors) Doctors")
                    .font(.caption)
            }
            .foregroundColor(.teal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

