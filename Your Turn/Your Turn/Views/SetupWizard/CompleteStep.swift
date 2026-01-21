//
//  CompleteStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Complete step (Step 4) - setup finished
struct CompleteStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            // Title
            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            // Summary
            VStack(alignment: .leading, spacing: 8) {
                SummaryRow(icon: "checkmark", text: "Claude Code hooks installed")
                SummaryRow(icon: "checkmark", text: "Terminal automation configured")
                SummaryRow(icon: "checkmark", text: "Notifications enabled")
            }
            .padding(.horizontal, 40)

            Text("Your Turn will now notify you when Claude needs your attention.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Finish button
            Button("Start Using Your Turn") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
}

/// Helper view for summary checkmark rows
private struct SummaryRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .font(.caption)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CompleteStep(onFinish: {})
        .frame(width: 500, height: 350)
}
