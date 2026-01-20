//
//  AboutSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

struct AboutSection: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Turn")
                    .font(.headline)
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
