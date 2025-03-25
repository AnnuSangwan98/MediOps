import SwiftUI

struct CustomBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "chevron.left")
                    .foregroundColor(.teal)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .padding(.leading)
    }
}

#Preview {
    CustomBackButton()
} 