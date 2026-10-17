// InsightsView.swift
// Where the money goes: a donut chart by category, a ranked category list
// and a bar chart over time, for this week, month or year.

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @AppStorage("currencyCode") private var currencyCode = "LKR"
    @State private var period: Period = .month

    var body: some View {
        // Work out the numbers once here and pass them down, instead of in every child view.
        let current = ExpenseStats.expenses(expenses, in: period, containing: Date())
        let totals = ExpenseStats.totalsByCategory(current)
        let total = ExpenseStats.total(of: current)

        ScrollView {
            VStack(spacing: Theme.spacing) {
                Picker("Period", selection: $period) {
                    ForEach(Period.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if current.isEmpty {
                    ContentUnavailableView("No Spending", systemImage: "chart.pie",
                                           description: Text("Nothing was spent this \(period.title.lowercased())."))
                } else {
                    donutCard(totals: totals, total: total)
                    categoryList(totals: totals, total: total)
                    barCard(current)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insights")
    }

    private func donutCard(totals: [CategoryTotal], total: Double) -> some View {
        Chart(totals) { item in
            SectorMark(angle: .value("Amount", item.total), innerRadius: .ratio(0.62), angularInset: 2)
                .foregroundStyle(item.category.color)
                .cornerRadius(4)
        }
        .frame(height: 220)
        .overlay {
            VStack(spacing: 2) {
                Text("Total").font(.caption).foregroundStyle(.secondary)
                Text(total.asCurrency(code: currencyCode))
                    .font(.title3)
                    .fontDesign(.rounded)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: 120)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartSummary(totals: totals, total: total))
        .card()
    }

    private func categoryList(totals: [CategoryTotal], total: Double) -> some View {
        VStack(spacing: 12) {
            ForEach(totals) { item in
                HStack(spacing: 12) {
                    CategoryBadge(category: item.category)
                    Text(item.category.title).font(.body)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.total.asCurrency(code: currencyCode))
                            .fontDesign(.rounded)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text((item.total / total).formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .card()
    }

    private func barCard(_ current: [Expense]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Over Time").font(.headline)
            // One bar mark per expense; Charts adds up expenses that share a day or month.
            Chart(current) { expense in
                BarMark(x: .value("Date", expense.date, unit: period.chartUnit),
                        y: .value("Amount", expense.amount))
                    .foregroundStyle(Theme.accent)
            }
            .frame(height: 220)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bar chart of spending over this \(period.title.lowercased()), " +
                                "\(current.count) expenses in total.")
        }
        .card()
    }

    /// One sentence VoiceOver can read instead of the chart, for example "Food 40%, Bills 25%".
    private func chartSummary(totals: [CategoryTotal], total: Double) -> String {
        let parts = totals.map { item in
            "\(item.category.title) \((item.total / total).formatted(.percent.precision(.fractionLength(0))))"
        }
        return "Spending by category. Total \(total.asCurrency(code: currencyCode)). " + parts.joined(separator: ", ")
    }
}
