import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    private var version: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                Toggle(L("Auto-translate while typing"), isOn: $store.autoTranslate)

                HStack {
                    Text(L("Auto-translate delay"))
                    Slider(value: $store.autoTranslateDelay, in: 0.2...2.0, step: 0.1)
                    Text(LF("%.1f s", store.autoTranslateDelay))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 46, alignment: .trailing)
                }
                .disabled(!store.autoTranslate)

                Stepper(value: $store.historyLimit, in: 20...1000, step: 20) {
                    Text(LF("Keep at most %ld history entries", store.historyLimit))
                }
            } header: {
                Text(L("General"))
            }

            Section {
                LabeledContent(L("Translation engine")) {
                    Text(L("Apple on-device translation"))
                }
                LabeledContent(L("Works offline")) {
                    Text(L("Yes, after the language pack is downloaded."))
                }
            } header: {
                Text(L("Translation"))
            }

            Section {
                LabeledContent(L("Version")) {
                    Text(version).monospacedDigit()
                }
                LabeledContent(L("Source code")) {
                    Link("GitHub", destination: URL(string: "https://github.com/Lives0808/LingoSwift")!)
                }
                Button(L("Reset Settings and History"), role: .destructive) {
                    store.resetEverything()
                    store.clearHistory()
                }
            } header: {
                Text(L("About"))
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .navigationTitle(L("Settings"))
    }
}
