import SwiftUI

struct HospitalCard: View {
    let hospital: HospitalModel
    
    var body: some View {
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
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.teal)
                Text("\(hospital.numberOfDoctors) Doctors")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

