// ParsedReceipt.swift
// What the receipt parser managed to find. Every field is optional
// because a messy photo may not show all of them.

import Foundation

struct ParsedReceipt: Equatable {
    var merchant: String?
    var total: Double?
    var date: Date?
}
