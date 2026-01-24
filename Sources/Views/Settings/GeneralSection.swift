//
//  GeneralSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI
import ServiceManagement

struct GeneralSection: View {
    @State private var launchAtLogin = false

    var body: some View {
        Section {
            ToggleRow(
                title: "Launch at login",
                subtitle: "Start automatically when you log in",
                isOn: $launchAtLogin
            )
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .onChange(of: launchAtLogin) { _, newValue in
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silent failure - revert toggle per CONTEXT.md
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }
}
