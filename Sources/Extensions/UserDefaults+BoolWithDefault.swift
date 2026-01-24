//
//  UserDefaults+BoolWithDefault.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import Foundation

extension UserDefaults {
    /// Returns bool for key, or defaultValue if key doesn't exist.
    /// Standard bool(forKey:) returns false for missing keys, which
    /// makes it impossible to distinguish "explicitly set to false"
    /// from "never set, use default".
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        object(forKey: key) != nil ? bool(forKey: key) : defaultValue
    }
}
