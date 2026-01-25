//
//  WelcomeStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Welcome step (Step 0) - introduces the app
struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        WizardStepLayout(
            title: "Welcome to Your Turn",
            subtitle: "Find out when it's your turn.\nOne click to pick up where you left off.",
            icon: .appIcon,
            primaryButton: WizardButton(label: "Continue", action: onContinue)
        )
    }
}

#Preview {
    WelcomeStep(onContinue: {})
        .frame(width: 500, height: 350)
}
