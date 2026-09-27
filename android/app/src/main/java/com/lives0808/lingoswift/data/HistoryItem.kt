package com.lives0808.lingoswift.data

import org.json.JSONObject
import java.util.UUID

/** One finished translation, kept in the history sheet. */
data class HistoryItem(
    val id: String = UUID.randomUUID().toString(),
    val sourceText: String,
    val translatedText: String,
    val sourceLanguage: AppLanguage,
    val targetLanguage: AppLanguage,
    val timestamp: Long = System.currentTimeMillis(),
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("sourceText", sourceText)
        put("translatedText", translatedText)
        put("sourceLanguage", sourceLanguage.code)
        put("targetLanguage", targetLanguage.code)
        put("timestamp", timestamp)
    }

    companion object {
        fun fromJson(json: JSONObject): HistoryItem? {
            val sourceText = json.optString("sourceText").takeIf { it.isNotEmpty() } ?: return null
            val translatedText = json.optString("translatedText")
            val source = AppLanguage.fromCode(json.optString("sourceLanguage")) ?: return null
            val target = AppLanguage.fromCode(json.optString("targetLanguage")) ?: return null
            return HistoryItem(
                id = json.optString("id").ifEmpty { UUID.randomUUID().toString() },
                sourceText = sourceText,
                translatedText = translatedText,
                sourceLanguage = source,
                targetLanguage = target,
                timestamp = json.optLong("timestamp", System.currentTimeMillis()),
            )
        }
    }
}
