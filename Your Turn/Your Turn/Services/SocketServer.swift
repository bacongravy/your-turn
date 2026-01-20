//
//  SocketServer.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Combine
import Foundation
import Network
import os.log

/// Unix socket server that listens for JSON-RPC messages from Claude Code hooks.
/// Uses Network.framework NWListener for modern async socket handling.
@MainActor
class SocketServer: ObservableObject {
    private var listener: NWListener?
    private let socketPath: URL
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "SocketServer")

    @Published private(set) var lastEvent: HookEvent?
    @Published private(set) var isRunning = false
    @Published private(set) var error: Error?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Claude Notify")
        socketPath = appDir.appendingPathComponent("claude-notify.sock")
    }

    func start() {
        do {
            // Create app directory if needed
            try FileManager.default.createDirectory(
                at: socketPath.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Remove stale socket file (from crash recovery)
            try? FileManager.default.removeItem(at: socketPath)

            // Configure NWListener for Unix socket
            let params = NWParameters()
            params.defaultProtocolStack.transportProtocol = NWProtocolTCP.Options()
            params.requiredLocalEndpoint = NWEndpoint.unix(path: socketPath.path)
            params.allowLocalEndpointReuse = true

            listener = try NWListener(using: params)

            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    self?.handleStateChange(state)
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handleConnection(connection)
                }
            }

            listener?.start(queue: .main)
            logger.info("Socket server starting at \(self.socketPath.path)")
        } catch {
            logger.error("Failed to start socket server: \(error.localizedDescription)")
            self.error = error
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false

        // Clean up socket file
        try? FileManager.default.removeItem(at: socketPath)
        logger.info("Socket server stopped")
    }

    private func handleStateChange(_ state: NWListener.State) {
        switch state {
        case .ready:
            isRunning = true
            error = nil
            logger.info("Socket server ready")
        case .failed(let err):
            isRunning = false
            error = err
            logger.error("Socket server failed: \(err.localizedDescription)")
        case .cancelled:
            isRunning = false
            logger.info("Socket server cancelled")
        case .waiting(let err):
            logger.warning("Socket server waiting: \(err.localizedDescription)")
        default:
            break
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        logger.debug("New connection received")

        // Use a class to hold accumulated data since closures can't capture inout
        let connectionHandler = ConnectionHandler(server: self, connection: connection, logger: logger)
        connectionHandler.start()
    }

    fileprivate func processMessage(_ data: Data) {
        guard !data.isEmpty else {
            logger.debug("Empty message received, ignoring")
            return
        }

        do {
            let event = try JSONDecoder().decode(HookEvent.self, from: data)
            logger.info("Received event: \(event.hookEventName) for session \(event.sessionId)")
            self.lastEvent = event
        } catch {
            // Log and ignore malformed JSON per CONTEXT.md decision
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.warning("Failed to parse hook event: \(error.localizedDescription). Raw: \(jsonString.prefix(200))")
            } else {
                logger.warning("Failed to parse hook event: \(error.localizedDescription). Data not UTF-8.")
            }
        }
    }
}

/// Helper class to manage a single connection's lifecycle and data accumulation.
/// This is nonisolated to work with Network.framework callbacks.
private class ConnectionHandler: @unchecked Sendable {
    private weak var server: SocketServer?
    private let connection: NWConnection
    private let logger: Logger
    private var accumulatedData = Data()

    init(server: SocketServer, connection: NWConnection, logger: Logger) {
        self.server = server
        self.connection = connection
        self.logger = logger
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleState(state)
        }
        connection.start(queue: .main)
    }

    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            logger.debug("Connection ready, starting receive")
            receiveData()
        case .cancelled, .failed:
            logger.debug("Connection ended")
        default:
            break
        }
    }

    private func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                self.accumulatedData.append(data)
                self.logger.debug("Received \(data.count) bytes, total: \(self.accumulatedData.count)")
            }

            if isComplete {
                // Connection closed - process accumulated data
                self.logger.debug("Connection complete, processing \(self.accumulatedData.count) bytes")
                let finalData = self.accumulatedData
                Task { @MainActor in
                    self.server?.processMessage(finalData)
                }
                self.connection.cancel()
            } else if let error = error {
                self.logger.error("Receive error: \(error.localizedDescription)")
                self.connection.cancel()
            } else {
                // Continue receiving (data may arrive in chunks)
                self.receiveData()
            }
        }
    }
}
