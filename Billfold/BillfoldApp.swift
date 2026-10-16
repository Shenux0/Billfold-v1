// BillfoldApp.swift
// The app's starting point. Creates the SwiftData store and shows the tabs.
// UI tests launch with "UI_TESTING" to get a fresh in-memory store full of sample data.

import SwiftUI
import SwiftData

@main
struct BillfoldApp: App {
    let container: ModelContainer

    init() {
        let inMemory = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: Expense.self, configurations: config)
        } catch {
            // Without a data store the app cannot work at all, so stopping is the only option.
            fatalError("Could not create the data store: \(error)")
        }
        if inMemory {
            SampleData.insert(into: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
