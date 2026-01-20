//
//  SystemSound.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation

/// Represents a system sound available for notification alerts.
struct SystemSound: Identifiable, Hashable {
    /// Display name without file extension (e.g., "Sosumi")
    let name: String

    /// Full filename including extension (e.g., "Sosumi.aiff")
    let filename: String

    var id: String { filename }

    /// Represents "no sound" option for silent notifications
    static let none = SystemSound(name: "None", filename: "")

    /// Returns all available system sounds from /System/Library/Sounds.
    /// Handles errors gracefully by returning an empty array.
    static func getSystemSounds() -> [SystemSound] {
        let soundsURL = URL(fileURLWithPath: "/System/Library/Sounds")

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: soundsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            return files
                .filter { $0.pathExtension.lowercased() == "aiff" }
                .map { url in
                    SystemSound(
                        name: url.deletingPathExtension().lastPathComponent,
                        filename: url.lastPathComponent
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            print("Error reading system sounds: \(error)")
            return []
        }
    }

    /// Returns the default notification sound.
    /// Prefers Sosumi (classic) or Sonumi (Big Sur+ renamed version).
    /// Falls back to first available sound, or nil if no sounds available.
    static func defaultSound() -> SystemSound? {
        let sounds = getSystemSounds()

        // Look for Sosumi or Sonumi (renamed in Big Sur)
        if let sosumiVariant = sounds.first(where: {
            $0.name.localizedCaseInsensitiveContains("sosu") ||
            $0.name.localizedCaseInsensitiveContains("sonu")
        }) {
            return sosumiVariant
        }

        // Fall back to first available sound
        return sounds.first
    }
}
