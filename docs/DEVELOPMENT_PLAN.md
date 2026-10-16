# Billfold: Receipt Scanner and Expense Tracker (iOS): Development Plan

> **For Claude Code.** Read this whole file before writing any code. Follow it exactly. Do not add features that are not listed here.

## 1. What we are building

**Billfold** is an iOS app that tracks spending. The user takes or picks a photo of a receipt, the app **reads it on the device** using Apple's Vision framework, pre-fills the merchant, total, and date, and saves the expense. Charts show where the money goes.

This is **Part A** of university assignment SE4041 (Mobile Application Design and Development), worth 15%. The student must **explain every file in a viva**, so the code has to be simple and readable. This is a **separate repository** from the tvOS app.

### Purpose and target audience (the student must justify these in the report)

- **Problem:** paper receipts pile up, spending is forgotten, and typing every expense by hand is boring, so people stop tracking.
- **Audience:** university students and young professionals in Sri Lanka. They pay by cash and card, get paper receipts from supermarkets, restaurants, and pharmacies, and have tight monthly budgets.
- **Why this design fits them:** scanning removes the typing; everything runs **on the device** (no account, no cloud, private); the interface is quick and uncluttered.

### Non-negotiable rules

1. **Simple beats clever.** No Combine, no generics tricks, no protocol hierarchies, no property-wrapper magic beyond what is listed here.
2. **Every file starts with a 2-3 line comment** saying what the file is for. Comments explain *why*, not *what*.
3. **Keep files short** (about 120 lines max). One main type per file.
4. **No force unwraps (`!`)**, no `try!`. The only allowed `fatalError` is when the SwiftData container cannot be created at launch.
5. **No third-party libraries.** Apple frameworks only: SwiftUI, SwiftData, Vision, PhotosUI, Charts, Foundation, UIKit (for `UIImage` only).
6. **Do NOT create or edit `.xcodeproj` / `.pbxproj` files.** The student creates the Xcode project on a Mac and drops these source files in.
7. **The code cannot be compiled on this machine (Windows).** Use only well-known, stable APIs. If you are not 100% sure an API exists on iOS 17, pick a simpler alternative, or add a `// MAC-CHECK:` comment above the line so it can be found with a search on the Mac.
8. **Mark all service functions `nonisolated`** and run heavy work with `Task.detached`, so the code behaves the same whatever the Xcode default actor-isolation setting is.
9. **Out of scope. Do not build:** accounts or login, cloud sync, networking, budgets or alerts, recurring expenses, export, widgets, localization, onboarding screens, camera capture (only as the optional last phase).

### Target and tooling

- Platform: **iOS 17.0+**, iPhone first, iPad works through adaptive layouts (no separate iPad design)
- Swift 5.9+ (Swift 5 language mode), SwiftUI, **SwiftData** (persistence), **Vision** (on-device text recognition), **PhotosUI** (`PhotosPicker`), **Swift Charts**
- Architecture: **MVVM-lite**
  - **Models:** data types
  - **Services:** pure logic with no UI (parser, stats, OCR). Easiest to unit test and to explain
  - **ViewModels:** only where there is async or multi-step state (the scan flow). Simple screens use `@Query` and `@State`
  - **Views:** SwiftUI only

---

## 2. Design language (Apple minimal)

Goal: it should feel like an Apple app. Calm, spacious, system-native, big readable numbers.

| Element | Rule |
|---|---|
| Layout | Standard iOS: large navigation titles, grouped `List` and `Form`, `TabView` with 3 tabs |
| Typography | System font only, semantic text styles (`.largeTitle`, `.title3`, `.headline`, `.body`, `.caption`). **Never fixed point sizes** (this is what makes Dynamic Type work). Money amounts use `.fontDesign(.rounded)` with `.bold` |
| Color | One accent color (teal-green, defined in `Theme`, with light and dark variants). Category colors are fixed system colors. Backgrounds use system semantic colors so Light and Dark both work |
| Shape | Cards: corner radius **20**, filled with `secondarySystemGroupedBackground`, **no shadow** |
| Icons | SF Symbols only inside the app. A custom **app icon** is made by the student (see section 11) |
| Motion | `.snappy` and soft springs. Numbers roll with `.contentTransition(.numericText())`. Haptic feedback on save |
| Empty states | `ContentUnavailableView` |

