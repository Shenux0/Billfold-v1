// SettingsView.swift
// The settings sheet: pick a currency, load demo data, or delete everything.
// The currency is saved with @AppStorage, so every screen updates at once.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") private var currencyCode = "LKR"
    @State private var showingDeleteConfirm = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(Currency.codes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Main Currency")
                } footer: {
                    Text("Used for new expenses and for totals and charts. Receipts showing another currency, such as $, are saved in that currency.")
                }

                Section {
                    Button("Load Sample Data") {
                        SampleData.insert(into: modelContext)
                    }
                    .accessibilityIdentifier("loadSampleDataButton")
                    Button("Delete All Expenses", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                } header: {
                    Text("Data")
                } footer: {
                    VStack(spacing: 4) {
                        Text("Sample data adds 25 example expenses for trying out the app.")
                        Text("Billfold \(version)")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete all expenses?", isPresented: $showingDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete All", role: .destructive, action: deleteAll)
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private func deleteAll() {
        // MAC-CHECK: if the lists do not empty straight away, delete each expense in a loop instead.
        try? modelContext.delete(model: Expense.self)
        try? modelContext.save()
    }
}
