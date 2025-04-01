//import SwiftUI
//
//struct PatientDashboardView: View {
//    @State private var selectedTab = 0
//    
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            // Home Tab
//            NavigationView {
//                VStack {
//                    Text("Welcome to MediOps")
//                        .font(.title)
//                        .padding()
//                    
//                    // Add your dashboard content here
//                    
//                }
//                .navigationTitle("Home")
//            }
//            .tabItem {
//                Image(systemName: "house.fill")
//                Text("Home")
//            }
//            .tag(0)
//            
//            // Appointments Tab
//            NavigationView {
//                Text("Appointments")
//                    .navigationTitle("Appointments")
//            }
//            .tabItem {
//                Image(systemName: "calendar")
//                Text("Appointments")
//            }
//            .tag(1)
//            
//            // Profile Tab
//            NavigationView {
//                Text("Profile")
//                    .navigationTitle("Profile")
//            }
//            .tabItem {
//                Image(systemName: "person.fill")
//                Text("Profile")
//            }
//            .tag(2)
//        }
//    }
//}
//
//#Preview {
//    PatientDashboardView()
//} 
