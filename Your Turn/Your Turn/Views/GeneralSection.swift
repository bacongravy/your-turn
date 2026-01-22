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
                title: "Launch at login",
                subtitle: "Start automatically when you log in",
                isOn: $launchAtLogin
            )

            VStack(alignment: .leading, spacing: 4) {
                Picker("Notification sound", selection: $selectedSound) {
                    Text(SystemSound.none.name).tag(SystemSound.none.filename)
                    Divider()
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
        } else {
            let allSounds = systemSounds + classicSounds
            if !allSounds.contains(where: { $0.filename == selectedSound }) {
                selectedSound = SystemSound.defaultSound()?.filename ?? ""
            }
        }
    }

    private func playSound(_ filename: String) {
        guard !filename.isEmpty else { return }

        // Check if this is a classic sound (bundled with app)
        let isClassicSound = classicSounds.contains { $0.filename == filename }

        let soundURL: URL?
        if isClassicSound {
            // Get sound from app bundle's Sounds subdirectory
            soundURL = Bundle.main.url(
                forResource: filename.replacingOccurrences(of: ".aiff", with: ""),
                withExtension: "aiff",
                subdirectory: "Sounds"
            )
        } else {
            // Get sound from system library
            soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(filename)")
        }

        if let url = soundURL, let sound = NSSound(contentsOf: url, byReference: true) {
            sound.play()
        }
    }
}