### Branding

- App name: **Billfold**
- Accent color: light `#0E9F82`, dark `#2DD4A8`
- Icon: simple receipt glyph on the accent color (student designs it in Figma, exports 1024x1024)

### Theme file (`Theme/Theme.swift`)

```swift
import SwiftUI
import UIKit

enum Theme {
    // Accent color with a light and a dark variant, so we need no asset catalog edits.
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.176, green: 0.831, blue: 0.659, alpha: 1)   // #2DD4A8
            : UIColor(red: 0.055, green: 0.624, blue: 0.510, alpha: 1)   // #0E9F82
    })

    static let cornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16
}
```

`BillfoldApp` applies `.tint(Theme.accent)` to the root view.

---

## 3. Folder structure (standard Xcode layout)

```
billfold-ios/                         <- git repo root
├── README.md
├── docs/
│   ├── DEVELOPMENT_PLAN.md        <- this file
│   ├── AI_USAGE_LOG.md
│   ├── CITATIONS.md
│   └── (later) TECHNICAL_DOCS.md, USER_GUIDE.md, REPORT.md, UAT.md
├── Billfold/                         <- app source (becomes the Xcode target folder)
│   ├── BillfoldApp.swift
│   ├── Models/
│   │   ├── ExpenseCategory.swift
│   │   ├── Expense.swift          (SwiftData model)
│   │   ├── ExpenseDraft.swift
│   │   ├── ParsedReceipt.swift
│   │   └── Period.swift
│   ├── Services/
│   │   ├── ReceiptScanner.swift   (Vision OCR)
│   │   ├── ReceiptParser.swift    (text lines -> merchant/total/date)
│   │   ├── CategoryGuesser.swift
│   │   ├── ExpenseStats.swift
│   │   └── SampleData.swift
│   ├── ViewModels/
│   │   └── ScanViewModel.swift
│   ├── Views/
│   │   ├── RootTabView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── SummaryCard.swift
│   │   ├── Expenses/
│   │   │   ├── ExpenseListView.swift
│   │   │   └── ExpenseFormView.swift
│   │   ├── Scan/
│   │   │   └── ScanView.swift
│   │   ├── Insights/
│   │   │   └── InsightsView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Components/
│   │       ├── CardStyle.swift        (custom ViewModifier)
│   │       ├── CategoryBadge.swift
│   │       ├── ExpenseRow.swift
│   │       └── ScanLineOverlay.swift  (custom animation)
│   ├── Theme/
│   │   └── Theme.swift
│   └── Extensions/
│       ├── UIImage+Resize.swift
│       └── Formatting.swift
├── BillfoldTests/
│   ├── ReceiptParserTests.swift
│   ├── CategoryGuesserTests.swift
│   ├── ExpenseStatsTests.swift
│   ├── ExpenseDraftTests.swift
│   ├── ReceiptScannerTests.swift
│   └── PerformanceTests.swift
└── BillfoldUITests/
    └── BillfoldUITests.swift
```

---

## 4. Data layer

### 4.1 `Models/ExpenseCategory.swift`

```swift
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food, transport, shopping, bills, health, entertainment, other
    var id: String { rawValue }

    var title: String        // "Food", "Transport", ...
    var symbol: String       // SF Symbol, well-known ones only: fork.knife, car.fill, bag.fill,
                             // bolt.fill, cross.case.fill, popcorn.fill, ellipsis.circle.fill
    var color: Color         // food .orange, transport .blue, shopping .pink, bills .purple,
                             // health .red, entertainment .indigo, other .gray
}
```

### 4.2 `Models/Expense.swift` (SwiftData)

