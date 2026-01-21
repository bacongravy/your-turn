//
//  GeneralSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import AppKit
import SwiftUI
import ServiceManagement

struct GeneralSection: View {
    @State private var launchAtLogin = false
    @AppStorage("notify.sound") private var selectedSound: String = ""

    /// System sounds loaded synchronously to ensure Picker tags are available on first render
    private var sounds: [SystemSound] {
        SystemSound.getSystemSounds()
    }

    var body: some View {
        Section {
            ToggleRow(
                title: "Launch at login",
                subtitle: "Start automatically when you log in",
                isOn: $launchAtLogin
            )

            VStack(alignment: .leading, spacing: 4) {
                Picker("Notification sound", selection: $selectedSound) {
                    Text(SystemSound.none.name).tag(SystemSound.none.filename)
                    Divider()
                    ForEach(sounds) { sound in
                        Text(sound.name).tag(sound.filename)
                    }
                }
                .onChange(of: selectedSound) { _, newValue in
                    playSound(newValue)
                }
                Text("Play a sound with each notification")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("General")
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            initializeSelectedSound()
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
    }

    private func initializeSelectedSound() {
        if selectedSound.isEmpty {
            selectedSound = SystemSound.defaultSound()?.filename ?? ""
        } else if !sounds.contains(where: { $0.filename == selectedSound }) {
            selectedSound = SystemSound.defaultSound()?.filename ?? ""
        }
    }

    private func playSound(_ filename: String) {
        guard !filename.isEmpty else { return }
        let soundPath = "/System/Library/Sounds/\(filename)"
        if let sound = NSSound(contentsOf: URL(fileURLWithPath: soundPath), byReference: true) {
            sound.play()
        }
    }
}
