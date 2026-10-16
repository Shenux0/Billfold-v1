// ScanView.swift
// The scan sheet. Shows one layout per scan state: pick a photo, reading,
// what was found, or what went wrong. PhotosPicker needs no permission prompt.

import SwiftUI
import PhotosUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currencyCode") private var currencyCode = "LKR"
    @ScaledMetric private var iconSize: CGFloat = 72

    @State private var viewModel = ScanViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingManualForm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    content
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await viewModel.load(newItem) }
            }
            .animation(.snappy, value: viewModel.state)
            .navigationDestination(isPresented: $showingManualForm) {
                ExpenseFormView(draft: manualDraft, onFinish: { dismiss() })
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            message(symbol: "doc.text.viewfinder", title: "Scan a Receipt",
                    text: "Your receipt is read on your device and never uploaded.")
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose Receipt Photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("choosePhotoButton")

        case .processing:
            receiptImage(maxHeight: 420, scanning: true)
            Text("Reading receipt…").font(.headline).foregroundStyle(.secondary)

        case .result(let parsed):
            receiptImage(maxHeight: 200, scanning: false)
            resultCard(parsed)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            NavigationLink {
                ExpenseFormView(draft: viewModel.draft ?? ExpenseDraft(), onFinish: { dismiss() })
            } label: {
                Label("Review & Save", systemImage: "checkmark.circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("reviewSaveButton")

        case .failed(let text):
            message(symbol: "exclamationmark.triangle", title: "Couldn't Read Receipt", text: text)
            Button("Try Another Photo") {
                pickerItem = nil // so picking the same photo again still counts as a change
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button("Enter Manually") { showingManualForm = true }
                .buttonStyle(.bordered)
                .controlSize(.large)
        }
    }

    /// A manual entry still keeps the photo, if there is one.
    private var manualDraft: ExpenseDraft {
        var draft = ExpenseDraft()
        draft.receiptImageData = viewModel.imageData
        return draft
    }

    private func message(symbol: String, title: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title).font(.title2).bold()
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }

    @ViewBuilder
    private func receiptImage(maxHeight: CGFloat, scanning: Bool) -> some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: maxHeight)
                .overlay { if scanning { ScanLineOverlay() } }
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .accessibilityLabel("Receipt photo")
        } else {
            ProgressView().padding(40)
        }
    }

    private func resultCard(_ parsed: ParsedReceipt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found on Receipt").font(.headline)
            resultRow("Merchant", value: parsed.merchant)
            resultRow("Total", value: parsed.total?.asCurrency(code: currencyCode))
            resultRow("Date", value: parsed.date?.formatted(date: .abbreviated, time: .omitted))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func resultRow(_ label: String, value: String?) -> some View {
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
