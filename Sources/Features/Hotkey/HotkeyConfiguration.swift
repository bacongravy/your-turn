//
//  HotkeyConfiguration.swift
//  Your Turn
//
//  Created by Claude on 2/15/26.
//

import AppKit
import Carbon.HIToolbox

/// Data model for a global hotkey binding: virtual key code + modifier flags.
/// Handles Cocoa-to-Carbon modifier conversion, human-readable display, and UserDefaults persistence.
struct HotkeyConfiguration {
    let keyCode: UInt16
    let cocoaModifiers: NSEvent.ModifierFlags

    // MARK: - Carbon Conversion

    /// Converts Cocoa modifier flags to Carbon modifier mask for RegisterEventHotKey.
    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        if cocoaModifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if cocoaModifiers.contains(.option)  { carbon |= UInt32(optionKey) }
        if cocoaModifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if cocoaModifiers.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    // MARK: - Display

    /// Human-readable string using standard macOS modifier symbols (e.g. "^~C").
    var displayString: String {
        var parts = ""
        if cocoaModifiers.contains(.control) { parts += "\u{2303}" } // ⌃
        if cocoaModifiers.contains(.option)  { parts += "\u{2325}" } // ⌥
        if cocoaModifiers.contains(.shift)   { parts += "\u{21E7}" } // ⇧
        if cocoaModifiers.contains(.command) { parts += "\u{2318}" } // ⌘
        parts += keyName
        return parts
    }

    /// Locale-aware key name via UCKeyTranslate.
    private var keyName: String {
        // Try UCKeyTranslate for locale-aware name
        if let name = Self.keyNameFromUCKeyTranslate(keyCode: keyCode) {
            return name.uppercased()
        }
        // Fallback to key code number
        return "Key\(keyCode)"
    }

    private static func keyNameFromUCKeyTranslate(keyCode: UInt16) -> String? {
        guard let keyboard = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let layoutDataRef = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }

        let layoutData = unsafeBitCast(layoutDataRef, to: CFData.self) as Data
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length: Int = 0

        let result = layoutData.withUnsafeBytes { rawBuffer in
            guard let ptr = rawBuffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return errSecInternalError
            }
            return UCKeyTranslate(
                ptr,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0, // no modifiers for key name
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
        }

        guard result == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }

    // MARK: - Persistence

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(Int(keyCode), forKey: "hotkey.keyCode")
        defaults.set(Int(cocoaModifiers.rawValue), forKey: "hotkey.modifiers")
    }

    static func load() -> HotkeyConfiguration? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "hotkey.keyCode") != nil,
              defaults.object(forKey: "hotkey.modifiers") != nil else {
            return nil
        }
        let keyCode = UInt16(defaults.integer(forKey: "hotkey.keyCode"))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(defaults.integer(forKey: "hotkey.modifiers")))
        return HotkeyConfiguration(keyCode: keyCode, cocoaModifiers: modifiers)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hotkey.keyCode")
        defaults.removeObject(forKey: "hotkey.modifiers")
    }
}
