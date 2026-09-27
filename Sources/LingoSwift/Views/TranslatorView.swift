import SwiftUI

struct TranslatorView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            LanguageBar()
            Divider()
            HStack(spacing: 0) {
                SourcePane()
                Divider()
                TranslationPane()
            }
            Divider()
            BottomBar()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Language bar

private struct LanguageBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 10) {
            Picker(L("Source Language"), selection: $store.sourceLanguage) {
                Text(L("Detect Language")).tag(AppLanguage?.none)
                Divider()
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(AppLanguage?.some(language))
                }
            }
            .labelsHidden()
            .frame(maxWidth: 190)

            Button(action: store.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
            }
            .buttonStyle(.borderless)
            .help(L("Swap Languages"))
            .accessibilityLabel(L("Swap Languages"))

            Picker(L("Target Language"), selection: $store.targetLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 190)

            Spacer()

            LanguagePackBadge()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct LanguagePackBadge: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if let status = store.languagePackStatus, store.sourceLanguage != nil || !store.sourceText.isEmpty {
            switch status {
            case .installed:
                Label(L("Language pack ready"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
            case .supported:
                Label(L("Language pack needed"), systemImage: "arrow.down.circle")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .help(L("Start a translation and follow the system prompt to download the language pack once."))
            default:
                Label(L("Language pair not supported"), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }
}

// MARK: - Panes

private struct SourcePane: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TextPaneCard(title: L("Source"), subtitle: detectedSubtitle) {
            ZStack(alignment: .topLeading) {
                if store.sourceText.isEmpty {
                    Text(L("Enter or paste the text to translate…"))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $store.sourceText)
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -5)
            }
        } headerActions: {
            Text(LF("%ld characters", store.sourceText.count))
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button(action: store.speakSourceText) {
                Image(systemName: "speaker.wave.2")
            }
            .disabled(store.sourceText.isEmpty)
            .help(L("Speak"))

            Button(action: store.clear) {
                Image(systemName: "xmark.circle")
            }
            .disabled(store.sourceText.isEmpty && store.targetText.isEmpty)
            .help(L("Clear"))
        } footer: {
            EmptyView()
        }
    }

    private var detectedSubtitle: String? {
        guard store.sourceLanguage == nil, let detected = store.detectedLanguage,
              !store.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return LF("Detected: %@", detected.nativeName)
    }
}

private struct TranslationPane: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TextPaneCard(title: L("Translation"), subtitle: nil) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if store.targetText.isEmpty {
                        Text(store.isTranslating ? L("Translating…") : L("The translation appears here."))
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(store.targetText)
                            .font(.system(size: 15))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
        } headerActions: {
            if store.isTranslating {
                ProgressView()
                    .controlSize(.small)
            }

            Button(action: store.copyTranslation) {
                Label(
                    store.didCopyTranslation ? L("Copied") : L("Copy"),
                    systemImage: store.didCopyTranslation ? "checkmark" : "doc.on.doc"
                )
                .labelStyle(.titleAndIcon)
            }
            .disabled(store.targetText.isEmpty)

            Button(action: store.speakTranslation) {
                Image(systemName: "speaker.wave.2")
            }
            .disabled(store.targetText.isEmpty)
            .help(L("Speak"))
        } footer: {
            EmptyView()
        }
    }
}

private struct TextPaneCard<Content: View, HeaderActions: View, Footer: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content
    @ViewBuilder let headerActions: HeaderActions
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                headerActions
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Bottom bar

private struct BottomBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            if let error = store.errorMessage, !error.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.callout)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.12))
            }

            HStack(spacing: 12) {
                Toggle(L("Auto-translate"), isOn: $store.autoTranslate)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                if store.isTranslating {
                    Text(L("Translating…"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: store.requestTranslation) {
                    Text(L("Translate"))
                        .frame(minWidth: 76)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(store.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help(L("Translate (⌘↩)"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
