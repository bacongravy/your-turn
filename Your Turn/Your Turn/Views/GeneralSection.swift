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
    @AppStorage("setupComplete") private var setupComplete = true

    var socketServer: SocketServer?

    var body: some View {
        HealthStatusSection(socketServer: socketServer)

        Section {
            ToggleRow(
                title: "Launch at Login",
                subtitle: "Start automatically when you log in",
                isOn: $launchAtLogin
            )

            Button("Notification Settings...") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)

            Divider()

            Button("Re-run Setup Wizard...") {
                setupComplete = false
                NotificationCenter.default.post(name: .openSetup, object: nil)
            }
            .buttonStyle(.bordered)
        } header: {
            Text("General")
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