```swift
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var categoryRaw: String
    var notes: String
    @Attribute(.externalStorage) var receiptImageData: Data?   // big data is stored outside the database

    // Computed, not stored. Enums are stored as a raw string because that is the safest way in SwiftData.
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(title: String, amount: Double, date: Date = .now,
         category: ExpenseCategory = .other, notes: String = "", receiptImageData: Data? = nil) { ... }
}
```

### 4.3 `Models/ExpenseDraft.swift`

The editable copy of an expense used by the form. Keeps validation out of the view and makes it unit testable.

```swift
struct ExpenseDraft {
    var title = ""
    var amountText = ""
    var date = Date()
    var category: ExpenseCategory = .other
    var notes = ""
    var receiptImageData: Data?

    var amount: Double?     // parses amountText: trims spaces, removes ",", returns nil if not a number
    var isValid: Bool       // title not blank AND amount > 0

    init()
    init(expense: Expense)
    init(parsed: ParsedReceipt, imageData: Data?)   // uses CategoryGuesser on the merchant
    func apply(to expense: Expense)                 // copies fields into a SwiftData object
}
```

### 4.4 `Models/ParsedReceipt.swift`

```swift
struct ParsedReceipt: Equatable {
    var merchant: String?
    var total: Double?
    var date: Date?
}
```

### 4.5 `Models/Period.swift`

```swift
enum Period: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }
    var title: String                         // "Week", "Month", "Year"
    var calendarComponent: Calendar.Component // .weekOfYear, .month, .year
    var chartUnit: Calendar.Component         // .day for week and month, .month for year
}
```

### 4.6 `Services/ReceiptScanner.swift` (Vision OCR)

```swift
import Vision
import UIKit

enum ReceiptScanner {
    enum ScanError: Error { case noImage }

    /// Reads all text lines in the image, top to bottom, fully on the device.
    nonisolated static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { throw ScanError.noImage }
        // Vision is synchronous and heavy, so run it off the main thread.
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let observations = request.results ?? []
            return observations.compactMap { $0.topCandidates(1).first?.string }
        }.value
    }
}
```

Image orientation note: `UIImage+Resize` redraws the image with `UIGraphicsImageRenderer`, which **bakes the orientation into the pixels**. After that, Vision can read portrait phone photos correctly with no orientation handling. Always resize before OCR.

### 4.7 `Services/ReceiptParser.swift` (pure logic)

```swift
enum ReceiptParser {
    nonisolated static func parse(lines: [String]) -> ParsedReceipt
}
```

Rules, in this order:

1. **Amounts:** an amount is text matching `[0-9]{1,3}(,[0-9]{3})*\.[0-9]{2}` or `[0-9]+\.[0-9]{2}` (must have two decimals, so phone numbers and dates are not mistaken for money). Remove commas, convert to `Double`. Use `NSRegularExpression`. Assume "." is the decimal separator (a limitation to mention in the report).
2. **Total:** a *candidate line* contains (case-insensitive) `total`, `amount due`, or `balance due`, and does **not** contain `sub`. Take the last amount on that line; if the line has none, use the first amount on the **next** line (OCR often splits label and number). Among all candidates, pick the **largest**. If there are no candidates, fall back to the largest amount anywhere on the receipt.
3. **Merchant:** the first line among the first 5 that has at least 3 letters, is not mostly digits, and does not contain `receipt`, `invoice`, `tel`, `phone`, `date`, or `www`. Trim it. If it is ALL CAPS, convert with `.capitalized`.
4. **Date:** run `NSDataDetector` (date type) over all lines joined with newlines, take the first date found. Ignore it if it is more than one day in the future.
5. Anything not found stays `nil`. The parser never crashes on empty input.

### 4.8 `Services/CategoryGuesser.swift`

A small keyword table, nothing more.

```swift
enum CategoryGuesser {
    nonisolated static func guess(from merchant: String?) -> ExpenseCategory
}
```

