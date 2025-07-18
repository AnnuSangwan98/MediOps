import SwiftUI
import Charts

// Data model for appointment data
struct AnalyticsAppointmentData: Identifiable {
    let id: String
    let date: Date
    let isPremium: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct HospitalAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Appointment data
    @State private var premiumAppointments = 0
    @State private var regularAppointments = 0
    @State private var appointmentsByDate: [String: Int] = [:]
    @State private var appointmentRevenue: Double = 0.0
    
    // Supabase client
    private let supabase = SupabaseController.shared
    
    // For tab selection
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading analytics...")
                            .padding(.top, 40)
                    } else if let error = errorMessage {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Error Loading Data")
                                .font(.headline)
                            
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            Button("Try Again") {
                                loadData()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        revenueOverviewCard
                        
                        appointmentBreakdownCard
                    }
                }
                .padding()
            }
            .navigationTitle("Hospital Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private var revenueOverviewCard: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Revenue")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("₹\(String(format: "%.2f", appointmentRevenue))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            Divider().padding(.vertical, 8)
            
            HStack {
                revenueMetricView(
                    title: "Premium",
                    value: "\(premiumAppointments)",
                    amount: "₹\(String(format: "%.2f", Double(premiumAppointments) * 700))",
                    icon: "star.fill",
                    color: .yellow
                )
                
                Divider().frame(height: 40)
                
                revenueMetricView(
                    title: "Regular",
                    value: "\(regularAppointments)",
                    amount: "₹\(String(format: "%.2f", Double(regularAppointments) * 500))",
                    icon: "person.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func revenueMetricView(title: String, value: String, amount: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(amount)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var appointmentBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appointment Breakdown")
                .font(.headline)
            
            HStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10)
                        .opacity(0.3)
                        .foregroundColor(.blue)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(Double(premiumAppointments) / Double(max(premiumAppointments + regularAppointments, 1)), 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.blue)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: premiumAppointments)
                    
                    VStack {
                        Text("\(Int((Double(premiumAppointments) / Double(max(premiumAppointments + regularAppointments, 1))) * 100))%")
                            .font(.title3.bold())
                        Text("Premium")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                        
                        Text("Premium Appointments:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(premiumAppointments)")
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 16, height: 16)
                        
                        Text("Regular Appointments:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(regularAppointments)")
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        
                        Text("Total Appointments:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(premiumAppointments + regularAppointments)")
                            .font(.subheadline.bold())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func loadData() {
        guard let hospitalId = UserDefaults.standard.string(forKey: "hospital_id") else {
            errorMessage = "Hospital ID not found. Please login again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await loadAppointmentData(hospitalId: hospitalId)
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadAppointmentData(hospitalId: String) async throws {
        do {
            let appointments = try await supabase.select(
                from: "appointments",
                where: "hospital_id",
                equals: hospitalId
            )
            
            // Process appointments and calculate revenue
            var premiumCount = 0
            var regularCount = 0
            
            var processedAppointments: [AnalyticsAppointmentData] = []
            
            for appointment in appointments {
                guard let isPremium = appointment["is_premium"] as? Bool else {
                    continue
                }
                
                if isPremium {
                    premiumCount += 1
                } else {
                    regularCount += 1
                }
                
                // Parse the appointment data for display
                if let id = appointment["id"] as? String,
                   let appointmentDate = appointment["appointment_date"] as? String {
                    
                    let appointmentData = AnalyticsAppointmentData(
                        id: id,
                        date: Date(timeIntervalSince1970: Double(appointmentDate) ?? 0),
                        isPremium: isPremium
                    )
                    
                    processedAppointments.append(appointmentData)
                }
            }
            
            // Calculate total revenue
            let premiumRevenue = Double(premiumCount) * 700
            let regularRevenue = Double(regularCount) * 500
            let total = premiumRevenue + regularRevenue
            
            await MainActor.run {
                self.premiumAppointments = premiumCount
                self.regularAppointments = regularCount
                self.appointmentRevenue = total
            }
        } catch {
            throw error
        }
    }
}

#Preview {
    HospitalAnalyticsView()
} 
