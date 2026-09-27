import Foundation

/// One finished translation, kept in the history sidebar.
struct HistoryRecord: Identifiable, Codable, Equatable, Sendable {
    var id = UUID()
    var sourceText: String
    var translatedText: String
    var sourceLanguage: AppLanguage
    var targetLanguage: AppLanguage
    var date = Date()
}
