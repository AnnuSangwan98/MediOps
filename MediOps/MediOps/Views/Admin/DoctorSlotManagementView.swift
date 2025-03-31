import SwiftUI

struct DoctorSlotManagementView: View {
    @StateObject private var viewModel = DoctorSlotViewModel()
    @State private var selectedDoctor: UIDoctor?
    @State private var selectedDay: WeekDay = .monday
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var showAddSlotSheet = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Doctor Slots")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showAddSlotSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.teal)
                }
            }
            .padding(.horizontal)
            
            // Slots List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.slots.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No slots added yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Tap + to add a new slot")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.slots) { slot in
                        SlotRowView(slot: slot)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSlotSheet) {
            AddSlotSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct SlotRowView: View {
    let slot: DoctorSlot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(slot.day.rawValue)
                    .font(.headline)
                Spacer()
                Text(slot.isAvailable ? "Available" : "Unavailable")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(slot.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(slot.isAvailable ? .green : .red)
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text("\(slot.startTime.formatted(date: .omitted, time: .shortened)) - \(slot.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSlotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DoctorSlotViewModel
    @State private var selectedDay: WeekDay = .monday
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedDoctor: UIDoctor?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Doctor")) {
                    // TODO: Add doctor picker
                    Text("Select Doctor")
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Schedule")) {
                    Picker("Day", selection: $selectedDay) {
                        ForEach(WeekDay.allCases) { day in
                            Text(day.rawValue).tag(day)
                        }
                    }
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Slot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            if let doctor = selectedDoctor {
                                await viewModel.addSlot(
                                    doctorId: doctor.id,
                                    day: selectedDay,
                                    startTime: startTime,
                                    endTime: endTime
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(selectedDoctor == nil)
                }
            }
        }
    }
}

#Preview {
    DoctorSlotManagementView()
} 