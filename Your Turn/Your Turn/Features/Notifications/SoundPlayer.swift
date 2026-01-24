//
//  SoundPlayer.swift
//  Your Turn
//
//  Created by Claude on 1/21/26.
//

import AppKit
import Foundation

/// Service that plays notification sounds with configurable repeat count.
/// Handles both system sounds and classic sounds bundled with the app.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var currentSound: NSSound?
    private var remainingPlays: Int = 0

    private init() {}

    /// Plays the configured notification sound the configured number of times.
    func playNotificationSound() {
        let defaults = UserDefaults.standard

        // Check if sound is enabled (default: true)
        let soundEnabled = defaults.object(forKey: "notify.soundEnabled") != nil
            ? defaults.bool(forKey: "notify.soundEnabled")
            : true

        guard soundEnabled else { return }

        let filename = defaults.string(forKey: "notify.sound") ?? ""
        let repeatCount = defaults.integer(forKey: "notify.soundRepeatCount")

        // Use default of 1 if not set (integer returns 0 for missing keys)
        let count = repeatCount > 0 ? repeatCount : 1

        play(filename: filename, repeatCount: count)
    }

    /// Plays a sound file the specified number of times.
    /// - Parameters:
    ///   - filename: The sound filename (e.g., "Sosumi.aiff")
    ///   - repeatCount: Number of times to play the sound (1-5)
    func play(filename: String, repeatCount: Int = 1) {
        guard !filename.isEmpty else { return }

        // Stop any currently playing sound
        stop()

        guard let url = soundURL(for: filename) else { return }
        guard let sound = NSSound(contentsOf: url, byReference: true) else { return }

        currentSound = sound
        remainingPlays = max(1, min(5, repeatCount)) // Clamp to 1-5
        sound.delegate = SoundPlayerDelegate.shared

        playNext()
    }

    /// Stops any currently playing sound.
    func stop() {
        currentSound?.stop()
        currentSound = nil
        remainingPlays = 0
    }

    /// Called by delegate when sound finishes playing.
    fileprivate func soundDidFinish() {
        remainingPlays -= 1
        if remainingPlays > 0 {
            playNext()
        } else {
            currentSound = nil
        }
    }

    private func playNext() {
        currentSound?.play()
    }

    private func soundURL(for filename: String) -> URL? {
        // Try bundled classic sounds first
        if let bundledURL = Bundle.main.url(
            forResource: filename.replacingOccurrences(of: ".aiff", with: ""),
            withExtension: "aiff",
            subdirectory: "Sounds"
        ) {
            return bundledURL
        }

        // Fall back to system sounds
        let systemURL = URL(fileURLWithPath: "/System/Library/Sounds/\(filename)")
        if FileManager.default.fileExists(atPath: systemURL.path) {
            return systemURL
        }

        return nil
    }
}

/// Delegate to handle sound completion for repeat playback.
/// Separate class because NSSound.delegate requires NSObjectProtocol.
private class SoundPlayerDelegate: NSObject, NSSoundDelegate {
    static let shared = SoundPlayerDelegate()

    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        if flag {
            Task { @MainActor in
                SoundPlayer.shared.soundDidFinish()
            }
        }
    }
}
