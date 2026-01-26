//
//  HookInstaller.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation
import os.log

/// Errors that can occur during hook installation
enum HookError: LocalizedError {
    case scriptNotBundled
    case settingsCorrupted(String)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .scriptNotBundled:
            return "Hook script not found in app bundle"
        case .settingsCorrupted(let detail):
            return "Claude Code settings.json is corrupted: \(detail)"
        case .writeFailed(let underlying):
            return "Failed to write file: \(underlying.localizedDescription)"
        }
    }
}

/// Installs and manages Claude Code hooks for Your Turn integration.
/// Handles settings.json modification and hook script deployment.
class HookInstaller {
    private let settingsPath: URL
    private let hooksDir: URL
    private let scriptName = "your-turn-notify.sh"
    private let logger = Logger(category: "HookInstaller")

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        settingsPath = home.appendingPathComponent(".claude/settings.json")
        hooksDir = home.appendingPathComponent(".claude/hooks")
    }

    /// Install hooks into Claude Code settings.json and deploy hook script
    func installHooks() throws {
        logger.info("Starting hook installation")

        do {
            // Install settings.json hooks
            try installSettingsHooks()

            // Deploy hook script
            try deployHookScript()

            logger.info("Hook installation complete")
        } catch {
            logger.error("Hook installation failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Remove our hooks from Claude Code settings
    func uninstallHooks() throws {
        logger.info("Starting hook uninstallation")

        let fm = FileManager.default

        // Remove hook script
        let scriptPath = hooksDir.appendingPathComponent(scriptName)
        if fm.fileExists(atPath: scriptPath.path) {
            try fm.removeItem(at: scriptPath)
            logger.debug("Removed hook script")
        }

        // Remove our hooks from settings.json
        if fm.fileExists(atPath: settingsPath.path) {
            let data = try Data(contentsOf: settingsPath)
            guard var settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw HookError.settingsCorrupted("Root is not a dictionary")
            }

            if var hooks = settings["hooks"] as? [String: Any] {
                // Remove our hooks by filtering out entries with our script
                hooks["Notification"] = removeOurHook(from: hooks["Notification"])
                hooks["Stop"] = removeOurHook(from: hooks["Stop"])

                // Clean up empty arrays
                if let arr = hooks["Notification"] as? [[String: Any]], arr.isEmpty {
                    hooks.removeValue(forKey: "Notification")
                }
                if let arr = hooks["Stop"] as? [[String: Any]], arr.isEmpty {
                    hooks.removeValue(forKey: "Stop")
                }

                // Remove hooks key entirely if empty
                if hooks.isEmpty {
                    settings.removeValue(forKey: "hooks")
                } else {
                    settings["hooks"] = hooks
                }

                // Write back
                let outputData = try JSONSerialization.data(
                    withJSONObject: settings,
                    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                )
                try outputData.write(to: settingsPath)
                logger.debug("Removed our hooks from settings.json")
            }
        }

        logger.info("Hook uninstallation complete")
    }

    /// Silently update the hook script if it already exists and content differs.
    /// Used on app launch to ensure existing users get script updates without prompts.
    /// Returns true if the script was updated, false if it didn't exist or was already current.
    @discardableResult
    func updateScriptIfPresent() -> Bool {
        let fm = FileManager.default
        let scriptPath = hooksDir.appendingPathComponent(scriptName)

        guard fm.fileExists(atPath: scriptPath.path) else {
            return false
        }

        // Compare content to avoid unnecessary writes
        guard let bundledScript = Bundle.main.url(forResource: "your-turn-notify", withExtension: "sh"),
              let bundledContent = try? Data(contentsOf: bundledScript),
              let deployedContent = try? Data(contentsOf: scriptPath),
              bundledContent != deployedContent else {
            logger.debug("Hook script already current, skipping update")
            return false
        }

        do {
            try deployHookScript()
            logger.info("Updated hook script to new version")
            return true
        } catch {
            logger.error("Failed to update hook script: \(error.localizedDescription)")
            return false
        }
    }

    /// Check if our hooks are currently installed
    func isInstalled() -> Bool {
        let fm = FileManager.default

        // Check script exists and is executable
        let scriptPath = hooksDir.appendingPathComponent(scriptName)
        guard fm.fileExists(atPath: scriptPath.path),
              fm.isExecutableFile(atPath: scriptPath.path) else {
            return false
        }

        // Check settings.json has our hooks
        guard fm.fileExists(atPath: settingsPath.path),
              let data = try? Data(contentsOf: settingsPath),
              let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = settings["hooks"] as? [String: Any] else {
            return false
        }

        let hasNotificationHook = checkForOurHook(in: hooks["Notification"])
        let hasStopHook = checkForOurHook(in: hooks["Stop"])

        return hasNotificationHook && hasStopHook
    }

    // MARK: - Private Methods

    private func installSettingsHooks() throws {
        let fm = FileManager.default

        // Create .claude directory if needed
        let claudeDir = settingsPath.deletingLastPathComponent()
        try fm.createDirectory(at: claudeDir, withIntermediateDirectories: true)

        // Read existing settings or start fresh
        var settings: [String: Any]
        if fm.fileExists(atPath: settingsPath.path) {
            // Backup first
            let backupPath = settingsPath.deletingLastPathComponent()
                .appendingPathComponent("settings.json.backup")
            try? fm.removeItem(at: backupPath)
            try fm.copyItem(at: settingsPath, to: backupPath)
            logger.debug("Created backup at \(backupPath.path)")

            let data = try Data(contentsOf: settingsPath)
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw HookError.settingsCorrupted("Root is not a dictionary")
            }
            settings = parsed
        } else {
            settings = [:]
            logger.debug("Creating new settings.json")
        }

        // Merge our hooks
        var hooks = settings["hooks"] as? [String: Any] ?? [:]
        hooks["Notification"] = mergeOurHook(into: hooks["Notification"])
        hooks["Stop"] = mergeOurHook(into: hooks["Stop"])
        settings["hooks"] = hooks

        // Write back with pretty printing
        let outputData = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )

        do {
            try outputData.write(to: settingsPath)
        } catch {
            throw HookError.writeFailed(error)
        }

        logger.info("Installed hooks into settings.json")
    }

    private func deployHookScript() throws {
        let fm = FileManager.default

        // Create hooks directory if needed
        try fm.createDirectory(at: hooksDir, withIntermediateDirectories: true)

        // Get bundled script
        guard let bundledScript = Bundle.main.url(forResource: "your-turn-notify", withExtension: "sh") else {
            throw HookError.scriptNotBundled
        }

        let scriptDest = hooksDir.appendingPathComponent(scriptName)

        // Remove old version if exists
        try? fm.removeItem(at: scriptDest)

        // Copy new version
        do {
            try fm.copyItem(at: bundledScript, to: scriptDest)
        } catch {
            throw HookError.writeFailed(error)
        }

        // Make executable (chmod +x)
        try fm.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptDest.path
        )

        logger.info("Deployed hook script to \(scriptDest.path)")
    }

    /// Build our hook configuration for a single hook type
    private func ourHookConfig() -> [[String: Any]] {
        return [[
            "matcher": "",
            "hooks": [[
                "type": "command",
                "command": "~/.claude/hooks/\(scriptName)"
            ]]
        ]]
    }

    /// Merge our hook into existing hook array, avoiding duplicates
    private func mergeOurHook(into existing: Any?) -> [[String: Any]] {
        var hookArray = existing as? [[String: Any]] ?? []

        // Remove any existing entries with our script (to allow updates)
        hookArray = hookArray.filter { entry in
            guard let hooks = entry["hooks"] as? [[String: Any]] else { return true }
            for hook in hooks {
                if let command = hook["command"] as? String,
                   command.contains("your-turn-notify") {
                    return false
                }
            }
            return true
        }

        // Add our hook config
        hookArray.append(contentsOf: ourHookConfig())

        return hookArray
    }

    /// Remove our hook from existing hook array
    private func removeOurHook(from existing: Any?) -> [[String: Any]] {
        guard var hookArray = existing as? [[String: Any]] else { return [] }

        hookArray = hookArray.filter { entry in
            guard let hooks = entry["hooks"] as? [[String: Any]] else { return true }
            for hook in hooks {
                if let command = hook["command"] as? String,
                   command.contains("your-turn-notify") {
                    return false
                }
            }
            return true
        }

        return hookArray
    }

    /// Check if our hook exists in a hook array
    private func checkForOurHook(in hookConfig: Any?) -> Bool {
        guard let hookArray = hookConfig as? [[String: Any]] else { return false }

        for hookEntry in hookArray {
            guard let hooks = hookEntry["hooks"] as? [[String: Any]] else { continue }
            for hook in hooks {
                if let command = hook["command"] as? String,
                   command.contains("your-turn-notify") {
                    return true
                }
            }
        }
        return false
    }
}
