//
//  WarpController.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation

/// Controller for Warp terminal activation.
/// Warp does not support AppleScript for session focus, so we just activate the app.
@MainActor
final class WarpController: TerminalActivating {
    static let shared = WarpController()

    private init() {}

    /// Activate Warp.
    /// - Parameters:
    ///   - termSessionId: Ignored. Warp does not support session-level focus.
    ///   - tty: Ignored. Warp does not support session-level focus.
    func activate(termSessionId: String?, tty: String?) {
        Warp.activate()
    }
}
