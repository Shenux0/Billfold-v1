// ExpenseFormView.swift
// One form for adding, editing and reviewing a scanned expense.
// It edits a draft copy, so nothing is saved until the user taps Save.

import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ExpenseDraft
    @State private var saveCount = 0
    @State private var showingDeleteConfirm = false

    private let expense: Expense?
    private let onFinish: (() -> Void)?

    /// Pass `expense` to edit it, or a `draft` (for example from a scan) to start a new one.
    init(expense: Expense? = nil, draft: ExpenseDraft = ExpenseDraft(), onFinish: (() -> Void)? = nil) {
        self.expense = expense
        self.onFinish = onFinish
        _draft = State(initialValue: expense.map { ExpenseDraft(expense: $0) } ?? draft)
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $draft.title)
                    .accessibilityIdentifier("titleField")
                TextField("Amount", text: $draft.amountText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("amountField")
                Picker("Currency", selection: $draft.currencyCode) {
                    ForEach(Currency.codes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
            }
            Section("Category") { categoryGrid }
            Section("Notes") {
                TextField("Optional", text: $draft.notes, axis: .vertical)
            }
            if let data = draft.receiptImageData, let image = UIImage(data: data) {
                Section("Receipt") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Receipt photo")
                }
            }
            if expense != nil {
                Section {
                    Button("Delete Expense", role: .destructive) { showingDeleteConfirm = true }
                }
            }
        }
        .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Cancel replaces Back, so leaving is always a clear choice
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!draft.isValid)
                    .accessibilityIdentifier("saveButton")
            }
        }
        .confirmationDialog("Delete this expense?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: deleteExpense)
        }
        .sensoryFeedback(.success, trigger: saveCount)
    }

    /// Adaptive columns: as many badges per row as fit, on any screen size.
    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76))], spacing: 12) {
            ForEach(ExpenseCategory.allCases) { category in
                Button { draft.category = category } label: {
                    VStack(spacing: 6) {
                        CategoryBadge(category: category, isSelected: draft.category == category)
                        Text(category.title)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
                // Plain style stops a Form row from firing every button in it at once.
                .buttonStyle(.plain)
                .accessibilityLabel(category.title)
                .accessibilityAddTraits(draft.category == category ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func save() {
        let target = expense ?? Expense(title: "", amount: 0)
        draft.apply(to: target)
        if expense == nil {
            modelContext.insert(target)
        }
        saveCount += 1
        onFinish?()
        dismiss()
    }

    private func deleteExpense() {
        if let expense {
            modelContext.delete(expense)
        }
        dismiss()
    }
}
