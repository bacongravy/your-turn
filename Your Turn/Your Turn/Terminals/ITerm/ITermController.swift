//
//  ITermController.swift
//  Your Turn
//
//  Thin adapter for TerminalActivating protocol.
//  All iTerm2 logic is in ITerm2.swift.
//

import AppKit

/// Thin adapter that conforms to TerminalActivating protocol.
/// Delegates all iTerm2 operations to the ITerm2 enum.
@MainActor
final class ITermController: TerminalActivating {
    static let shared = ITermController()
    private init() {}

    func activate(sessionId: String?) {
        ITerm2.activate(sessionId: sessionId)
    }
}
