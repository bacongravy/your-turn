//
//  AutomationGuidanceSheet.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// Modal sheet showing step-by-step instructions for enabling automation in System Settings
struct AutomationGuidanceSheet: View {
    let terminalAppName: String
    let onOpenSettings: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("Enable Automation")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("In System Settings:")
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 8) {
                    guidanceRow(number: 1, text: "Find \"Your Turn\" in the app list")
                    guidanceRow(number: 2, text: "Click the disclosure indicator next to \"Your Turn\"")
                    guidanceRow(number: 3, text: "Toggle the switch next to \"\(terminalAppName)\"")
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func guidanceRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).")
                .monospacedDigit()
                .frame(width: 20, alignment: .trailing)
            Text(text)
        }
    }
}

#Preview {
    AutomationGuidanceSheet(terminalAppName: "Terminal", onOpenSettings: {})
}
