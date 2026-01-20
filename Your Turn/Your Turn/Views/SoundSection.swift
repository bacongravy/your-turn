//
//  SoundSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import AppKit
import SwiftUI

struct SoundSection: View {
    @AppStorage("notify.sound") private var selectedSound: String = ""
    @State private var sounds: [SystemSound] = []

    var body: some View {
        Section {
            HStack {
                Picker("Notification sound", selection: $selectedSound) {
                    Text(SystemSound.none.name).tag(SystemSound.none.filename)
                    Divider()
                    ForEach(sounds) { sound in
                        Text(sound.name).tag(sound.filename)
                    }
                }
                .labelsHidden()

                if !selectedSound.isEmpty {
                    Button {
                        playPreview()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                    }
                    .buttonStyle(.borderless)
                    .help("Preview sound")
                }
            }
        } header: {
            Text("Sound")
        }
        .task {
            sounds = SystemSound.getSystemSounds()

            // Set default sound if not yet configured
            if selectedSound.isEmpty {
                selectedSound = SystemSound.defaultSound()?.filename ?? ""
            }

            // Handle case where saved sound no longer exists
            if !selectedSound.isEmpty && !sounds.contains(where: { $0.filename == selectedSound }) {
                selectedSound = SystemSound.defaultSound()?.filename ?? ""
            }
        }
    }

    private func playPreview() {
        guard !selectedSound.isEmpty else { return }

        let soundPath = "/System/Library/Sounds/\(selectedSound)"
        if let sound = NSSound(contentsOf: URL(fileURLWithPath: soundPath), byReference: true) {
            sound.play()
        }
    }
}
