//
//  HealthStatus.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Foundation

/// Represents the state of a single health check
enum CheckState: Equatable {
    case ok
    case failed
    case checking
}

/// Aggregated health status for all integrations
struct HealthStatus {
    var hooks: CheckState = .checking
    var notifications: CheckState = .checking
    var automation: CheckState = .checking
    var socket: CheckState = .checking

    /// Count of critical issues (excludes automation which is optional)
    var criticalIssuesCount: Int {
        [hooks, notifications, socket].filter { $0 == .failed }.count
    }
}
