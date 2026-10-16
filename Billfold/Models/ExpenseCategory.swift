// ExpenseCategory.swift
// The fixed list of spending categories. Each one owns its display name,
// SF Symbol and color, so every screen shows a category the same way.

import SwiftUI

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food, transport, shopping, bills, health, entertainment, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .bills: return "Bills"
        case .health: return "Health"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .bills: return "bolt.fill"
        case .health: return "cross.case.fill"
        case .entertainment: return "popcorn.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    // System colors adapt to Light and Dark Mode on their own.
    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .pink
        case .bills: return .purple
        case .health: return .red
        case .entertainment: return .indigo
        case .other: return .gray
        }
    }
}
