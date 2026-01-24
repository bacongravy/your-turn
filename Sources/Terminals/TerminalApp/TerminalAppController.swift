//
//  TerminalAppController.swift
//  Your Turn
//
//  Thin adapter for TerminalActivating protocol.
//  All Terminal.app logic is in TerminalApp.swift.
//

import AppKit

/// Thin adapter that conforms to TerminalActivating protocol.
/// Delegates all Terminal.app operations to the TerminalApp enum.
@MainActor
final class TerminalAppController: TerminalActivating {
    static let shared = TerminalAppController()
    private init() {}

    func activate(termSessionId: String?, tty: String?) {
        TerminalApp.activate(tty: tty)
    }
}
