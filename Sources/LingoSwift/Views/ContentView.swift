import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            HistorySidebar()
                .navigationSplitViewColumnWidth(min: 210, ideal: 250, max: 340)
        } detail: {
            TranslatorView()
        }
        .translationTask(store.configuration) { session in
            await store.translate(using: session)
        }
        .onChange(of: store.sourceText) {
            store.sourceTextDidChange()
        }
        .onChange(of: store.sourceLanguage) {
            Task { await store.refreshLanguagePackStatus() }
        }
        .onChange(of: store.targetLanguage) {
            Task { await store.refreshLanguagePackStatus() }
        }
        .task {
            await store.refreshLanguagePackStatus()
        }
    }
}
