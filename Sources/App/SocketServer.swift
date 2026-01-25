//
//  SocketServer.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import Combine
import Foundation
import os.log

/// Unix socket server that listens for JSON-RPC messages from Claude Code hooks.
/// Uses POSIX sockets directly since Network.framework NWListener doesn't support Unix domain sockets.
@MainActor
class SocketServer: ObservableObject {
    /// Shared instance for access from non-SwiftUI code (e.g., AppDelegate-created windows)
    static var shared: SocketServer!

    private var serverSocket: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private let socketPath: URL
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "SocketServer")
    private let socketQueue = DispatchQueue(label: "net.bacongravy.Your-Turn.socket", qos: .utility)

    @Published private(set) var lastEvent: HookEvent?
    @Published private(set) var isRunning = false
    @Published private(set) var error: Error?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Your Turn")
        socketPath = appDir.appendingPathComponent("claude-notify.sock")

        // Auto-start on initialization
        // Since SocketServer is @MainActor and @StateObject creation happens on main actor, this is safe
        start()
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

            logger.info("Socket server starting at \(self.socketPath.path)")

            // Create Unix domain socket
            serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
            guard serverSocket >= 0 else {
                throw SocketError.createFailed(errno: errno)
            }

            // Set socket options
            var reuseAddr: Int32 = 1
            setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))

            // Bind to path
            var addr = sockaddr_un()
            addr.sun_family = sa_family_t(AF_UNIX)
            let pathBytes = socketPath.path.utf8CString
            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                let bound = ptr.withMemoryRebound(to: CChar.self, capacity: 104) { sunPath in
                    pathBytes.withUnsafeBufferPointer { pathBuffer in
                        let count = min(pathBuffer.count, 104)
                        for i in 0..<count {
                            sunPath[i] = pathBuffer[i]
                        }
                        return count
                    }
                }
                _ = bound
            }

            let bindResult = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
                }
            }
            guard bindResult == 0 else {
                close(serverSocket)
                serverSocket = -1
                throw SocketError.bindFailed(errno: errno)
            }

            // Listen with backlog of 5
            guard listen(serverSocket, 5) == 0 else {
                close(serverSocket)
                serverSocket = -1
                throw SocketError.listenFailed(errno: errno)
            }

            // Set non-blocking
            let flags = fcntl(serverSocket, F_GETFL)
            _ = fcntl(serverSocket, F_SETFL, flags | O_NONBLOCK)

            // Create dispatch source for accepting connections
            acceptSource = DispatchSource.makeReadSource(fileDescriptor: serverSocket, queue: socketQueue)
            acceptSource?.setEventHandler { [weak self] in
                self?.acceptConnection()
            }
            acceptSource?.setCancelHandler { [weak self] in
                if let fd = self?.serverSocket, fd >= 0 {
                    close(fd)
                }
            }
            acceptSource?.resume()

            isRunning = true
            error = nil
            logger.info("Socket server ready")
        } catch {
            logger.error("Failed to start socket server: \(error.localizedDescription)")
            self.error = error
        }
    }

    func stop() {
        acceptSource?.cancel()
        acceptSource = nil

        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }

        isRunning = false

        // Clean up socket file
        try? FileManager.default.removeItem(at: socketPath)
        logger.info("Socket server stopped")
    }

    private func acceptConnection() {
        var clientAddr = sockaddr_un()
        var addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

        let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                accept(serverSocket, sockaddrPtr, &addrLen)
            }
        }

        guard clientSocket >= 0 else {
            if errno != EWOULDBLOCK && errno != EAGAIN {
                logger.error("Accept failed: \(String(cString: strerror(errno)))")
            }
            return
        }

        logger.debug("New connection accepted")

        // Handle connection in background
        socketQueue.async { [weak self] in
            self?.handleConnection(clientSocket)
        }
    }

    private nonisolated func handleConnection(_ clientSocket: Int32) {
        defer { close(clientSocket) }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)

        // Read until connection closes
        while true {
            let bytesRead = read(clientSocket, &buffer, buffer.count)
            if bytesRead > 0 {
                data.append(contentsOf: buffer[0..<bytesRead])
            } else if bytesRead == 0 {
                // Connection closed
                break
            } else {
                if errno == EAGAIN || errno == EWOULDBLOCK {
                    // Would block, try again
                    usleep(1000) // 1ms
                    continue
                }
                logger.error("Read error: \(String(cString: strerror(errno)))")
                break
            }
        }

        logger.debug("Connection complete, processing \(data.count) bytes")

        // Process on main actor
        let finalData = data
        Task { @MainActor [weak self] in
            self?.processMessage(finalData)
        }
    }

    private func processMessage(_ data: Data) {
        guard !data.isEmpty else {
            logger.debug("Empty message received, ignoring")
            return
        }

        do {
            let event = try JSONDecoder().decode(HookEvent.self, from: data)
            var eventName = event.hookEventName
            if let notificationType = event.notificationType {
                eventName += ".\(notificationType)"
            }
            logger.info("Received event: \(eventName) for session \(event.sessionId)")
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

/// Socket-specific errors
enum SocketError: LocalizedError {
    case createFailed(errno: Int32)
    case bindFailed(errno: Int32)
    case listenFailed(errno: Int32)

    var errorDescription: String? {
        switch self {
        case .createFailed(let e):
            return "Failed to create socket: \(String(cString: strerror(e)))"
        case .bindFailed(let e):
            return "Failed to bind socket: \(String(cString: strerror(e)))"
        case .listenFailed(let e):
            return "Failed to listen on socket: \(String(cString: strerror(e)))"
        }
    }
}
