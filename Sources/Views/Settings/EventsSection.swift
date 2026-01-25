//
//  EventsSection.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

struct EventsSection: View {
    @AppStorage("notify.taskComplete") private var notifyTaskComplete = true
    @AppStorage("notify.inputNeeded") private var notifyInputNeeded = true
    // idle_prompt appears broken in Claude Code (GitHub issue #8320 closed as "not planned")
    // @AppStorage("notify.idle") private var notifyIdle = false

    var body: some View {
        Section {
            ToggleRow(
                title: "Task complete",
                subtitle: "When the agent finishes",
                isOn: $notifyTaskComplete
            )
            ToggleRow(
                title: "Input needed",
                subtitle: "When the agent stops to ask for input",
                isOn: $notifyInputNeeded
            )
            // idle_prompt appears broken in Claude Code (GitHub issue #8320 closed as "not planned")
            // ToggleRow(
            //     title: "Idle reminder",
            //     subtitle: "When the agent has been waiting 60+ seconds",
            //     isOn: $notifyIdle
            // )
        }
    }
}
