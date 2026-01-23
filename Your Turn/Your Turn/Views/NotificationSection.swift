//
//  NotificationSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-21.
//

import SwiftUI

struct NotificationSection: View {
    static let defaultSound: String = "Sosumi.aiff"

    @AppStorage("notify.enabled") private var notificationsEnabled: Bool = true
    @AppStorage("notify.soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("notify.sound") private var selectedSound: String = defaultSound
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
                title: "Send a notification",
                subtitle: "Send a notification when an event occurs",
                isOn: $notificationsEnabled
            )

            ToggleRow(
                title: "Play a sound",
                subtitle: "Play a sound when an event occurs",
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
    }

    private func previewSound(_ filename: String, repeatCount: Int? = nil) {
        guard !filename.isEmpty else { return }
        let count = repeatCount ?? soundRepeatCount
        SoundPlayer.shared.play(filename: filename, repeatCount: count)
    }
}
