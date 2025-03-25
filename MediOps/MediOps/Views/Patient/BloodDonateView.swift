//
//  BloodDonateView.swift
//  MediOps
//
//  Created by Aditya Rai on 21/03/25.
//

import SwiftUI

struct TermsAndConditions {
    static let terms = [
        "Must be between 18-65 years old",
        "Weight should be above 45 kg",
        "Should not have any chronic medical conditions",
        "Must not have donated blood in the last 3 months",
        "Hemoglobin level should be above 12.5 g/dL"
    ]
}

struct BloodDonateView: View {
    @State private var hasAcceptedTerms = false
    @State private var showMainOptions = false
    @State private var showDonateForm = false
    @State private var showRequestForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !showMainOptions {
                    termsAndConditionsView
                } else {
                    mainOptionsView
                }
            }
            .padding()
        }
        .navigationTitle("Blood Donation")
        .sheet(isPresented: $showDonateForm) {
            BloodDonationFormView()
        }
        .sheet(isPresented: $showRequestForm) {
            BloodRequestFormView()
        }
    }
    
    private var termsAndConditionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
                .padding(.bottom)
            
            Text("Terms & Conditions")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                ForEach(TermsAndConditions.terms, id: \.self) { term in
                    Text("• \(term)")
                        .padding(.vertical, 2)
                }
            }
            .padding(.vertical)
            
            Toggle("I accept all terms and conditions", isOn: $hasAcceptedTerms)
                .padding(.vertical)
            
            Button(action: {
                withAnimation {
                    showMainOptions = true
                }
            }) {
                Text("Accept and Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasAcceptedTerms ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!hasAcceptedTerms)
        }
    }
    
    private var mainOptionsView: some View {
        VStack(spacing: 25) {
            Image(systemName: "drop.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)
            
            Text("What would you like to do?")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: { showDonateForm = true }) {
                HStack {
                    Image(systemName: "heart.fill")
                    VStack(alignment: .leading) {
                        Text("Donate Blood")
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: { showRequestForm = true }) {
                HStack {
                    Image(systemName: "bell.fill")
                    VStack(alignment: .leading) {
                        Text("Request Blood")
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}

// Preview provider
struct BloodDonateView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BloodDonateView()
        }
    }
}
