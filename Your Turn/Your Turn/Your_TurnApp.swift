//
//  Your_TurnApp.swift
//  Your Turn
//
//  Created by David Kramer on 1/19/26.
//

import SwiftUI

@main
struct Your_TurnApp: App {
    var body: some Scene {
        MenuBarExtra("Your Turn", systemImage: "bubble.left") {
            Button("Settings...") {
                // Phase 2 will implement
            }
            .disabled(true)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
