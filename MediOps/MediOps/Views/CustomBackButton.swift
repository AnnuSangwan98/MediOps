import SwiftUI

struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: { dismiss() }) {
            ZStack {
                Circle()
                    .fill(Color.teal)
                    .frame(width: 40, height: 40)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, 16)
    }
} 