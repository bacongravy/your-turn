import Foundation
import os.log

extension Logger {
    /// Creates a Logger with the app's bundle identifier as the subsystem.
    init(category: String) {
        self.init(subsystem: Bundle.main.bundleIdentifier ?? "app", category: category)
    }
}