Lowercase the merchant and return the first category whose keyword it contains, otherwise `.other`:
- food: `restaurant`, `cafe`, `coffee`, `bakery`, `pizza`, `burger`, `keells`, `cargills`, `arpico`, `supermarket`, `grocery`
- transport: `uber`, `pickme`, `fuel`, `petrol`, `diesel`, `taxi`, `bus`, `ceypetco`
- health: `pharmacy`, `hospital`, `clinic`, `medical`
- bills: `dialog`, `mobitel`, `slt`, `electricity`, `water board`, `internet`
- shopping: `odel`, `mall`, `store`, `fashion`, `books`
- entertainment: `cinema`, `movie`, `games`, `theatre`

### 4.9 `Services/ExpenseStats.swift` (pure logic)

```swift
struct CategoryTotal: Identifiable {
    let category: ExpenseCategory
    let total: Double
    var id: String { category.id }
}

enum ExpenseStats {
    /// Expenses whose date falls in the same week/month/year as `date`.
    nonisolated static func expenses(_ all: [Expense], in period: Period,
                                     containing date: Date, calendar: Calendar = .current) -> [Expense]
    nonisolated static func total(of expenses: [Expense]) -> Double
    /// Totals per category, biggest first, categories with 0 left out.
    nonisolated static func totalsByCategory(_ expenses: [Expense]) -> [CategoryTotal]
}
```

Use `calendar.dateInterval(of: period.calendarComponent, for: date)` and test `interval.contains(expense.date)`.

### 4.10 `Services/SampleData.swift`

`static func insert(into context: ModelContext)` adds about 25 expenses across the last 60 days and all categories. Use a **fixed array of tuples** (title, amount, daysAgo, category), not random numbers, so screenshots and tests are repeatable. Used by Settings ("Load Sample Data") and by UI tests.

### 4.11 `Extensions/`

- `UIImage+Resize.swift`: `func resized(maxDimension: CGFloat) -> UIImage` (keeps aspect ratio, redraws with `UIGraphicsImageRenderer`, never upscales) and `func compressedData() -> Data?` (`jpegData(compressionQuality: 0.6)`).
- `Formatting.swift`: `extension Double { func asCurrency(code: String) -> String }` using `self.formatted(.currency(code: code))`.

---

## 5. App entry and persistence (`BillfoldApp.swift`)

```swift
@main
struct BillfoldApp: App {
    let container: ModelContainer

    init() {
        let inMemory = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: Expense.self, configurations: config)
        } catch {
            fatalError("Could not create the data store: \(error)")
        }
        if inMemory { SampleData.insert(into: container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView().tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
```

When the app is launched with `UI_TESTING`, it uses a throwaway in-memory store filled with sample data, so UI tests are always the same.

Currency is stored with `@AppStorage("currencyCode")` (default `"LKR"`), declared in each view that shows money.

---

## 6. Screens and navigation

Navigation: `TabView` with 3 tabs, each tab has its own `NavigationStack`. Adding and scanning open as **sheets**, each with its own `NavigationStack`. Settings is a sheet opened from the Home toolbar.

### 6.1 `RootTabView`
Tabs: **Home** (`house.fill`), **Expenses** (`list.bullet`), **Insights** (`chart.pie.fill`).

### 6.2 `HomeView` and `SummaryCard`
- Large title **"Billfold"**. Toolbar: gear (opens `SettingsView` sheet), plus (opens an empty `ExpenseFormView` sheet).
- **SummaryCard** (card style): month name with chevron buttons, the month total as a big number, `"{n} expenses"` caption, `"Top: {category}"` caption.
  - The total uses `.contentTransition(.numericText())` and `.animation(.snappy, value: total)`.
  - **Gesture:** a `DragGesture(minimumDistance: 30)` on the card. If the drag is mostly **horizontal** (`abs(width) > abs(height)`) and passes 50 points, swipe left shows the next month, swipe right the previous one. Month changes use an asymmetric slide transition. The chevron buttons do the same thing, so users who cannot swipe (VoiceOver) are covered.
