import Foundation
import Translation

/// Headless diagnostics: `LingoSwift.app/Contents/MacOS/LingoSwift --doctor`.
/// Prints the app version and the state of the on-device translation language packs.
enum Diagnostics {

    static var isRequested: Bool {
        CommandLine.arguments.contains("--doctor") || CommandLine.arguments.contains("--selftest")
    }

    static func performChecks() async {
        let info = Bundle.main.infoDictionary
        print("LingoSwift doctor")
        print("  bundle id:     \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("  version:       \(info?["CFBundleShortVersionString"] as? String ?? "unknown") (\(info?["CFBundleVersion"] as? String ?? "?"))")
        print("  bundle path:   \(Bundle.main.bundlePath)")
        print("  macOS:         \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("")

        let availability = LanguageAvailability()
        let english = AppLanguage.english.localeLanguage
        let simplified = AppLanguage.simplifiedChinese.localeLanguage
        let traditional = AppLanguage.traditionalChinese.localeLanguage

        let pairs: [(String, Locale.Language, Locale.Language)] = [
            ("en → zh-Hans", english, simplified),
            ("zh-Hans → en", simplified, english),
            ("en → zh-Hant", english, traditional),
        ]

        for (label, source, target) in pairs {
            let status = await availability.status(from: source, to: target)
            print("  \(label): \(describe(status))")
        }

        let supported = await availability.supportedLanguages
        print("  supported languages: \(supported.count)")
        print("")

        // A live translation can only be triggered from the app: it needs the macOS
        // language pack, which is downloaded through a system prompt.
        print("Open LingoSwift.app and translate once to let macOS download the language pack.")
    }

    private static func describe(_ status: LanguageAvailability.Status) -> String {
        switch status {
        case .installed: return "installed"
        case .supported: return "supported (needs download)"
        case .unsupported: return "unsupported"
        @unknown default: return "unknown"
        }
    }
}
