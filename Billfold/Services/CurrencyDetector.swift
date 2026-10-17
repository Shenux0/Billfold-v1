// CurrencyDetector.swift
// Works out which currency a receipt is in from the codes and symbols printed on it,
// so a "$" receipt is saved in dollars instead of the main currency.

import Foundation

enum CurrencyDetector {
    /// The currency code printed on the receipt, or nil if the receipt does not show one.
    nonisolated static func detect(in lines: [String]) -> String? {
        let text = lines.joined(separator: "\n")

        // 1. A written code, such as "USD 12.50" or "Total (LKR)", is the clearest sign.
        for code in Currency.codes {
            if text.range(of: "\\b" + code + "\\b", options: .regularExpression) != nil {
                return code
            }
        }

        // 2. A currency symbol. "$" is taken as US dollars, the most common dollar.
        let symbols = [("$", "USD"), ("€", "EUR"), ("£", "GBP"), ("₹", "INR")]
        for (symbol, code) in symbols where text.contains(symbol) {
            return code
        }

        // 3. "Rs" or "Rs." is how Sri Lankan receipts usually print rupees.
        if text.range(of: #"\b[Rr][Ss]\b"#, options: .regularExpression) != nil {
            return "LKR"
        }
        return nil
    }
}
