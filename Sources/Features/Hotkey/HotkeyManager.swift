//
//  HotkeyManager.swift
//  Your Turn
//
//  Created by Claude on 2/15/26.
//

import Carbon.HIToolbox
import Foundation
import os.log

/// Manages global hotkey registration via Carbon's RegisterEventHotKey.
/// Posts `.hotkeyPressed` notification when the hotkey is triggered.
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private let logger = Logger(category: "HotkeyManager")

    /// Carbon hotkey signature: "YTRN" (Your Turn)
    private let hotkeySignature: UInt32 = 0x5954524E

    /// Carbon hotkey ID
    private let hotkeyID: UInt32 = 1

    /// Reference to the registered hotkey (nil if not registered)
    private var hotkeyRef: EventHotKeyRef?

    /// Installed Carbon event handler reference
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    // MARK: - Public API

    /// Read UserDefaults and register (or unregister) the hotkey accordingly.
    func registerFromDefaults() {
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: "hotkey.enabled")

        guard enabled, let config = HotkeyConfiguration.load() else {
            unregister()
            return
        }

        register(config: config)
    }

    /// Unregister the current hotkey and remove the event handler.
    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
            logger.debug("Keyboard shortcut unregistered")
        }

        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    // MARK: - Private

    private func register(config: HotkeyConfiguration) {
        // Clean state: unregister before re-registering
        unregister()

        // Install Carbon event handler if not yet installed
        installEventHandler()

        // Register the hotkey
        let hotkeyIDStruct = EventHotKeyID(signature: hotkeySignature, id: hotkeyID)
        let status = RegisterEventHotKey(
            UInt32(config.keyCode),
            config.carbonModifiers,
            hotkeyIDStruct,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            logger.error("Failed to register keyboard shortcut (status: \(status)). Another app may hold this combination.")
            hotkeyRef = nil
        } else {
            logger.info("Keyboard shortcut registered: \(config.displayString, privacy: .public)")
        }
    }

    private func installEventHandler() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ in
            guard let event = event else { return OSStatus(eventNotHandledErr) }

            var hotkeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                UInt32(kEventParamDirectObject),
                UInt32(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )

            guard status == noErr else { return status }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .hotkeyPressed, object: nil)
            }

            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        if status != noErr {
            logger.error("Failed to install Carbon event handler (status: \(status))")
        }
    }
}
