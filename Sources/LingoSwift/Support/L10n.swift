import Foundation

/// Looks up a localized string. The key itself is the English text, so builds
/// without a localization bundle (for example `swift run`) still read well.
func L(_ key: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
}

/// Looks up a localized format string and fills in the arguments.
func LF(_ key: String, _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    return String(format: format, locale: .current, arguments: arguments)
}