- **Recent** section: last 5 expenses as `ExpenseRow`, and a "See All" `NavigationLink` to `ExpenseListView`.
- Bottom: a large prominent button **"Scan Receipt"** (`doc.text.viewfinder`) pinned with `.safeAreaInset(edge: .bottom)`. Opens `ScanView` in a sheet.
- **Adaptive layout:** read `@Environment(\.horizontalSizeClass)`. Compact width: summary on top, recent below (`VStack`). Regular width (iPad): side by side (`HStack`).
- Empty state when there are no expenses at all: `ContentUnavailableView` with a hint to scan the first receipt.
- Identifiers: `scanReceiptButton`, `addExpenseButton`, `settingsButton`, `monthTotalText`.

### 6.3 `ExpenseListView`
- `@Query(sort: \Expense.date, order: .reverse)` for all expenses; filter **in memory** with a computed property (the data is small, and this avoids dynamic predicates).
- `.searchable(text:)` on title. Toolbar `Menu` to filter by category ("All" plus each category).
- Rows are `ExpenseRow`. Tap pushes `ExpenseFormView` in edit mode. `.swipeActions` for **Delete** (destructive).
- Long-press `.contextMenu` with Edit and Delete.
- Empty state: `ContentUnavailableView`. Search with no result: `ContentUnavailableView.search`.
- Identifiers: `expenseList`, `expenseRow`.

### 6.4 `ExpenseFormView` (add, edit, and scan prefill)

```swift
struct ExpenseFormView: View {
    init(expense: Expense? = nil, draft: ExpenseDraft = ExpenseDraft(), onFinish: (() -> Void)? = nil)
}
```
- `@State private var draft: ExpenseDraft`, initialised from the `expense` if editing, otherwise from `draft`.
- `Form` sections: **Details** (title `TextField`, amount `TextField` with `.keyboardType(.decimalPad)`, `DatePicker`), **Category** (adaptive `LazyVGrid` of `CategoryBadge` buttons; the selected one scales up with a spring), **Notes**, and **Receipt** (thumbnail, only if there is an image).
- Toolbar: Cancel and **Save** (disabled unless `draft.isValid`). Edit mode also has a Delete button with a `.confirmationDialog`.
- On save: create or update the `Expense`, insert into `modelContext`, fire `.sensoryFeedback(.success, trigger: saveCount)`, call `onFinish`, then `dismiss()`.
- Identifiers: `titleField`, `amountField`, `saveButton`.

### 6.5 `ScanView` and `ScanViewModel`

```swift
enum ScanState { case idle, processing, result(ParsedReceipt), failed(String) }

@MainActor @Observable
final class ScanViewModel {
    private(set) var state: ScanState = .idle
    private(set) var image: UIImage?
    private(set) var imageData: Data?

    func load(_ item: PhotosPickerItem?) async   // loadTransferable(type: Data.self) -> UIImage -> process
    func process(_ image: UIImage) async         // resize (max 1600 px) -> OCR -> parse -> state = .result / .failed
    func reset()
    var draft: ExpenseDraft?                      // built from the .result state
}
```

`ScanView` shows a different layout per state:
- **idle:** large `doc.text.viewfinder` symbol, short explanation ("Your receipt is read on your device and never uploaded."), `PhotosPicker` button **"Choose Receipt Photo"** (`matching: .images`).
- **processing:** the image with `ScanLineOverlay` moving over it, caption "Reading receipt…".
- **result:** small image, a card listing **Merchant / Total / Date** (a missing value shows "Not found" in `.secondary`), and a prominent **"Review & Save"** `NavigationLink` that pushes `ExpenseFormView(draft:, onFinish:)`. `onFinish` dismisses the whole sheet. Result card appears with `.transition(.move(edge: .bottom).combined(with: .opacity))`.
- **failed:** message, **"Try Another Photo"**, and **"Enter Manually"**.
- `PhotosPicker` needs no photo-library permission string (it runs outside the app), which is worth mentioning in the viva.
- Identifiers: `choosePhotoButton`, `reviewSaveButton`.

