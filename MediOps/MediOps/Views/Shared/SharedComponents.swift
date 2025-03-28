//
//  SharedComponents.swift
//  MediOps
//
//  Created on 21/03/25.
//

import SwiftUI

/// A toggle button used for selecting qualifications in various forms
struct QualificationToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.teal : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 8)
    }
} 