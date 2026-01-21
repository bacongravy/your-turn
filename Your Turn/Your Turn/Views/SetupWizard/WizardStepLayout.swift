//
//  WizardStepLayout.swift
//  Your Turn
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Shared layout for all middle wizard steps (not Welcome or Complete)
/// Guarantees identical positioning of title, subtitle, action area, and navigation
struct WizardStepLayout<ActionContent: View>: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void
    let onContinue: () -> Void
    var continueLabel: String = "Continue"
    var continueDisabled: Bool = false
    @ViewBuilder let actionContent: () -> ActionContent

    var body: some View {
        VStack(spacing: 0) {
            // Fixed title area
            VStack(spacing: 8) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)

            Spacer()

            // Fixed action area - vertically centered
            actionContent()
                .frame(height: 120)

            Spacer()

            // Fixed navigation area
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .frame(width: 80)

                Spacer()

                Button(continueLabel) {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 100)
                .disabled(continueDisabled)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

#Preview {
    WizardStepLayout(
        title: "Step Title",
        subtitle: "This is the subtitle explaining what this step does.",
        onBack: {},
        onContinue: {}
    ) {
        Button("Action Button") {}
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
    .frame(width: 500, height: 340)
}
