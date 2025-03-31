// Time Slot Button Component
struct TimeSlotButton: View {
    let time: String
    let isSelected: Bool
    let action: () -> Void
    let isWeekend: Bool
    
    // Initialize with default isWeekend = false
    init(time: String, isSelected: Bool, isWeekend: Bool = false, action: @escaping () -> Void) {
        self.time = time
        self.isSelected = isSelected
        self.isWeekend = isWeekend
        self.action = action
    }
    
    // This is a custom button for time slots with better styling
    var body: some View {
        Button(action: action) {
            Text(time)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(minWidth: 120)
                .background(
                    isSelected 
                    ? Color.blue
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected 
                            ? Color.blue 
                            : Color.gray.opacity(0.3), 
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 