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
    
    private let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    private let adminController = AdminController.shared
    
    enum RequestStatus {
        case notSent
        case sent
        case completed
    }
    
    var body: some View {
        NavigationStack {
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
                    .padding(.bottom, 20)
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
                // Check if there are ANY donors for this blood group, even unavailable ones
                let anyDonorsWithMatchingBloodGroup = registeredDonors.contains { donor in
                    return selectedBloodGroup.isEmpty || donor.bloodGroup == selectedBloodGroup
                }
                
                if anyDonorsWithMatchingBloodGroup {
                    emptyStateView(
                        title: "No available donors",
                        message: "All donors with \(selectedBloodGroup) blood type already have pending requests",
                        icon: "person.fill.questionmark"
                    )
                } else {
                    emptyStateView(
                        title: "No donors found",
                        message: "No registered donors found for \(selectedBloodGroup) blood type",
                        icon: "person.slash"
                    )
                }
            } else {
                availableDonorsList
            }
            
            // Request button should only be active when there are donors who can be requested
            if !availableDonors().isEmpty {
                Button(action: sendBloodDonationRequest) {
                    HStack {
                        Image(systemName: "paperplane")
                        Text("Send Request to \(selectedDonors.count) Donors")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .disabled(selectedDonors.isEmpty || isLoading)
                .opacity(selectedDonors.isEmpty || isLoading ? 0.6 : 1)
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
                donorRow(donor: donor, isSelectable: true)
                    .background(
                        selectedDonors.contains(donor.id) ? 
                            Color.blue.opacity(0.05) : Color.clear
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDonors.contains(donor.id) {
                            selectedDonors.remove(donor.id)
                        } else {
                            selectedDonors.insert(donor.id)
                        }
                    }
                
                if donor.id != availableDonors().last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
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
        VStack(spacing: 0) {
            ForEach(activeDonors()) { donor in
                Button(action: {
                    donorToUpdate = donor
                    showStatusActionSheet = true
                }) {
                    donorRow(donor: donor, isSelectable: false)
                        .background(Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                if donor.id != activeDonors().last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func donorRow(donor: BloodDonor, isSelectable: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Name section
                Text(donor.name)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.bottom, 2)
                
                // Blood group with label in a fixed-width layout
                HStack(spacing: 8) {
                    Text("Blood Group:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    Text(donor.bloodGroup)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                // Request status section
                if donor.hasPendingRequest || donor.requestStatus != nil {
                    HStack(spacing: 8) {
                        Text("Status:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        // Show status indicators
                        if donor.hasPendingRequest {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                
                                Text("Pending Request")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else if let status = donor.requestStatus, status != "Rejected", status != "Cancelled" {
                            statusBadge(for: status)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Selection indicator or action indicator
            if isSelectable {
                if donor.canBeRequested {
                    if selectedDonors.contains(donor.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .frame(width: 40)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .frame(width: 40)
                    }
                } else {
                    // Cannot be selected - show more specific information
                    VStack(alignment: .center, spacing: 2) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.body)
                        
                        Text("In-use")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 40)
                }
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.callout)
                    .frame(width: 40)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .opacity(donor.canBeRequested || !isSelectable ? 1.0 : 0.7)
    }
    
    private func statusBadge(for status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: status))
                .frame(width: 8, height: 8)
            
            Text(status)
                .font(.caption)
                .foregroundColor(statusColor(for: status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor(for: status).opacity(0.15))
        .cornerRadius(12)
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
    
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            if requestStatus == .notSent && !selectedDonors.isEmpty {
                sendRequestButton
            } else if requestStatus == .sent {
                sentRequestButtons
            } else if requestStatus == .completed {
                newRequestButton
            }
        }
    }
    
    private var sendRequestButton: some View {
        Button(action: sendBloodDonationRequest) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Send Request to \(selectedDonors.count) Donors")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading || selectedDonors.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .disabled(selectedDonors.isEmpty || isLoading)
        .padding(.horizontal)
        .padding(.top, 15)
    }
    
    private var newRequestButton: some View {
        Button(action: resetView) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("New Request")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .disabled(isLoading)
        .padding(.horizontal)
        .padding(.top, 15)
    }
    
    private var sentRequestSection: some View {
        VStack(spacing: 10) {
            Divider()
                .padding(.vertical, 10)
            
            Text("Request sent to \(selectedDonors.count) donor(s)")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await cancelBloodDonationRequest()
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isLoading ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: {
                    Task {
                        await completeBloodDonationRequest()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)
            
            // Add a timestamp for better user feedback
            if selectedDonors.count > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Request sent \(formatTimeAgo())")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
        }
        .padding(.top, 15)
    }
    
    private var sentRequestButtons: some View {
        VStack(spacing: 10) {
            Text("Request sent to \(selectedDonors.count) donor(s)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                Button(action: {
                    Task {
                        await cancelBloodDonationRequest()
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel All")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: {
                    Task {
                        await completeBloodDonationRequest()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete All")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)
        }
        .padding(.top, 15)
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
        // Include only donors that can be requested and match blood group
        let filteredDonors = registeredDonors.filter { donor in
            // First check immediate status - filter out completed, cancelled, rejected
            if donor.requestStatus == "Completed" || 
               donor.requestStatus == "Cancelled" || 
               donor.requestStatus == "Rejected" {
                return false
            }
            
            // Then check history - filter out donors in completed or cancelled history
            let isDonorInCompletedHistory = requestHistory.contains { historyItem in
                guard let donorId = historyItem["donor_id"] as? String,
                      let status = historyItem["request_status"] as? String else {
                    return false
                }
                return donorId == donor.id && (status == "Completed" || status == "Cancelled")
            }
            
            // Match blood group if one is selected
            let matchesBloodGroup = selectedBloodGroup.isEmpty || 
                                   donor.bloodGroup == selectedBloodGroup
            
            // Filter out donors with pending or accepted requests (they're not available)
            let isAvailable = !donor.hasActiveRequest
            
            // Only include donor if they're available, not in completed history, and match blood group
            return isAvailable && !isDonorInCompletedHistory && matchesBloodGroup
        }
        
        // Sort by name
        return filteredDonors.sorted { $0.name < $1.name }
    }
    
    private func hasAvailableDonorsForSelection() -> Bool {
        return availableDonors().contains { $0.canBeRequested }
    }
    
    private func activeDonors() -> [BloodDonor] {
        return registeredDonors.filter { $0.hasPendingRequest || $0.requestStatus == "Accepted" }
                               .sorted { $0.name < $1.name }
    }
    
    private func refreshAllData() async {
        isLoading = true
        
        // Always fetch history first, so we have the latest completed requests data
        await fetchRequestHistory()
        
        switch activeTab {
        case 0:
            await fetchRegisteredDonors(bloodGroup: selectedBloodGroup)
        case 1:
            await fetchRegisteredDonors(bloodGroup: nil)
        case 2:
            // Already fetched history above
            break
        default:
            break
        }
        
        isLoading = false
    }
    
    private func fetchRegisteredDonors(bloodGroup: String? = nil) async {
        isLoadingDonors = true
        selectedDonors.removeAll()
        
        defer { isLoadingDonors = false }
        
        do {
            // Always fetch history data first to ensure we have up-to-date history
            await fetchRequestHistory()
            
            registeredDonors = try await adminController.getRegisteredBloodDonors(bloodGroup: bloodGroup)
            
            // Auto-select only donors that can be requested AND match the selected blood group
            for donor in registeredDonors {
                if donor.canBeRequested && (bloodGroup == nil || donor.bloodGroup == bloodGroup) {
                    selectedDonors.insert(donor.id)
                }
            }
            
            // Check if there are active requests
            let activeDonorsList = activeDonors()
            if !activeDonorsList.isEmpty {
                requestStatus = .sent
                
                // Make sure selected donors reflects the active requests
                selectedDonors.removeAll()
                for donor in activeDonorsList {
                    selectedDonors.insert(donor.id)
                }
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
            // Only update the specific donor's status
            if newStatus == "Completed" {
                try await adminController.completeBloodDonationRequest(
                    donorIds: [donor.id],
                    bloodGroup: donor.bloodGroup
                )
            } else if newStatus == "Cancelled" {
                try await adminController.cancelBloodDonationRequest(
                    donorIds: [donor.id],
                    bloodGroup: donor.bloodGroup
                )
            }
            
            await MainActor.run {
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
        
        // Filter out donors that cannot be requested
        let requestableDonors = selectedDonors.filter { donorId in
            registeredDonors.first { $0.id == donorId }?.canBeRequested ?? false
        }
        
        if requestableDonors.isEmpty {
            errorMessage = "None of the selected donors can be requested at this time."
            showError = true
            return
        }
        
        // Check if a request has already been sent
        if requestStatus == .sent || requestStatus == .completed {
            errorMessage = "A request has already been sent. Please cancel the current request first."
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await adminController.sendBloodDonationRequest(
                    donorIds: Array(requestableDonors),
                    bloodGroup: selectedBloodGroup
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    requestStatus = .sent
                    
                    // Switch to active requests tab
                    withAnimation {
                        activeTab = 1
                    }
                    
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
    }
    
    private func cancelBloodDonationRequest() async {
        isLoading = true
        
        do {
            try await adminController.cancelBloodDonationRequest(
                donorIds: Array(selectedDonors),
                bloodGroup: selectedBloodGroup
            )
            
            await MainActor.run {
                isLoading = false
                requestStatus = .notSent
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
    
    private func completeBloodDonationRequest() async {
        isLoading = true
        
        do {
            try await adminController.completeBloodDonationRequest(
                donorIds: Array(selectedDonors),
                bloodGroup: selectedBloodGroup
            )
            
            await MainActor.run {
                isLoading = false
                requestStatus = .completed
                showSuccess = true
                
                // Refresh request history first to ensure our completed requests are visible
                Task {
                    await fetchRequestHistory()
                    
                    // Then switch to history tab
                    withAnimation {
                        activeTab = 2
                    }
                    
                    // Finally refresh all data
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
        // In a real app, you'd store the time when the request was sent
        // For now, we'll just return a placeholder
        return "recently"
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
