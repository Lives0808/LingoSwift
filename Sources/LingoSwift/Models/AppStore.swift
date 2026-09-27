import AppKit
import AVFoundation
import Foundation
import NaturalLanguage
import SwiftUI
import Translation

/// The single source of truth for the app: language pair, texts, history and settings.
@MainActor
final class AppStore: ObservableObject {

    // MARK: - Published state

    /// `nil` means "detect the language automatically".
    @Published var sourceLanguage: AppLanguage? {
        didSet { defaults.set(sourceLanguage?.rawValue ?? Self.automaticValue, forKey: Key.sourceLanguage) }
    }

    @Published var targetLanguage: AppLanguage {
        didSet { defaults.set(targetLanguage.rawValue, forKey: Key.targetLanguage) }
    }

    @Published var sourceText = ""
    @Published var targetText = ""
    @Published var detectedLanguage: AppLanguage?
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var languagePackStatus: LanguageAvailability.Status?
    @Published var configuration: TranslationSession.Configuration?
    @Published var didCopyTranslation = false

    @Published var autoTranslate: Bool {
        didSet {
            defaults.set(autoTranslate, forKey: Key.autoTranslate)
            if autoTranslate { sourceTextDidChange() }
        }
    }

    @Published var autoTranslateDelay: Double {
        didSet { defaults.set(autoTranslateDelay, forKey: Key.autoTranslateDelay) }
    }

    @Published var historyLimit: Int {
        didSet {
            defaults.set(historyLimit, forKey: Key.historyLimit)
            if history.count > historyLimit {
                history = Array(history.prefix(historyLimit))
            }
        }
    }

    @Published var history: [HistoryRecord] = [] {
        didSet { persistHistory() }
    }

    // MARK: - Private state

    private static let automaticValue = "auto"
    private let defaults: UserDefaults
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var autoTranslateTask: Task<Void, Never>?
    private var copyFeedbackTask: Task<Void, Never>?

    private enum Key {
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let autoTranslate = "autoTranslate"
        static let autoTranslateDelay = "autoTranslateDelay"
        static let historyLimit = "historyLimit"
        static let history = "history"
    }

