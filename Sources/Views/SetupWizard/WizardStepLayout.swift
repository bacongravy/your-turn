//
//  WizardStepLayout.swift
//  Your Turn
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

// MARK: - Supporting Types

/// Represents a button in the wizard layout
struct WizardButton {
    let label: String
    let action: () -> Void
    var isDisabled: Bool = false
}

/// Icon types for welcome/complete steps
enum WizardIcon {
    case appIcon
    case systemImage(String, Color)
}

// MARK: - Layout Constants

private enum LayoutConstants {
    static let iconZoneHeight: CGFloat = 80
    static let titleZoneHeight: CGFloat = 70
    static let statusZoneHeight: CGFloat = 40
    static let infoZoneHeight: CGFloat = 80
    static let buttonZoneHeight: CGFloat = 50
}

// MARK: - WizardStepLayout

/// Fixed-zone layout for all wizard steps
/// Guarantees consistent positioning across all steps
struct WizardStepLayout<StatusContent: View, InfoContent: View>: View {
    let title: String
    let subtitle: String
    var icon: WizardIcon? = nil

    let primaryButton: WizardButton
    var skipButton: WizardButton? = nil

    @ViewBuilder var statusContent: () -> StatusContent
    @ViewBuilder var infoContent: () -> InfoContent

    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Icon (optional)
            if let icon = icon {
                iconView(for: icon)
                    .frame(height: LayoutConstants.iconZoneHeight)
            }

            // Zone 2: Title + Subtitle
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
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: LayoutConstants.titleZoneHeight, alignment: .top)
            .padding(.top, icon == nil ? 40 : 16)

            Spacer()

            // Zone 3: Status (fixed position)
            statusContent()
                .frame(height: LayoutConstants.statusZoneHeight)

            // Zone 4: Info Content (fixed position)
            infoContent()
                .frame(height: LayoutConstants.infoZoneHeight)

            Spacer()

            // Zone 5: Button row - ZStack for centering primary, skip floats right
            ZStack {
                // Primary button - centered, fixed width
                Button {
                    primaryButton.action()
                } label: {
                    Text(primaryButton.label)
                        .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(primaryButton.isDisabled)
                .keyboardShortcut(.defaultAction)

                // Skip button - right aligned (when present)
                if let skip = skipButton {
                    HStack {
                        Spacer()
                        Button(skip.label) {
                            skip.action()
                        }
                        .buttonStyle(.bordered)
                        .disabled(skip.isDisabled)
                    }
                }
            }
            .frame(height: LayoutConstants.buttonZoneHeight)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func iconView(for icon: WizardIcon) -> some View {
        switch icon {
        case .appIcon:
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
            }
        case .systemImage(let name, let color):
            Image(systemName: name)
                .font(.system(size: 64))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Convenience Initializers

extension WizardStepLayout where StatusContent == EmptyView, InfoContent == EmptyView {
    /// Convenience initializer for steps with no status or info content
    init(
        title: String,
        subtitle: String,
        icon: WizardIcon? = nil,
        primaryButton: WizardButton,
        skipButton: WizardButton? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.primaryButton = primaryButton
        self.skipButton = skipButton
        self.statusContent = { EmptyView() }
        self.infoContent = { EmptyView() }
    }
}

extension WizardStepLayout where StatusContent == EmptyView {
    /// Convenience initializer for steps with only info content
    init(
        title: String,
        subtitle: String,
        icon: WizardIcon? = nil,
        primaryButton: WizardButton,
        skipButton: WizardButton? = nil,
        @ViewBuilder infoContent: @escaping () -> InfoContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.primaryButton = primaryButton
        self.skipButton = skipButton
        self.statusContent = { EmptyView() }
        self.infoContent = infoContent
    }
}

extension WizardStepLayout where InfoContent == EmptyView {
    /// Convenience initializer for steps with only status content
    init(
        title: String,
        subtitle: String,
        icon: WizardIcon? = nil,
        primaryButton: WizardButton,
        skipButton: WizardButton? = nil,
        @ViewBuilder statusContent: @escaping () -> StatusContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.primaryButton = primaryButton
        self.skipButton = skipButton
        self.statusContent = statusContent
        self.infoContent = { EmptyView() }
    }
}

// MARK: - Preview

#Preview {
    WizardStepLayout(
        title: "Step Title",
        subtitle: "This is the subtitle explaining what this step does.",
        primaryButton: WizardButton(label: "Continue", action: {}),
        skipButton: WizardButton(label: "Skip", action: {}),
        statusContent: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Success message")
                    .foregroundStyle(.secondary)
            }
        },
        infoContent: {
            VStack(spacing: 4) {
                Text("Info line 1")
                Text("Info line 2")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    )
    .frame(width: 500, height: 340)
}
