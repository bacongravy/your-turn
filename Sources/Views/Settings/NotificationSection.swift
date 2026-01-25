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

    /// System sounds loaded once on view creation (not on every body evaluation)
    @State private var systemSounds: [SystemSound] = SystemSound.getSystemSounds()

    /// Classic sounds bundled with the app from Resources/Sounds
    @State private var classicSounds: [SystemSound] = SystemSound.getClassicSounds()

    var body: some View {
        Section {
            ToggleRow(
                title: "Send a notification",
                isOn: $notificationsEnabled
            )

            ToggleRow(
                title: "Play a sound",
                isOn: $soundEnabled
            )
        }

        Section {
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

            Picker("Times to play", selection: $soundRepeatCount) {
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
        }
    }

    private func previewSound(_ filename: String, repeatCount: Int? = nil) {
        guard !filename.isEmpty else { return }
        let count = repeatCount ?? soundRepeatCount
        SoundPlayer.shared.play(filename: filename, repeatCount: count)
    }
}