    // MARK: - Lifecycle

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let storedSource = defaults.string(forKey: Key.sourceLanguage) {
            sourceLanguage = storedSource == Self.automaticValue ? nil : AppLanguage(rawValue: storedSource)
        } else {
            sourceLanguage = .english
        }
        targetLanguage = defaults.string(forKey: Key.targetLanguage)
            .flatMap(AppLanguage.init(rawValue:)) ?? .simplifiedChinese
        autoTranslate = defaults.object(forKey: Key.autoTranslate) as? Bool ?? true
        autoTranslateDelay = defaults.object(forKey: Key.autoTranslateDelay) as? Double ?? 0.7
        historyLimit = defaults.object(forKey: Key.historyLimit) as? Int ?? 100
        history = Self.loadHistory(from: defaults, limit: historyLimit)
    }

    // MARK: - Translation

    /// Asks the translation task to run. Re-invalidating the configuration is the
    /// only way to translate again with the same language pair.
    func requestTranslation() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        errorMessage = nil

        var updated = configuration ?? TranslationSession.Configuration()
        if let source = sourceLanguage ?? Self.detectLanguage(in: text) {
            updated.source = source.localeLanguage
            detectedLanguage = source
        } else {
            updated.source = nil
            detectedLanguage = nil
        }
        updated.target = targetLanguage.localeLanguage
        updated.invalidate()
        configuration = updated
    }

    /// Runs inside the SwiftUI `translationTask` once the configuration is set.
    func translate(using session: TranslationSession) async {
        let text = sourceText
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isTranslating = true
        defer { isTranslating = false }

        do {
            let response = try await session.translate(text)
            guard !Task.isCancelled else { return }

            let source = AppLanguage(localeLanguage: response.sourceLanguage) ?? sourceLanguage ?? .english
            detectedLanguage = source
            targetText = response.targetText
            errorMessage = nil

            addToHistory(
                HistoryRecord(
                    sourceText: text,
                    translatedText: response.targetText,
                    sourceLanguage: source,
                    targetLanguage: targetLanguage
                )
            )
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            targetText = ""
            errorMessage = Self.message(for: error)
        }
    }

    /// Re-checks whether the system language pack for the current pair is installed.
    func refreshLanguagePackStatus() async {
        let source = sourceLanguage
            ?? Self.detectLanguage(in: sourceText)
            ?? .english
        let status = await LanguageAvailability().status(
            from: source.localeLanguage,
            to: targetLanguage.localeLanguage
        )
        guard !Task.isCancelled else { return }
        languagePackStatus = status
    }

    // MARK: - Actions

    func swapLanguages() {
        let newTarget = sourceLanguage ?? Self.detectLanguage(in: sourceText) ?? .english
        let newSource = targetLanguage
        sourceLanguage = newSource
        targetLanguage = newTarget

        if targetText.isEmpty {
            detectedLanguage = nil
        } else {
            sourceText = targetText
            targetText = ""
            detectedLanguage = nil
            if autoTranslate { requestTranslation() }
        }
    }

    func clear() {
        autoTranslateTask?.cancel()
        sourceText = ""
        targetText = ""
        detectedLanguage = nil
        errorMessage = nil
    }

    func copyTranslation() {
        guard !targetText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(targetText, forType: .string)

        didCopyTranslation = true
        copyFeedbackTask?.cancel()
        copyFeedbackTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.didCopyTranslation = false
        }
    }

    func speakSourceText() {
        speak(sourceText, language: sourceLanguage ?? Self.detectLanguage(in: sourceText))
    }

    func speakTranslation() {
        speak(targetText, language: targetLanguage)
    }

    /// Debounced auto-translation used while the user types.
    func sourceTextDidChange() {
        autoTranslateTask?.cancel()
        guard autoTranslate else { return }

        let delay = autoTranslateDelay
        autoTranslateTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.requestTranslation()
        }
    }

    // MARK: - History

    func addToHistory(_ record: HistoryRecord) {
        var updated = history
        updated.removeAll {
            $0.sourceText == record.sourceText
                && $0.translatedText == record.translatedText
                && $0.targetLanguage == record.targetLanguage
        }
        updated.insert(record, at: 0)
        if updated.count > historyLimit {
            updated = Array(updated.prefix(historyLimit))
        }
        history = updated
    }

    func deleteHistory(_ record: HistoryRecord) {
        history.removeAll { $0.id == record.id }
    }

    func clearHistory() {
        history = []
    }

    func loadIntoEditor(_ record: HistoryRecord) {
        autoTranslateTask?.cancel()
        sourceLanguage = record.sourceLanguage
        targetLanguage = record.targetLanguage
        sourceText = record.sourceText
        targetText = record.translatedText
        detectedLanguage = record.sourceLanguage
        errorMessage = nil
    }

    func resetEverything() {
        autoTranslate = true
        autoTranslateDelay = 0.7
        historyLimit = 100
        sourceLanguage = .english
        targetLanguage = .simplifiedChinese
        clear()
    }

    // MARK: - Language detection

    /// Detects English or Chinese from the given text using NaturalLanguage.
    static func detectLanguage(in text: String) -> AppLanguage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        if let dominant = recognizer.dominantLanguage {
            if let language = AppLanguage(identifier: dominant.rawValue) {
                return language
            }
        }

        // Fall back to a simple script check when the recognizer is not confident.
        let hanCount = trimmed.unicodeScalars.filter { (0x4E00...0x9FFF).contains($0.value) }.count
        if hanCount * 4 > trimmed.unicodeScalars.count * 3 {
            return .simplifiedChinese
        }
        return nil
    }

    // MARK: - Helpers

    static func message(for error: Error) -> String {
        // `TranslationError.alreadyCancelled` and `.notInstalled` only exist in the
        // macOS 26 SDK, so match those causes by name to stay compatible with the
        // macOS 15 SDK used by older toolchains.
        switch causeName(of: error) {
        case "alreadyCancelled":
            return ""
        case "notInstalled":
            return L("The language pack is not installed yet. Download it when the system asks, then translate again.")
        default:
            break
        }

        if TranslationError.unsupportedLanguagePairing ~= error {
            return L("This language pair is not supported.")
        }
        if TranslationError.unsupportedSourceLanguage ~= error {
            return L("The source language is not supported.")
        }
        if TranslationError.unsupportedTargetLanguage ~= error {
            return L("The target language is not supported.")
        }
        if TranslationError.unableToIdentifyLanguage ~= error {
            return L("LingoSwift could not tell which language the text is in.")
        }
        if TranslationError.nothingToTranslate ~= error {
            return L("There is nothing to translate.")
        }
        if TranslationError.internalError ~= error {
            return L("The translation service hit an internal error. Please try again.")
        }
        return error.localizedDescription
    }

    /// Extracts the cause name from a `TranslationError`, for example `notInstalled`.
    /// Used for causes that older SDKs do not expose as static members.
    private static func causeName(of error: Error) -> String? {
        let description = String(describing: error)
        guard let range = description.range(of: "Cause.") else { return nil }
        let name = description[range.upperBound...].prefix { $0.isLetter || $0.isNumber }
        return name.isEmpty ? nil : String(name)
    }

    private func speak(_ text: String, language: AppLanguage?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: trimmed)
        if let language, let voice = AVSpeechSynthesisVoice(language: language.speechCode) {
            utterance.voice = voice
        }
        speechSynthesizer.speak(utterance)
    }

    private func persistHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: Key.history)
    }

    private static func loadHistory(from defaults: UserDefaults, limit: Int) -> [HistoryRecord] {
        guard let data = defaults.data(forKey: Key.history),
              let records = try? JSONDecoder().decode([HistoryRecord].self, from: data) else {
            return []
        }
        return Array(records.prefix(max(limit, 1)))
    }
}
