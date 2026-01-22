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

    /// Whether this sound is a bundled classic sound (vs system sound)
    let isClassic: Bool

    var id: String { filename }

    /// Represents "no sound" option for silent notifications
    static let none = SystemSound(name: "None", filename: "", isClassic: false)

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
                        filename: url.lastPathComponent,
                        isClassic: false
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            print("Error reading system sounds: \(error)")
            return []
        }
    }

    /// Returns all available classic sounds bundled with the app from Resources/Sounds.
    /// Handles errors gracefully by returning an empty array.
    static func getClassicSounds() -> [SystemSound] {
        guard let soundsURL = Bundle.main.resourceURL?.appendingPathComponent("Sounds") else {
            return []
        }

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
                        filename: url.lastPathComponent,
                        isClassic: true
                    )
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            print("Error reading classic sounds: \(error)")
            return []
        }
    }

    /// Returns the default notification sound.
    /// Prefers classic Sosumi (bundled), then system Sosumi/Sonumi, then falls back.
    static func defaultSound() -> SystemSound? {
        let classicSounds = getClassicSounds()
        let systemSounds = getSystemSounds()

        // Prefer classic Sosumi (the original)
        if let classicSosumi = classicSounds.first(where: {
            $0.name.localizedCaseInsensitiveContains("sosu")
        }) {
            return classicSosumi
        }

        // Fall back to system Sosumi or Sonumi (renamed in Big Sur)
        if let sosumiVariant = systemSounds.first(where: {
            $0.name.localizedCaseInsensitiveContains("sosu") ||
            $0.name.localizedCaseInsensitiveContains("sonu")
        }) {
            return sosumiVariant
        }

        // Fall back to first available classic sound, then system sound
        return classicSounds.first ?? systemSounds.first
    }
}
