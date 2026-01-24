//
//  GeneralTabContent.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// Content wrapper for the General tab in Settings
/// Contains: Integration Status, Launch at Login, About
struct GeneralTabContent: View {
    var socketServer: SocketServer = .shared

    var body: some View {
        Form {
            HealthStatusSection(socketServer: socketServer)
            GeneralSection()
            AboutSection()
        }
        .formStyle(.grouped)
        .padding(.top, -20)
    }
}
