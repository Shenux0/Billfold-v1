// Currency.swift
// The currencies Billfold supports and the user's main currency.
// The main currency is picked in Settings and stored under one shared key.

import Foundation

enum Currency {
    static let codes = ["LKR", "USD", "EUR", "GBP", "INR", "AUD"]
    static let storageKey = "currencyCode"
    static let fallback = "LKR"

    /// The main currency from Settings. Views read the same value with @AppStorage("currencyCode").
    nonisolated static var main: String {
        UserDefaults.standard.string(forKey: storageKey) ?? fallback
    }
}
