import AppKit
import SwiftUI

struct HistorySidebar: View {
    @EnvironmentObject private var store: AppStore
    @State private var selection: UUID?
    @State private var query = ""

    private var filteredHistory: [HistoryRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return store.history }
        return store.history.filter {
            $0.sourceText.localizedCaseInsensitiveContains(trimmed)
                || $0.translatedText.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        Group {
            if store.history.isEmpty {
                ContentUnavailableView {
                    Label(L("No History Yet"), systemImage: "clock.arrow.circlepath")
                } description: {
                    Text(L("Translations you make will show up here."))
                }
            } else if filteredHistory.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(selection: $selection) {
                    ForEach(filteredHistory) { record in
                        HistoryRow(record: record)
                            .tag(record.id)
                            .contextMenu {
                                Button(L("Copy Translation")) { copy(record) }
                                Button(L("Delete"), role: .destructive) { store.deleteHistory(record) }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle(L("History"))
        .searchable(text: $query, placement: .sidebar, prompt: L("Search history"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    store.clearHistory()
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(store.history.isEmpty)
                .help(L("Clear History"))
            }
        }
        .onChange(of: selection) { _, newValue in
            guard let id = newValue, let record = store.history.first(where: { $0.id == id }) else { return }
            store.loadIntoEditor(record)
        }
        .onChange(of: store.history) { _, newValue in
            if let id = selection, !newValue.contains(where: { $0.id == id }) {
                selection = nil
            }
        }
    }

    private func copy(_ record: HistoryRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.translatedText, forType: .string)
    }
}

private struct HistoryRow: View {
    let record: HistoryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(record.sourceText)
                .font(.callout)
                .lineLimit(2)
            Text(record.translatedText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text("\(record.sourceLanguage.nativeName) → \(record.targetLanguage.nativeName)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(record.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 1)
        }
        .padding(.vertical, 3)
    }
}
