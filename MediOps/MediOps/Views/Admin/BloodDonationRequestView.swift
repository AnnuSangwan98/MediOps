import SwiftUI
import struct MediOps.BloodDonor

struct BloodDonationRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBloodGroup = "A+"
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var registeredDonors: [BloodDonor] = []
    @State private var selectedDonors: Set<String> = []
    @State private var isLoadingDonors = true
    @State private var requestStatus: RequestStatus = .notSent
    @State private var requestHistory: [[String: Any]] = []
    @State private var isLoadingHistory = true
    @State private var showHistory = false
    @State private var donorToUpdate: BloodDonor? = nil
    @State private var showStatusActionSheet = false
    @State private var activeTab = 0 // 0: Available, 1: Active Requests, 2: History
    @State private var showingStatusUpdateSheet = false
    @State private var selectedDonor: BloodDonor? = nil
    @State private var showStatusUpdateDialog = false
    
    private let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    private let adminController = AdminController.shared
    
    enum RequestStatus {
        case notSent
        case sent
        case completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Custom segment control
                    tabSelector
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Main content based on selected tab
                    ScrollView {
                        VStack(spacing: 0) {
                            switch activeTab {
                            case 0: // Available Donors
                                requestDetailsSection
                                availableDonorsSection
                                
                            case 1: // Active Requests
                                activeRequestsContent
                                
                            case 2: // History
                                historyContent
                                    .padding()
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.bottom, 80) // Add padding at the bottom for the floating button
                    }
                }
                
                // Floating Send Request Button (only on available tab with selected donors)
                if activeTab == 0 && !selectedDonors.isEmpty {
                    VStack {
                        Spacer()
                        
                        // Debug text to confirm donors are selected
                        Text("Debug: \(selectedDonors.count) donors selected")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Button(action: sendBloodDonationRequest) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.headline)
                                    Text("Send Request (\(selectedDonors.count))")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationTitle("Blood Donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshAllData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    // Don't dismiss the view, just close the alert
                }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Update Request Status", isPresented: $showStatusActionSheet, titleVisibility: .visible) {
                Button("Mark as Completed") {
                    if let donor = donorToUpdate {
                        Task {
                            await updateDonorStatus(donor: donor, newStatus: "Completed")
                        }
                    }
                }
                
                Button("Mark as Cancelled", role: .destructive) {
                    if let donor = donorToUpdate {
                        Task {
                            await updateDonorStatus(donor: donor, newStatus: "Cancelled")
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                if let donor = donorToUpdate {
                    Text("Update request status for \(donor.name)")
                } else {
                    Text("Select an action")
                }
            }
            .task {
                await refreshAllData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var tabSelector: some View {
        Picker("View Mode", selection: $activeTab) {
            Text("Available").tag(0)
            Text("Active").tag(1)
            Text("History").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onChange(of: activeTab) { newTab in
            // Refresh data when switching tabs
            Task {
                if newTab == 0 {
                    await fetchRegisteredDonors(bloodGroup: selectedBloodGroup)
                } else if newTab == 1 {
                    await fetchRegisteredDonors(bloodGroup: nil)
                } else if newTab == 2 {
                    await fetchRequestHistory()
                }
            }
        }
    }
    
    private var requestDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Blood Group")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            Picker("Blood Group Needed", selection: $selectedBloodGroup) {
                ForEach(bloodGroups, id: \.self) { group in
                    Text(group).tag(group)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedBloodGroup) { newValue in
                Task {
                    await fetchRegisteredDonors(bloodGroup: newValue)
                }
            }
            
            Divider()
                .padding(.top, 5)
        }
        .background(Color.white)
    }
    
    private var availableDonorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Available Donors")
                    .font(.headline)
                
                Spacer()
                
                if !isLoadingDonors {
                    Text("\(availableDonors().count) donors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoadingDonors {
                loadingIndicator
            } else if availableDonors().isEmpty {
                emptyStateView(
                    title: "No donors available",
                    message: "No registered donors found for \(selectedBloodGroup) blood type",
                    icon: "person.slash"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if !hasAvailableDonorsForSelection() {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("All donors have pending requests")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal)
                    }
                    
                    availableDonorsList
                }
            }
        }
        .background(Color.white)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Text("No active requests found")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("When you request blood donors, they will appear here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private func emptyStateView(title: String, message: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var availableDonorsList: some View {
        VStack(spacing: 0) {
            ForEach(availableDonors()) { donor in
                Button(action: {
                    // Toggle selection with print for debugging
                    if selectedDonors.contains(donor.id) {
                        selectedDonors.remove(donor.id)
                        print("Removed donor: \(donor.name), total: \(selectedDonors.count)")
                    } else {
                        selectedDonors.insert(donor.id)
                        print("Added donor: \(donor.name), total: \(selectedDonors.count)")
                    }
                }) {
                    HStack {
                        // Donor information
                        VStack(alignment: .leading, spacing: 8) {
                            // Donor name
                            Text(donor.name)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            // Blood Group row
                            HStack {
                                Text("Blood Group:")
                                    .foregroundColor(.gray)
                                Text(donor.bloodGroup)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        // Selection checkmark
                        Image(systemName: selectedDonors.contains(donor.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedDonors.contains(donor.id) ? .blue : .gray)
                            .font(.title2)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
    
    private var activeRequestsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Active Requests")
                    .font(.headline)
                
                Spacer()
                
                if !isLoadingDonors {
                    Text("\(activeDonors().count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if isLoadingDonors {
                loadingIndicator
            } else if activeDonors().isEmpty {
                emptyStateView(
                    title: "No Active Requests",
                    message: "You don't have any active blood donation requests at this time",
                    icon: "bell.slash"
                )
            } else {
                activeRequestsList
            }
        }
    }
    
    private var activeRequestsList: some View {
        VStack {
            if activeDonors().isEmpty {
                // Empty state view
                VStack(spacing: 16) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Active Blood Donation Requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Blood donation requests that are pending or accepted will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(activeDonors(), id: \.id) { donor in
                            // Active donor card
                            Button(action: {
                                selectedDonor = donor
                                showStatusUpdateDialog = true
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Donor name and status badge
                                    HStack {
                                        Text(donor.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        // Status badge
                                        Text(donor.requestStatus ?? "Pending")
                                            .font(.footnote)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(statusColor(for: donor.requestStatus ?? "Pending").opacity(0.1))
                                            .foregroundColor(statusColor(for: donor.requestStatus ?? "Pending"))
                                            .cornerRadius(16)
                                    }
                                    
                                    // Blood Group row
                                    HStack {
                                        Text("Blood Group:")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                        
                                        Text(donor.bloodGroup)
                                            .fontWeight(.semibold)
                                            .font(.title3)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .confirmationDialog(
            "Request sent to \(activeDonors().count) donor(s)",
            isPresented: $showStatusUpdateDialog,
            titleVisibility: .visible
        ) {
            if let donor = selectedDonor {
                Button("Complete Request", role: .none) {
                    Task {
                        await updateDonorStatus(donor: donor, newStatus: "Completed")
                    }
                }
                .foregroundColor(.green)
                
                Button("Cancel Request", role: .destructive) {
                    Task {
                        await updateDonorStatus(donor: donor, newStatus: "Cancelled")
                    }
                }
                
                Button("Dismiss", role: .cancel) {}
            }
        } message: {
            if let donor = selectedDonor {
                Text("What would you like to do with \(donor.name)'s request?")
            } else {
                Text("Select an action")
            }
        }
    }
    
    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Request History")
                    .font(.headline)
                
                Spacer()
                
                if !isLoadingHistory {
                    Text("\(requestHistory.count) records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoadingHistory {
                loadingIndicator
            } else if requestHistory.isEmpty {
                emptyStateView(
                    title: "No History Found",
                    message: "Completed, cancelled, and rejected requests will appear here",
                    icon: "clock.arrow.circlepath"
                )
            } else {
                historyList
            }
        }
    }
    
    private var historyList: some View {
        VStack(spacing: 12) {
            ForEach(requestHistory.indices, id: \.self) { index in
                HistoryCard(request: requestHistory[index])
            }
        }
    }
    
    private var successMessage: String {
        if requestStatus == .completed {
            return "Blood donation request marked as completed!"
        } else if requestStatus == .notSent {
            return "Blood donation request cancelled successfully!"
        } else {
            return "Blood donation request sent successfully!"
        }
    }
    
    // MARK: - Helper Methods
    
    private func availableDonors() -> [BloodDonor] {
        registeredDonors.filter { donor in
            // Only show donors that don't have an active request
            donor.requestStatus == nil ||
            donor.requestStatus == "Completed" ||
            donor.requestStatus == "Cancelled" ||
            donor.requestStatus == "Rejected"
        }.sorted { $0.name < $1.name } // Sort by name for consistent ordering
    }
    
    private func hasAvailableDonorsForSelection() -> Bool {
        return availableDonors().contains { $0.canBeRequested }
    }
    
    private func activeDonors() -> [BloodDonor] {
        let active = registeredDonors.filter { donor in
            // Show donors with pending or accepted requests
            return donor.requestStatus == "Pending" ||
                  donor.requestStatus == "Accepted"
        }.sorted { $0.name < $1.name } // Sort by name for consistent ordering
        
        print("ACTIVE DONORS FUNCTION: Found \(active.count) active donors")
        return active
    }
    
    private func refreshAllData() async {
        switch activeTab {
        case 0:
            await fetchRegisteredDonors(bloodGroup: selectedBloodGroup)
        case 1:
            await fetchRegisteredDonors(bloodGroup: nil)
        case 2:
            await fetchRequestHistory()
        default:
            break
        }
    }
    
    private func fetchRegisteredDonors(bloodGroup: String? = nil) async {
        isLoadingDonors = true
        selectedDonors.removeAll()
        
        defer { isLoadingDonors = false }
        
        do {
            // Get all registered donors
            registeredDonors = try await adminController.getRegisteredBloodDonors(bloodGroup: bloodGroup)
            
            // Get active blood donation requests
            let activeRequests = try await adminController.getBloodDonationRequests()
            
            // Update donor statuses based on active requests
            for (index, donor) in registeredDonors.enumerated() {
                if let activeRequest = activeRequests.first(where: { ($0["donor_id"] as? String) == donor.id }) {
                    var updatedDonor = donor
                    updatedDonor.requestStatus = (activeRequest["request_status"] as? String) ?? "Pending"
                    registeredDonors[index] = updatedDonor
                }
            }
            
            print("DONORS AFTER UPDATE: \(registeredDonors.map { "\($0.name): \($0.requestStatus ?? "none")" }.joined(separator: ", "))")
            print("ACTIVE DONORS: \(activeDonors().map { $0.name }.joined(separator: ", "))")
            
            // Check if there are active requests
            let activeDonorsList = activeDonors()
            if !activeDonorsList.isEmpty {
                requestStatus = .sent
            } else if requestStatus != .completed {
                requestStatus = .notSent
            }
        } catch {
            errorMessage = "Failed to load blood donors: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func fetchRequestHistory() async {
        isLoadingHistory = true
        
        defer { isLoadingHistory = false }
        
        do {
            requestHistory = try await adminController.getBloodDonationRequestHistory()
        } catch {
            errorMessage = "Failed to load request history: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func updateDonorStatus(donor: BloodDonor, newStatus: String) async {
        isLoading = true
        
        do {
            // Get the request ID for this donor
            let requests = try await adminController.getBloodDonationRequests()
            guard let request = requests.first(where: { ($0["donor_id"] as? String) == donor.id }),
                  let requestId = request["id"] as? String else {
                throw AdminError.customError("Could not find active request for this donor")
            }
            
            if newStatus == "Completed" {
                try await adminController.completeBloodDonationRequest(requestId: requestId)
            } else if newStatus == "Cancelled" {
                try await adminController.cancelBloodDonationRequest(requestId: requestId)
            }
            
            await MainActor.run {
                // Update the local donor status
                if let index = registeredDonors.firstIndex(where: { $0.id == donor.id }) {
                    var updatedDonor = registeredDonors[index]
                    updatedDonor.requestStatus = newStatus
                    registeredDonors[index] = updatedDonor
                }
                
                isLoading = false
                showSuccess = true
                
                // Refresh all data
                Task {
                    await refreshAllData()
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func sendBloodDonationRequest() {
        guard !selectedDonors.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                // Send the blood donation request
                try await adminController.sendBloodDonationRequest(
                    donorIds: Array(selectedDonors),
                    bloodGroup: selectedBloodGroup
                )
                
                await MainActor.run {
                    // Update local state for immediate UI update
                    for donorId in selectedDonors {
                        if let index = registeredDonors.firstIndex(where: { $0.id == donorId }) {
                            var updatedDonor = registeredDonors[index]
                            updatedDonor.requestStatus = "Pending"
                            registeredDonors[index] = updatedDonor
                        }
                    }
                    
                    isLoading = false
                    showSuccess = true
                    requestStatus = .sent
                    
                    // Switch to active requests tab
                    withAnimation {
                        activeTab = 1
                    }
                    
                    // Clear selected donors
                    selectedDonors.removeAll()
                    
                    // Force refresh active requests data
                    Task {
                        do {
                            // Get active blood donation requests
                            let activeRequests = try await adminController.getBloodDonationRequests()
                            
                            await MainActor.run {
                                for (index, donor) in registeredDonors.enumerated() {
                                    if let activeRequest = activeRequests.first(where: { ($0["donor_id"] as? String) == donor.id }) {
                                        var updatedDonor = donor
                                        updatedDonor.requestStatus = (activeRequest["request_status"] as? String) ?? "Pending"
                                        registeredDonors[index] = updatedDonor
                                    }
                                }
                                
                                print("ACTIVE TAB DONORS: \(activeDonors().map { $0.name }.joined(separator: ", "))")
                            }
                        } catch {
                            print("Error refreshing active requests: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func resetView() {
        requestStatus = .notSent
        
        Task {
            // Switch back to available tab
            withAnimation {
                activeTab = 0
            }
            
            // Refresh data
            await refreshAllData()
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "Pending":
            return .orange
        case "Accepted":
            return .blue
        case "Rejected", "Cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatTimeAgo() -> String {
        return "recently"
    }
    
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            VStack {
                ProgressView()
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
            .padding()
            Spacer()
        }
    }
}

struct HistoryCard: View {
    let request: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with name and status
            HStack(alignment: .top) {
                Text(getDonorName())
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                statusBadge
            }
            
            // Blood group information row with fixed-width label
            HStack(spacing: 8) {
                Text("Blood Group:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                    
                    Text(getBloodGroup())
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            
            // Date information with fixed-width label
            if let date = getRequestDate() {
                HStack(spacing: 8) {
                    Text("Requested:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Hospital information with fixed-width label if available
            if let hospitalId = request["hospital_id"] as? String {
                HStack(spacing: 8) {
                    Text("Hospital:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text(hospitalId)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
    
    private var statusBadge: some View {
        let status = getStatusText()
        let color = getStatusColor()
        
        return Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    private func getDonorName() -> String {
        return request["donor_name"] as? String ?? request["donor_id"] as? String ?? "Unknown"
    }
    
    private func getBloodGroup() -> String {
        return request["blood_requested_for"] as? String ?? "Unknown"
    }
    
    private func getStatusText() -> String {
        return request["request_status"] as? String ?? "Unknown"
    }
    
    private func getRequestDate() -> Date? {
        if let dateString = request["blood_requested_time"] as? String {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString)
        }
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func getStatusColor() -> Color {
        if let status = request["request_status"] as? String {
            switch status {
            case "Completed": return .green
            case "Cancelled": return .red
            case "Rejected": return .red
            case "Pending": return .orange
            case "Accepted": return .blue
            default: return .gray
            }
        }
        return .gray
    }
}

#Preview {
    BloodDonationRequestView()
} 
