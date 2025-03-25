//
//  MyReportView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//
import SwiftUI

struct MyReportView: View {
    var body: some View {
        VStack {
            Text("My Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Spacer()

            Text("No reports available yet.")
                .foregroundColor(.gray)
                .font(.subheadline)

            Spacer()
        }
        .navigationTitle("My Report")
    }
}

