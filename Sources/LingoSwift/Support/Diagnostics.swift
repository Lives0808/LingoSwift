import Foundation
import Translation

/// Headless diagnostics: `LingoSwift.app/Contents/MacOS/LingoSwift --doctor`.
/// Prints the state of the on-device translation engine and, when the language
/// pack is installed, runs a real translation.
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

        guard #available(macOS 26.0, *) else {
            print("Run a translation in the app to let macOS download the language pack.")
            return
        }

        let status = await availability.status(from: english, to: simplified)
        guard status == .installed else {
            print("The English → Simplified Chinese language pack is not installed yet.")
            print("Open LingoSwift.app, translate something and accept the system download prompt once.")
            print("macOS handles that download in the app; it cannot be triggered headlessly.")
            return
        }

        let session = TranslationSession(installedSource: english, target: simplified)
        do {
            let response = try await session.translate("Hello world! It is a beautiful day.")
            print("  live translation: \"\(response.targetText)\"")
        } catch {
            print("  live translation failed: \(error)")
        }
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
