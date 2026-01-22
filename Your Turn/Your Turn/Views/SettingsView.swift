//
//  SettingsView.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

struct SettingsView: View {
    var socketServer: SocketServer?

    var body: some View {
        Form {
            HealthStatusSection(socketServer: socketServer)
            GeneralSection()
            NotificationSection()
            EventsSection()
            AboutSection()
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }
}
