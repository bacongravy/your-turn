//
//  AppleScriptRunner.swift
//  Your Turn
//
//  Shared AppleScript execution utility used by terminal integrations.
//

import AppKit
import Foundation
import os.log

/// Result of automation permission request
enum AutomationResult: Equatable {
    case success
    case denied
    case error(String)

    /// Returns true if this result represents an error (denied or error case)
    var isError: Bool {
        switch self {
        case .success:
            return false
        case .denied, .error:
            return true
        }
    }
}

/// Shared AppleScript execution utility.
/// Provides consistent script execution and error handling across terminal integrations.
enum AppleScriptRunner {
    private static let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "AppleScriptRunner")

    /// Standard error code for automation permission denied
    static let automationDeniedErrorCode = -1743

    /// Execute an AppleScript and return the result
    /// - Parameter source: The AppleScript source code
    /// - Returns: A tuple containing the result descriptor and error info (both optional)
    @discardableResult
    static func executeScript(_ source: String) -> (result: NSAppleEventDescriptor?, error: NSDictionary?) {
        guard let script = NSAppleScript(source: source) else {
            logger.error("Failed to create AppleScript")
            return (nil, nil)
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        if let error = errorInfo {
            logger.debug("AppleScript error: \(error)")
        }

        return (result, errorInfo)
    }

    /// Activate an application (bring to front).
    /// - Parameter appName: The application name (e.g., "Terminal", "iTerm2", "Warp")
    static func activateApp(_ appName: String) {
        let script = """
            tell application "\(appName)"
                activate
            end tell
            """
        executeScript(script)
    }

    /// Check automation permission for a given application by executing a simple AppleScript.
    /// This will show a permission dialog if not yet granted.
    /// Executes on a background queue to prevent blocking the main thread.
    /// - Parameters:
    ///   - appName: The application name to check (e.g., "Terminal", "iTerm")
    ///   - completion: Called on the main queue with the result
    static func checkAutomationPermission(for appName: String, completion: @escaping (AutomationResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let (result, error) = executeScript("tell application \"\(appName)\" to count windows")

            let automationResult: AutomationResult
            if let error = error {
                let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"

                if errorNumber == automationDeniedErrorCode {
                    automationResult = .denied
                } else {
                    automationResult = .error(errorMessage)
                }
            } else if result != nil {
                automationResult = .success
            } else {
                automationResult = .error("AppleScript execution failed")
            }

            DispatchQueue.main.async {
                completion(automationResult)
            }
        }
    }
}
