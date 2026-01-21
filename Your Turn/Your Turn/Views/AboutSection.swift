//
//  AboutSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

struct AboutSection: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Your Turn v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }
}
