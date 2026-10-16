# Billfold

**Receipt scanner and expense tracker for iOS.** Take a photo of a paper receipt and Billfold reads it on your device. It fills in the merchant, total and date, guesses a category, and saves the expense. Charts show where your money goes.

Built for SE4041 Mobile Application Design and Development (Part A).

## Features

- **Scan a receipt** from your photo library. Text is read on the device with Apple's Vision framework, and the photo is never uploaded.
- **Automatic pre-fill:** merchant, total, date and a guessed category, all editable before saving.
- **Add, edit and delete** expenses by hand. Swipe or long-press a row to delete it.
- **Home summary** for each month. Swipe the card, or use the arrows, to move between months.
- **Insights:** a donut chart by category and a bar chart over time, for this week, month or year.
- **Search and filter** the expense list by title and category.
- **Settings:** currency (LKR, USD, EUR, GBP, INR, AUD), load sample data, delete all expenses.
- Works in Light and Dark Mode and with large Dynamic Type sizes, with adaptive layouts on iPad.

## Requirements

- A Mac with **Xcode 15 or later**
- **iOS 17.0+** (simulator or device)
- No third-party libraries and no network access

## Build and run

The repository holds the source files. The Xcode project is created on a Mac:

1. In Xcode, choose **File > New > Project > iOS > App**. Set Product Name to **Billfold**, Interface to **SwiftUI**, Language to **Swift** and Storage to **None**, and tick **Include Tests**.
2. Set **Minimum Deployments** to **iOS 17.0**.
3. Delete the template `ContentView.swift`, `BillfoldApp.swift` and any `Item.swift`.
4. Copy the folders in `Billfold/` (Models, Services, ViewModels, Views, Theme, Extensions) and `BillfoldApp.swift` into the project's `Billfold` group, with the app target ticked.
5. Replace the template test files with the files in `BillfoldTests/` and `BillfoldUITests/`.
6. Search the project for `MAC-CHECK` and review those lines.
7. **Actor isolation:** if the build shows many "main actor-isolated" errors (new projects in Xcode 26 default to MainActor), go to **Build Settings > Default Actor Isolation** and set it to **nonisolated**.
8. Build with **Cmd+B**, then run on an iPhone simulator with **Cmd+R**.

### Adding a test receipt to the simulator

Drag a receipt photo from Finder onto the simulator window. It is saved to the Photos app, and you can then pick it from **Scan Receipt > Choose Receipt Photo**.

### Demo data

**Settings > Load Sample Data** adds 25 example expenses across the last 60 days, so every screen has something to show.

## Tests

Run all tests with **Cmd+U**.

| Test file | What it covers |
|---|---|
| `ReceiptParserTests` | Total, subtotal, split lines, fallback amount, phone numbers, merchant and date rules |
| `CategoryGuesserTests` | Merchant keyword to category mapping |
| `ExpenseStatsTests` | Week, month and year filtering, totals, totals by category |
| `ExpenseDraftTests` | Amount parsing, validation, building a draft from a scan |
| `ReceiptScannerTests` | Vision reading a rendered receipt image, plus image resizing |
| `PerformanceTests` | Time and memory for the parser and for stats over 5,000 expenses |
| `BillfoldUITests` | Add an expense, swipe to delete, change currency, launch time |

UI tests launch the app with the `UI_TESTING` argument, which uses a temporary in-memory store filled with sample data.

## Folder overview

```
Billfold/
├── BillfoldApp.swift      App entry, SwiftData container
├── Models/                Expense (SwiftData), ExpenseCategory, ExpenseDraft, ParsedReceipt, Period
├── Services/              ReceiptScanner (Vision), ReceiptParser, CategoryGuesser, ExpenseStats, SampleData
├── ViewModels/            ScanViewModel (the multi-step scan flow)
├── Views/                 Home, Expenses, Scan, Insights, Settings, shared Components
├── Theme/                 Accent color and card measurements
└── Extensions/            Image resizing, currency formatting
BillfoldTests/             Unit and performance tests
BillfoldUITests/           UI tests
docs/                      Development plan, AI usage log, citations
```

**Architecture:** MVVM-lite. Services hold pure logic with no UI, so they are easy to test. Only the scan flow has a view model, because it is the only screen with async, multi-step state. Simple screens read data directly with `@Query`.

## Known limitations

- The parser assumes "." is the decimal separator (for example `1,250.00`).
- Category guessing uses a small keyword list, and the user can always change the category.
- OCR accuracy depends on the photo: crumpled, faded or dark receipts may need manual corrections.

## Credits

- Third-party libraries: **none**. Only Apple frameworks are used (see [docs/CITATIONS.md](docs/CITATIONS.md)).
- AI assistance (Claude Code) is recorded in [docs/AI_USAGE_LOG.md](docs/AI_USAGE_LOG.md).
