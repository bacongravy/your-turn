//
//  EventsSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

struct EventsSection: View {
    @AppStorage("notify.permission") private var notifyPermission = true
    @AppStorage("notify.inputNeeded") private var notifyInputNeeded = true
    @AppStorage("notify.taskComplete") private var notifyTaskComplete = false
    @AppStorage("notify.error") private var notifyError = false

    var body: some View {
        Section {
            ToggleRow(
                title: "Permission requests",
                subtitle: "When Claude needs approval to proceed",
                isOn: $notifyPermission
            )
            ToggleRow(
                title: "Input needed",
                subtitle: "When Claude is waiting for your response",
                isOn: $notifyInputNeeded
            )
            ToggleRow(
                title: "Task complete",
                subtitle: "When Claude finishes a task",
                isOn: $notifyTaskComplete
            )
            ToggleRow(
                title: "Errors",
                subtitle: "When something goes wrong",
                isOn: $notifyError
            )
        }
    }
}
