//
//  TerminalController.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation

/// Protocol for terminal controllers that can activate their terminal.
/// Implementations handle terminal-specific activation logic (AppleScript, NSWorkspace, etc.).
protocol TerminalActivating {
    /// Activate the terminal, optionally focusing a specific session.
    /// - Parameters:
    ///   - termSessionId: TERM_SESSION_ID for iTerm2 (e.g., "w0t0p0:UUID").
    ///   - tty: TTY path for Terminal.app (e.g., "/dev/ttys001").
    /// Implementations use whichever identifier is relevant and ignore the other.
    func activate(termSessionId: String?, tty: String?)
}

/// Registry mapping TERM_PROGRAM values to their terminal controllers.
/// Used by AppDelegate to route notification clicks to the appropriate controller.
@MainActor
final class TerminalRegistry {
    static let shared = TerminalRegistry()

    /// Maps lowercased TERM_PROGRAM values to controllers.
    /// Keys use canonical names: "iterm", "apple_terminal", "warpterminal"
    private var controllers: [String: TerminalActivating] = [:]

    private init() {
        // Register known terminal controllers
        register("iterm", controller: ITermController.shared)
        register("apple_terminal", controller: TerminalAppController.shared)
        register("warpterminal", controller: WarpController.shared)
    }

    /// Register a controller for a TERM_PROGRAM value.
    /// - Parameters:
    ///   - termProgram: The lowercased TERM_PROGRAM value to match.
    ///   - controller: The controller to handle activation for this terminal.
    private func register(_ termProgram: String, controller: TerminalActivating) {
        controllers[termProgram] = controller
    }

    /// Look up the controller for a given TERM_PROGRAM value.
    /// - Parameter termProgram: The TERM_PROGRAM environment variable value.
    /// - Returns: The matching controller, or nil if no match found.
    ///
    /// Matching strategy:
    /// 1. Direct match (exact lowercased key)
    /// 2. Substring match (for values like "iTerm.app" containing "iterm")
    func controller(for termProgram: String?) -> TerminalActivating? {
        guard let termProgram = termProgram, !termProgram.isEmpty else {
            return nil
        }

        let lowercased = termProgram.lowercased()

        // Direct match first
        if let controller = controllers[lowercased] {
            return controller
        }

        // Substring match fallback
        for (key, controller) in controllers {
            if lowercased.contains(key) {
                return controller
            }
        }

        return nil
    }
}
