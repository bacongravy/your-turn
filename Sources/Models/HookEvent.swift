//
//  HookEvent.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation

/// Represents an event received from Claude Code hooks via JSON-RPC.
/// All events contain session info; tool-specific and notification-specific fields are optional.
struct HookEvent: Codable {
    // Core identifiers (required)
    let sessionId: String
    let cwd: String
    let hookEventName: String

    // Common optional fields
    let transcriptPath: String?
    let permissionMode: String?

    // Tool-specific fields
    let toolName: String?
    let toolInput: ToolInput?

    // Notification-specific fields
    let message: String?
    let notificationType: String?

    // Stop-specific fields
    let stopHookActive: Bool?

    // Environment variables passed by hook script
    let termSessionId: String?
    let termProgram: String?
    let tty: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cwd
        case hookEventName = "hook_event_name"
        case transcriptPath = "transcript_path"
        case permissionMode = "permission_mode"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case message
        case notificationType = "notification_type"
        case stopHookActive = "stop_hook_active"
        case termSessionId = "term_session_id"
        case termProgram = "term_program"
        case tty
    }
}

/// Tool input varies by tool type. All fields optional since different tools use different fields.
struct ToolInput: Codable {
    let command: String?      // Bash tool
    let description: String?  // Bash tool
    let filePath: String?     // Read/Write/Edit tools
    let content: String?      // Write tool

    enum CodingKeys: String, CodingKey {
        case command
        case description
        case filePath = "file_path"
        case content
    }
}
