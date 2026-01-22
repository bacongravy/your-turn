//
//  NotificationSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-21.
//

import SwiftUI

struct NotificationSection: View {
    @AppStorage("notify.enabled") private var notificationsEnabled: Bool = true
    @AppStorage("notify.soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("notify.sound") private var selectedSound: String = ""
    @AppStorage("notify.soundRepeatCount") private var soundRepeatCount: Int = 1

    /// System sounds loaded synchronously to ensure Picker tags are available on first render
    private var systemSounds: [SystemSound] {
        SystemSound.getSystemSounds()
    }

    /// Classic sounds bundled with the app from Resources/Sounds
    private var classicSounds: [SystemSound] {
        SystemSound.getClassicSounds()
    }

    var body: some View {
        Section {
            ToggleRow(
                title: "Send notifications",
                subtitle: "Post macOS notifications when events arrive",
                isOn: $notificationsEnabled
            )

            ToggleRow(
                title: "Play a sound",
                subtitle: "Play a sound when an event arrives",
                isOn: $soundEnabled
            )

            VStack(alignment: .leading, spacing: 4) {
                Picker("Sound", selection: $selectedSound) {
                    Section(header: Text("System Sounds")) {
                        ForEach(systemSounds) { sound in
                            Text(sound.name).tag(sound.filename)
                        }
                    }
                    Divider()
                    Section(header: Text("Classic Sounds")) {
                        ForEach(classicSounds) { sound in
                            Text(sound.name).tag(sound.filename)
                        }
                    }
                }
                .disabled(!soundEnabled)
                .onChange(of: selectedSound) { _, newValue in
                    if soundEnabled {
                        previewSound(newValue)
                    }
                }
                Text("Sound to play")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Picker("Repeat count", selection: $soundRepeatCount) {
                    ForEach(1...5, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .disabled(!soundEnabled)
                .onChange(of: soundRepeatCount) { _, newValue in
                    if soundEnabled {
                        previewSound(selectedSound, repeatCount: newValue)
                    }
                }
                Text("Number of times to play the sound")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Notifications")
        }
        .onAppear {
            migrateFromLegacyNoneSound()
            initializeSelectedSound()
        }
    }

    /// Migrates users who had "None" selected (empty string) to the new toggle-based approach.
    private func migrateFromLegacyNoneSound() {
        let defaults = UserDefaults.standard

        // Only migrate if soundEnabled hasn't been explicitly set yet
        guard defaults.object(forKey: "notify.soundEnabled") == nil else { return }

        // If sound was empty (legacy "None"), disable sound and set to default
        if selectedSound.isEmpty {
            soundEnabled = false
            selectedSound = SystemSound.defaultSound()?.filename ?? ""
        }
    }

    private func initializeSelectedSound() {
        if selectedSound.isEmpty {
            selectedSound = SystemSound.defaultSound()?.filename ?? ""
        } else {
            let allSounds = systemSounds + classicSounds
            if !allSounds.contains(where: { $0.filename == selectedSound }) {
                selectedSound = SystemSound.defaultSound()?.filename ?? ""
            }
        }
    }

    private func previewSound(_ filename: String, repeatCount: Int? = nil) {
        guard !filename.isEmpty else { return }
        let count = repeatCount ?? soundRepeatCount
        SoundPlayer.shared.play(filename: filename, repeatCount: count)
    }
}