### 6.6 `InsightsView`
- Segmented `Picker` for `Period` (Week / Month / Year), bound with `@State`.
- **Donut chart:** `SectorMark(angle:, innerRadius: .ratio(0.62), angularInset: 2)` per `CategoryTotal`, colored by category, with the period total in the centre (overlay).
- **Category list** under it: badge, name, amount, percentage.
- **Bar chart:** one `BarMark(x: .value("Date", expense.date, unit: period.chartUnit), y: .value("Amount", expense.amount))` per expense (Charts stacks and sums them per day or month).
- Empty period: `ContentUnavailableView`.
- Wrap charts so they have a fixed height (about 220) and `.accessibilityLabel` summaries.

### 6.7 `SettingsView`
`Form` in a sheet with a Done button:
- **Currency** `Picker` (LKR, USD, EUR, GBP, INR, AUD) bound to `@AppStorage("currencyCode")`
- **Load Sample Data** button (calls `SampleData.insert`)
- **Delete All Expenses** (destructive, with confirmation; uses `modelContext.delete(model: Expense.self)`)
- Footer: app name and version
- Identifiers: `loadSampleDataButton`

---

## 7. Shared components (`Views/Components/`)

### `CardStyle.swift` (the custom ViewModifier to show in the viva)

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}
```

### `CategoryBadge.swift`
Rounded square (about 40 pt using `@ScaledMetric` so it grows with Dynamic Type) filled with the category color at 20% opacity, with the category SF Symbol in the full color. Optional `isSelected` state draws a ring and scales to 1.1 with a spring.

### `ExpenseRow.swift`
`HStack`: `CategoryBadge`, title (`.headline`) with date (`.caption`, `.secondary`) underneath, amount on the right (`.fontDesign(.rounded)`). Use `.accessibilityElement(children: .combine)` so VoiceOver reads one sentence per row.

### `ScanLineOverlay.swift` (custom animation)
A thin horizontal capsule with a vertical gradient (accent to clear) that moves from the top to the bottom of the image and back, forever, using `withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true))` triggered in `.onAppear`. Position it with `GeometryReader`.

---

## 8. Accessibility checklist (rubric item: Dark Mode and Dynamic Type)

- Only semantic fonts, no `.system(size:)`. Icon sizes use `@ScaledMetric`.
- Big amounts: `.lineLimit(1)` and `.minimumScaleFactor(0.5)`.
- Layouts must survive the largest Accessibility sizes; use `ViewThatFits` or wrap rows if text overflows.
- Only semantic colors and `Theme` colors, so Dark Mode works everywhere. Never hard-code `.white` or `.black` for backgrounds.
- Every icon-only button has `.accessibilityLabel`. Charts have `.accessibilityLabel` summaries.
- The swipe gesture has a button alternative (see 6.2).
- Animations are kept short and gentle (respect `accessibilityReduceMotion` for the scan line if time allows).

---

## 9. Build order

Work in phases. **After each phase, make one git commit** with a clear message. Use a branch per phase when practical (`feature/models`, `feature/ocr`, `feature/ui`).

| Phase | Work | Commit message example |
|---|---|---|
| 0 | Folder structure, `README.md` stub, `docs/AI_USAGE_LOG.md`, `docs/CITATIONS.md`, Xcode `.gitignore` (`xcuserdata/`, `DerivedData/`, `.DS_Store`) | `chore: scaffold project structure` |
| 1 | `ExpenseCategory`, `Expense`, `ExpenseDraft`, `Period`, `ParsedReceipt`, `Formatting`, `ExpenseStats`, `CategoryGuesser`, with their tests | `feat: add models and stats logic with tests` |
| 2 | `ReceiptParser` and `ReceiptParserTests` | `feat: add receipt parser with tests` |
| 3 | `UIImage+Resize`, `ReceiptScanner`, `ReceiptScannerTests` | `feat: add on-device text recognition` |
| 4 | `Theme`, `CardStyle`, `CategoryBadge`, `ExpenseRow`, `ScanLineOverlay` | `feat: add theme and shared components` |
| 5 | `BillfoldApp`, `RootTabView`, `HomeView`, `SummaryCard`, `ExpenseListView`, `ExpenseFormView`, `SampleData` | `feat: add home, list and expense form` |
| 6 | `ScanViewModel`, `ScanView` | `feat: add receipt scanning flow` |
| 7 | `InsightsView`, `SettingsView` | `feat: add insights and settings` |
| 8 | UI tests, performance tests, README, comment pass over every file | `docs: tests, readme and comments` |
| 9 | **Optional, only after everything works on the Mac:** camera capture (small `UIViewControllerRepresentable` around `UIImagePickerController`, shown only if `UIImagePickerController.isSourceTypeAvailable(.camera)`, needs `NSCameraUsageDescription`) | `feat: add camera capture` |

After each phase, add an entry to `docs/AI_USAGE_LOG.md`:
`Date | Tool (Claude Code) | What the student asked | What was generated | What the student changed or checked`.
Never invent entries. Leave the "what the student changed" column for the student to fill in.

---

## 10. Tests

Test files are written now and are **added as targets and run on the Mac**.

**Unit tests (`BillfoldTests/`)**
- `ReceiptParserTests`: finds `TOTAL 1,250.00`; ignores `SUBTOTAL`; total on the line after the label; falls back to the largest amount; ignores numbers without decimals (phone numbers); merchant is the first sensible line; ALL CAPS merchant is converted; date found with an unambiguous format such as `12 Oct 2026`; empty input returns all `nil`.
- `CategoryGuesserTests`: a few merchants map to the right categories; unknown and `nil` map to `.other`.
- `ExpenseStatsTests`: period filtering for week, month, year; totals; totals by category sorted and without zeros.
- `ExpenseDraftTests`: amount parsing (`"1,250.50"`, `" 99 "`, `"abc"` gives nil); `isValid` rules; `init(parsed:imageData:)` fills the fields and category.
- `ReceiptScannerTests`: render lines such as "BILLFOLD CAFE" and "TOTAL 450.00" into a `UIImage` with `UIGraphicsImageRenderer`, run `ReceiptScanner.recognizeText`, and check the text contains `TOTAL`. If Vision is unavailable in the simulator, `throw XCTSkip`.
- `PerformanceTests`: `measure(metrics: [XCTClockMetric(), XCTMemoryMetric()])` around `ReceiptParser.parse` on a large array of lines, and around `ExpenseStats` on 5,000 generated expenses. The numbers go into the report.

**UI tests (`BillfoldUITests/`)**, all launched with `app.launchArguments = ["UI_TESTING"]`:
- Add an expense by hand: tap `addExpenseButton`, type title and amount, tap `saveButton`, then check the row appears in the Expenses tab.
- Delete an expense with a swipe.
- Open Settings, change currency, and check the Home total text changes.
- A launch performance test with `XCTApplicationLaunchMetric`.

---

## 11. Documentation and assets (the student does the human parts)

- `README.md`: what the app is, requirements (Xcode 15+, iOS 17 simulator), how to build and run, how to add a test receipt to the simulator (drag the image onto the simulator window), folder overview, third-party credits (none), AI tool note.
- `docs/CITATIONS.md`: Apple frameworks used (SwiftUI, SwiftData, Vision, PhotosUI, Charts) and any other resource. Note that merchant keywords are common knowledge.
- `docs/TECHNICAL_DOCS.md` (Claude Code can draft this at the end): architecture diagram, data model, how the OCR and parser work, the parser rules, folder map.
- `docs/USER_GUIDE.md`: how to scan, add, edit, view insights, change currency, with screenshots (student takes them).
- `docs/UAT.md`: user acceptance testing. 5 testers, 5 tasks (scan a receipt, add an expense, find last week's spending, change currency, delete an expense), a results table (pass or fail, time taken, comments), and what was changed afterwards.
- `docs/REPORT.md` outline (the student writes the reflections): purpose and audience, similar apps (Money Manager, Wallet, Expensify, Apple Wallet receipts: the student verifies each), design decisions (minimal Apple style, on-device privacy, MVVM-lite), development challenges (OCR accuracy, orientation, parsing messy receipts), testing results (unit, UI, performance, UAT), Instruments screenshots (Time Profiler, Allocations, Leaks), reflections.
- **App icon:** the student designs a 1024x1024 icon in Figma and sets it in `Assets.xcassets > AppIcon`.
- **Test receipts:** the student photographs about 5 real receipts (cover or crop personal details) and keeps them out of the repo.

---

## 12. Performance notes (rubric item: Testing and Optimization)

These are the optimisations to implement and describe in the report:
1. Resize the photo to at most 1600 px before OCR (less memory, faster Vision).
2. OCR runs on a background task, never on the main thread.
3. Receipt images are stored with `.externalStorage` and compressed to JPEG quality 0.6.
4. `List` and `LazyVGrid` render rows lazily.
5. Expensive stats are computed from a small filtered array, not recomputed in nested views.

---

## 13. Mac session checklist (for the student, not for Claude Code)

1. Install Xcode (start the download early). Check the macOS version supports it.
2. Xcode > New Project > **iOS > App**. Product Name **Billfold**, Interface **SwiftUI**, Language **Swift**, Storage **None**, tick "Include Tests". Devices: iPhone and iPad. Save it in a **new empty folder**, not inside the repo.
3. Set **Minimum Deployments = iOS 17.0**.
4. In the new project delete the template `ContentView.swift`, `BillfoldApp.swift` and any `Item.swift`.
5. Copy our `Billfold/` source folders (Models, Services, ViewModels, Views, Theme, Extensions, `BillfoldApp.swift`) into the project's `Billfold/` folder. If Xcode does not pick them up automatically, drag them into the project navigator with "Create groups" and the app target ticked.
6. Replace the template test files with ours in `BillfoldTests/` and `BillfoldUITests/`.
7. Build (Cmd+B). Search the project for `MAC-CHECK` first. Fix errors in batches. If you see actor-isolation errors, try Build Settings > **Default Actor Isolation** and set it to the other value.
8. Run on an iPhone simulator. Drag a receipt photo onto the simulator window to put it in Photos, then test scanning.
9. Check **Dark Mode** (Cmd+Shift+A in the simulator), **Dynamic Type** (Xcode's Environment Overrides button while running, or Settings > Accessibility in the simulator), and **rotation** and an **iPad simulator**.
10. Run all tests (Cmd+U). Run Instruments (Product > Profile) with Time Profiler, Allocations, and Leaks while scanning, and save screenshots for the report.
11. Copy the generated `Billfold.xcodeproj` and updated files back into the git repo, commit, push.

---

## 14. Rubric map (where each mark is earned)

| Rubric item | Where it is covered |
|---|---|
| App Functionality (15) | Full flow: scan, review, save, list, edit, delete, insights, settings. Sample data for demos |
| Advanced UI and UX (15) | Swipe-to-change-month gesture, scan line animation, numeric text transitions, slide and fade transitions, donut and bar charts, adaptive layouts (size class and adaptive grids), haptics |
| Code Quality and Architecture (15) | MVVM-lite, pure testable services, short documented files, custom `ViewModifier` |
| Emerging Technologies (15) | Vision on-device text recognition driving the core feature, plus the parser and category guesser built on top |
| Testing and Optimization (10) | Unit, UI, performance and memory tests, UAT, Instruments results, the optimisations in section 12 |
| Documentation and Reporting (10) | README, technical docs, user guide, report, AI usage log, citations |
| Innovation and Creativity (10) | Private, on-device receipt reading with automatic category guessing, built for the local market |
| Presentation and Deployment Readiness (10) | Sample data button for a clean live demo, rehearsed demo script, icon and branding done |

## 15. Definition of done

- App builds and runs on an iPhone simulator, and also looks right on iPad.
- Scanning a receipt photo fills the form; saving shows the expense on Home, the list, and Insights.
- Works in Light and Dark Mode and at the largest Dynamic Type sizes.
- Unit tests, UI tests, and performance tests pass.
- Every file has a header comment and the student can explain it.
- README, technical docs, user guide, UAT, report, AI usage log, and citations are complete.
