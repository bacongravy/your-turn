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
    case unknown  // Not yet tested (user must explicitly trigger)
}

/// Aggregated health status for all integrations
struct HealthStatus {
    var hooks: CheckState = .checking
    var notifications: CheckState = .checking
    var iTermIntegration: CheckState = .unknown
    var socket: CheckState = .checking
}
