// Formatting.swift
// One place to turn numbers into money text, so every screen formats
// amounts the same way for the chosen currency.

import Foundation

extension Double {
    /// For example 1250.5 with "LKR" becomes "LKR 1,250.50" (the exact look follows the device region).
    func asCurrency(code: String) -> String {
        self.formatted(.currency(code: code))
    }
}
