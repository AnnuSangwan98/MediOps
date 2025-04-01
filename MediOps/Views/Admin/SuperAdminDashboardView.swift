import SwiftUI

struct Hospital: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let contact: String
    let email: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case contact
        case email
        case createdAt = "created_at"
    }
}

class HospitalViewModel: ObservableObject {
    @Published var hospitals: [Hospital] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseClient.shared
    
    func fetchHospitals() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response: [Hospital] = try await supabase.database
                    .from("hospitals")
                    .select()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.hospitals = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct SuperAdminDashboardView: View {
    @StateObject private var viewModel = HospitalViewModel()
    @State private var searchText = ""
    @State private var showAddHospital = false
    
    private var filteredHospitals: [Hospital] {
        if searchText.isEmpty {
            return viewModel.hospitals
        }
        return viewModel.hospitals.filter { hospital in
            hospital.name.localizedCaseInsensitiveContains(searchText) ||
            hospital.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading hospitals...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            viewModel.fetchHospitals()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search hospitals...", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        
                        if filteredHospitals.isEmpty {
                            ContentUnavailableView(
                                "No Hospitals Found",
                                systemImage: "building.2",
                                description: Text("Try adjusting your search or add a new hospital")
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredHospitals) { hospital in
                                        HospitalCard(hospital: hospital)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Hospitals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddHospital = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.fetchHospitals() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchHospitals()
        }
    }
}

struct HospitalCard: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(hospital.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(hospital.address, systemImage: "mappin.circle")
                    Label(hospital.contact, systemImage: "phone")
                    Label(hospital.email, systemImage: "envelope")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Text("Added \(hospital.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    SuperAdminDashboardView()
} 