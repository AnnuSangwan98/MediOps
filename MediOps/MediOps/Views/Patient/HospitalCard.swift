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
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
}

