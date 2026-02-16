//
//  GeneralSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI
import ServiceManagement

struct GeneralSection: View {
    @State private var launchAtLogin = false

    var body: some View {
        Section {
            ToggleRow(
                title: "Launch at login",
                subtitle: "Start automatically when you log in",
                isOn: $launchAtLogin
            )
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .onChange(of: launchAtLogin) { _, newValue in
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silent failure - revert toggle per CONTEXT.md
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }

        HotkeySection()
    }
}

// MARK: - Hotkey Section

private struct HotkeySection: View {
    @AppStorage("hotkey.enabled") private var hotkeyEnabled = false
    @State private var currentConfig: HotkeyConfiguration?
    @State private var isRecording = false

    var body: some View {
        Section {
            ToggleRow(
                title: "Keyboard shortcut",
                subtitle: "Press to focus the latest notification's terminal session",
                isOn: $hotkeyEnabled
            )

            HStack {
                Text("Shortcut")
                Spacer()

                if isRecording {
                    Text("Press a key combo...")
                        .foregroundStyle(.secondary)
                        .italic()

                    Button("Cancel") {
                        stopRecording()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Text(currentConfig?.displayString ?? "Not set")
                        .foregroundStyle(currentConfig != nil ? .primary : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.quaternary)
                        )

                    Button("Record") {
                        startRecording()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if currentConfig != nil {
                        Button("Clear") {
                            clearHotkey()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .disabled(!hotkeyEnabled && !isRecording)
        }
        .onAppear {
            currentConfig = HotkeyConfiguration.load()
        }
        .onChange(of: hotkeyEnabled) { _, newValue in
            if newValue {
                HotkeyManager.shared.registerFromDefaults()
            } else {
                HotkeyManager.shared.unregister()
            }
        }
    }

    private func startRecording() {
        // Unregister the current hotkey while recording to prevent it from firing
        HotkeyManager.shared.unregister()
        isRecording = true
        HotkeyRecorder.shared.start { config in
            if let config {
                currentConfig = config
                config.save()
            }
            isRecording = false
            // Re-register (will register the new combo, or restore the old one)
            HotkeyManager.shared.registerFromDefaults()
        }
    }

    private func stopRecording() {
        HotkeyRecorder.shared.stop()
        isRecording = false
        // Re-register whatever was previously configured
        HotkeyManager.shared.registerFromDefaults()
    }

    private func clearHotkey() {
        HotkeyManager.shared.unregister()
        HotkeyConfiguration.clear()
        currentConfig = nil
        hotkeyEnabled = false
    }
}

// MARK: - Hotkey Recorder

/// Uses NSEvent.addLocalMonitorForEvents to capture the next qualified keypress.
/// Requires at least one modifier key + a non-modifier key. Escape cancels.
@MainActor
private final class HotkeyRecorder {
    static let shared = HotkeyRecorder()

    private var monitor: Any?
    private var completion: ((HotkeyConfiguration?) -> Void)?

    private init() {}

    func start(completion: @escaping (HotkeyConfiguration?) -> Void) {
        stop() // Clean up any existing monitor
        self.completion = completion

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return nil // Consume the event
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        completion?(nil) // Signal cancellation
        completion = nil
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // Escape cancels recording
        if event.keyCode == 53 {
            let cb = completion
            completion = nil
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
            cb?(nil)
            return
        }

        // Require at least one modifier key
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let qualifyingModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        guard !modifiers.intersection(qualifyingModifiers).isEmpty else { return }

        // Must have a non-modifier key (not just modifiers alone)
        let modifierKeyCodes: Set<UInt16> = [
            54, 55,  // Command (right, left)
            56, 60,  // Shift (left, right)
            58, 61,  // Option (left, right)
            59, 62,  // Control (left, right)
            57,      // Caps Lock
            63       // Function
        ]
        guard !modifierKeyCodes.contains(event.keyCode) else { return }

        let config = HotkeyConfiguration(
            keyCode: event.keyCode,
            cocoaModifiers: modifiers
        )

        let cb = completion
        completion = nil
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        cb?(config)
    }
}
