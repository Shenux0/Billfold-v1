// CategoryGuesser.swift
// Guesses a category from the merchant name with a small keyword table.
// Deliberately simple: it only saves the user one tap, and they can change it.

import Foundation

enum CategoryGuesser {
    nonisolated static func guess(from merchant: String?) -> ExpenseCategory {
        guard let merchant else { return .other }
        let name = merchant.lowercased()
        for entry in keywords() {
            if entry.words.contains(where: { name.contains($0) }) {
                return entry.category
            }
        }
        return .other
    }

    // Checked in this order; the first match wins. A function, not a stored
    // property, so it works whatever the project's default actor isolation is.
    private nonisolated static func keywords() -> [(category: ExpenseCategory, words: [String])] {
        [
            (.food, ["restaurant", "cafe", "coffee", "bakery", "pizza", "burger",
                     "keells", "cargills", "arpico", "supermarket", "grocery"]),
            (.transport, ["uber", "pickme", "fuel", "petrol", "diesel", "taxi", "bus", "ceypetco"]),
            (.health, ["pharmacy", "hospital", "clinic", "medical"]),
            (.bills, ["dialog", "mobitel", "slt", "electricity", "water board", "internet"]),
            (.shopping, ["odel", "mall", "store", "fashion", "books"]),
            (.entertainment, ["cinema", "movie", "games", "theatre"])
        ]
    }
}
