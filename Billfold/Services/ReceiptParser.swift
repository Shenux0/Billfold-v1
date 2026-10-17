// ReceiptParser.swift
// Turns the raw text lines read from a receipt into a merchant, total and date.
// Pure logic with no UI or Vision, so it is fully unit tested.

import Foundation

enum ReceiptParser {
    nonisolated static func parse(lines: [String]) -> ParsedReceipt {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return ParsedReceipt(merchant: findMerchant(in: cleaned),
                             total: findTotal(in: cleaned),
                             date: findDate(in: cleaned),
                             currencyCode: CurrencyDetector.detect(in: cleaned))
    }

    /// Every money amount on one line, left to right.
    /// An amount must have exactly two decimals ("1,250.00" or "450.00"), so phone
    /// numbers and dates such as "12.10.2026" are not mistaken for money.
    /// Assumes "." is the decimal separator.
    nonisolated static func amounts(in line: String) -> [Double] {
        let line = removeSpacesInNumbers(line)
        let pattern = #"(?<![0-9,])([0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)\.[0-9]{2}(?![0-9]|\.[0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(line.startIndex..., in: line)
        return regex.matches(in: line, range: range).compactMap { match in
            guard let textRange = Range(match.range, in: line) else { return nil }
            return Double(line[textRange].replacingOccurrences(of: ",", with: ""))
        }
    }

    /// OCR often adds stray spaces around the decimal point, such as "1,250. 00".
    /// Commas are left alone, because "Items 3, 450.00" must not become 3,450.00.
    private nonisolated static func removeSpacesInNumbers(_ line: String) -> String {
        line.replacingOccurrences(of: #"(?<=[0-9])\s*\.\s*(?=[0-9]{2}(?![0-9]))"#,
                                  with: ".", options: .regularExpression)
    }

    // MARK: - Total

    /// The largest amount on a "total" line. If there is no total line,
    /// the largest amount anywhere on the receipt is the best guess.
    private nonisolated static func findTotal(in lines: [String]) -> Double? {
        var candidates: [Double] = []
        for (index, line) in lines.enumerated() where isTotalLine(line) {
            if let last = amounts(in: line).last {
                candidates.append(last)
            } else if index + 1 < lines.count, let next = amounts(in: lines[index + 1]).first {
                // OCR often puts the label and the number on separate lines.
                candidates.append(next)
            }
        }
        if let best = candidates.max() { return best }
        return lines.flatMap { amounts(in: $0) }.max()
    }

    private nonisolated static func isTotalLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        // "total" also covers "Net Total" and "Grand Total"; the others are common on Sri Lankan bills.
        let labels = ["total", "amount due", "balance due", "net amount", "payable", "bill amount"]
        // "Subtotal" is before tax and discounts, so it is never the final total.
        return labels.contains { lower.contains($0) } && !lower.contains("sub")
    }

    // MARK: - Merchant

    /// The shop name is usually printed at the top, so look at the first 5 lines only.
    private nonisolated static func findMerchant(in lines: [String]) -> String? {
        let skipWords = ["receipt", "invoice", "tel", "phone", "date", "www"]
        for line in lines.prefix(5) {
            let lower = line.lowercased()
            let letters = line.filter { $0.isLetter }.count
            let digits = line.filter { $0.isNumber }.count
            let nonSpaces = line.filter { !$0.isWhitespace }.count
            let mostlyDigits = digits * 2 > nonSpaces
            if letters < 3 || mostlyDigits || skipWords.contains(where: { lower.contains($0) }) {
                continue
            }
            // "KEELLS SUPER" reads better as "Keells Super".
            return line == line.uppercased() ? line.capitalized : line
        }
        return nil
    }

    // MARK: - Date

    private nonisolated static func findDate(in lines: [String]) -> Date? {
        let text = lines.joined(separator: "\n")
        guard let date = dayFirstDate(in: text) ?? detectedDate(in: text) else { return nil }
        // A receipt cannot be from the future; allow one day for time zones.
        let latestAllowed = Date().addingTimeInterval(24 * 60 * 60)
        return date > latestAllowed ? nil : date
    }

    /// Sri Lankan receipts print numeric dates day first: 17/10/2026, 17-10-26, 17.10.2026.
    /// Apple's detector would follow the phone's region and could read 05/10 as 10 May.
    private nonisolated static func dayFirstDate(in text: String) -> Date? {
        let pattern = #"(?<![0-9])([0-9]{1,2})[/.-]([0-9]{1,2})[/.-]([0-9]{4}|[0-9]{2})(?![0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }

        let parts = (1...3).compactMap { index -> Int? in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return Int(text[range])
        }
        guard parts.count == 3, (1...31).contains(parts[0]), (1...12).contains(parts[1]) else { return nil }
        let year = parts[2] < 100 ? 2000 + parts[2] : parts[2]
        return Calendar.current.date(from: DateComponents(year: year, month: parts[1], day: parts[0], hour: 12))
    }

    /// For written dates such as "12 Oct 2026", Apple's NSDataDetector already does the work.
    private nonisolated static func detectedDate(in text: String) -> Date? {
        guard !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        else { return nil }
        return detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))?.date
    }
}
