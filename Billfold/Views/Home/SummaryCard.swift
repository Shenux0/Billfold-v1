// SummaryCard.swift
// The month summary on Home. Swipe left or right (or use the chevrons)
// to move between months; the total rolls to its new value.

import SwiftUI

struct SummaryCard: View {
    let expenses: [Expense]

    @AppStorage("currencyCode") private var currencyCode = "LKR"
    @State private var month = Date()
    @State private var movingForward = true

    private var allThisMonth: [Expense] {
        ExpenseStats.expenses(expenses, in: .month, containing: month)
    }
    /// The big total only counts the main currency; other currencies are listed under it.
    private var monthExpenses: [Expense] {
        ExpenseStats.expenses(allThisMonth, inCurrency: currencyCode)
    }
    private var otherCurrencies: [Expense] {
        allThisMonth.filter { $0.currencyCode != currencyCode }
    }
    private var total: Double { ExpenseStats.total(of: monthExpenses) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            details
                .id(month) // a new id per month lets SwiftUI slide the old one out and the new one in
                .transition(slide)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .card()
        .contentShape(Rectangle())
        .simultaneousGesture(swipe) // simultaneous, so the page can still scroll vertically
    }

    private var header: some View {
        HStack {
            Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous Month")
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next Month")
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(total.asCurrency(code: currencyCode))
                .font(.largeTitle)
                .fontDesign(.rounded)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.snappy, value: total)
                .accessibilityIdentifier("monthTotalText")
            Text(monthExpenses.count == 1 ? "1 expense" : "\(monthExpenses.count) expenses")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let top = ExpenseStats.totalsByCategory(monthExpenses).first {
                Text("Top: \(top.category.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !otherCurrencies.isEmpty {
                Text("Also " + ExpenseStats.totalsByCurrency(otherCurrencies)
                    .map { $0.total.asCurrency(code: $0.code) }
                    .joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The new month comes in from the side the user swiped towards.
    private var slide: AnyTransition {
        .asymmetric(insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity))
    }

    /// Only a mostly horizontal drag of 50+ points counts, so scrolling the page still works.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let width = value.translation.width
                let height = value.translation.height
                guard abs(width) > abs(height), abs(width) > 50 else { return }
                changeMonth(by: width < 0 ? 1 : -1) // swipe left = next month
            }
    }

    private func changeMonth(by value: Int) {
        movingForward = value > 0
        withAnimation(.snappy) {
            month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
        }
    }
}
