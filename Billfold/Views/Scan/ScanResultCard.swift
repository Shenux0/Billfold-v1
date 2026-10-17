// ScanResultCard.swift
// Shows what the parser found on a receipt: merchant, total and date.
// Anything missing says "Not found", so the user knows to fill it in.

import SwiftUI

struct ScanResultCard: View {
    let parsed: ParsedReceipt

    @AppStorage("currencyCode") private var currencyCode = "LKR"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found on Receipt").font(.headline)
            row("Merchant", value: parsed.merchant)
            // Use the currency printed on the receipt, or the main currency if none was found.
            row("Total", value: parsed.total?.asCurrency(code: parsed.currencyCode ?? currencyCode))
            row("Date", value: parsed.date?.formatted(date: .abbreviated, time: .omitted))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func row(_ label: String, value: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "Not found")
                .fontWeight(value == nil ? .regular : .semibold)
                .foregroundStyle(value == nil ? Color.secondary : Color.primary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
