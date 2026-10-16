// ExpenseRow.swift
// One expense in a list: badge, title, date and amount.
// At the largest text sizes the amount moves under the title so nothing is cut off.

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    @AppStorage("currencyCode") private var currencyCode = "LKR"
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(category: expense.category)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    titleText
                    dateText
                    amountText
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    titleText
                    dateText
                }
                Spacer(minLength: 8)
                amountText
            }
        }
        // VoiceOver reads the whole row as one sentence instead of four pieces.
        .accessibilityElement(children: .combine)
    }

    private var titleText: some View {
        Text(expense.title)
            .font(.headline)
            .lineLimit(2)
    }

    private var dateText: some View {
        Text(expense.date, format: .dateTime.day().month().year())
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var amountText: some View {
        Text(expense.amount.asCurrency(code: currencyCode))
            .font(.body)
            .fontDesign(.rounded)
            .bold()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
