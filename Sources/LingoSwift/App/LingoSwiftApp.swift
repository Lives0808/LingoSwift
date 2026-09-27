import SwiftUI

@available(macOS 15.0, *)
struct LingoSwiftApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        Window(L("LingoSwift"), id: "main") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 780, minHeight: 500)
        }
        .defaultSize(width: 1000, height: 640)
        .commands { LingoSwiftCommands(store: store) }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

struct LingoSwiftCommands: Commands {
    @ObservedObject var store: AppStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu(L("Translation")) {
            Button(L("Translate")) { store.requestTranslation() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(store.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button(L("Swap Languages")) { store.swapLanguages() }
                .keyboardShortcut("s", modifiers: [.command, .shift])

            Button(L("Copy Translation")) { store.copyTranslation() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(store.targetText.isEmpty)

            Divider()

            Button(L("Clear")) { store.clear() }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(store.sourceText.isEmpty && store.targetText.isEmpty)
        }

        CommandGroup(replacing: .help) {
            Link(L("LingoSwift on GitHub"), destination: URL(string: "https://github.com/Lives0808/LingoSwift")!)
        }
    }
}
