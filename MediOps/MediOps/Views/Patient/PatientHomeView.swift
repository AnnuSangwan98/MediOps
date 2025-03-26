import SwiftUI

struct PatientHomeView: View {
    var body: some View {
        TabView {
            HomeTabView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                }

            MyReportView()
                .tabItem {
                    Image(systemName: "doc.plaintext")
                    Text("My Report")
                }

            BloodDonateView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Blood Donate")
                }
        }
    }
}

