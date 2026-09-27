import Foundation

/// The languages LingoSwift can translate between.
enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    /// The name of the language rendered in the language itself, the way macOS does it.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }

    /// The name of the language in the language of the user interface.
    var displayName: String {
        switch self {
        case .english: return L("English")
        case .simplifiedChinese: return L("Simplified Chinese")
        case .traditionalChinese: return L("Traditional Chinese")
        }
    }

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: rawValue)
    }

    /// Language code used by the speech synthesizer.
    var speechCode: String {
        switch self {
        case .english: return "en-US"
        case .simplifiedChinese: return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        }
    }

    init?(identifier: String) {
        let normalized = identifier.lowercased()
        if normalized.hasPrefix("zh") {
            let isTraditional = normalized.contains("hant")
                || normalized.hasSuffix("-tw")
                || normalized.hasSuffix("-hk")
                || normalized.hasSuffix("-mo")
            self = isTraditional ? .traditionalChinese : .simplifiedChinese
        } else if normalized.hasPrefix("en") {
            self = .english
        } else {
            return nil
        }
    }

    init?(localeLanguage: Locale.Language?) {
        guard let maximal = localeLanguage?.maximalIdentifier else { return nil }
        self.init(identifier: maximal)
    }
}
