package com.lives0808.lingoswift.data

import android.content.Context
import org.json.JSONArray

/** Local persistence for history and settings. Nothing ever leaves the device. */
class HistoryStore(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun load(limit: Int): List<HistoryItem> {
        val raw = prefs.getString(KEY_HISTORY, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    array.optJSONObject(index)?.let { HistoryItem.fromJson(it) }?.let(::add)
                }
            }
        }.getOrDefault(emptyList()).take(limit.coerceAtLeast(1))
    }

    fun add(item: HistoryItem, limit: Int): List<HistoryItem> {
        val updated = load(Int.MAX_VALUE)
            .filterNot {
                it.sourceText == item.sourceText &&
                    it.translatedText == item.translatedText &&
                    it.targetLanguage == item.targetLanguage
            }
            .toMutableList()
            .apply { add(0, item) }
            .take(limit.coerceAtLeast(1))
        persist(updated)
        return updated
    }

    fun delete(id: String, limit: Int): List<HistoryItem> {
        val updated = load(Int.MAX_VALUE).filterNot { it.id == id }.take(limit.coerceAtLeast(1))
        persist(updated)
        return updated
    }

    fun clear() {
        prefs.edit().remove(KEY_HISTORY).apply()
    }

    private fun persist(items: List<HistoryItem>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        prefs.edit().putString(KEY_HISTORY, array.toString()).apply()
    }

    // Settings -----------------------------------------------------------------

    var sourceLanguageCode: String?
        get() = prefs.getString(KEY_SOURCE_LANGUAGE, null)
        set(value) = prefs.edit().putString(KEY_SOURCE_LANGUAGE, value).apply()

    var targetLanguageCode: String?
        get() = prefs.getString(KEY_TARGET_LANGUAGE, null)
        set(value) = prefs.edit().putString(KEY_TARGET_LANGUAGE, value).apply()

    var autoTranslate: Boolean
        get() = prefs.getBoolean(KEY_AUTO_TRANSLATE, true)
        set(value) = prefs.edit().putBoolean(KEY_AUTO_TRANSLATE, value).apply()

    var autoTranslateDelay: Float
        get() = prefs.getFloat(KEY_AUTO_DELAY, 0.7f)
        set(value) = prefs.edit().putFloat(KEY_AUTO_DELAY, value).apply()

    var historyLimit: Int
        get() = prefs.getInt(KEY_HISTORY_LIMIT, 100)
        set(value) = prefs.edit().putInt(KEY_HISTORY_LIMIT, value).apply()

    var firstRunHintSeen: Boolean
        get() = prefs.getBoolean(KEY_HINT_SEEN, false)
        set(value) = prefs.edit().putBoolean(KEY_HINT_SEEN, value).apply()

    private companion object {
        const val PREFS_NAME = "lingoswift"
        const val KEY_HISTORY = "history"
        const val KEY_SOURCE_LANGUAGE = "sourceLanguage"
        const val KEY_TARGET_LANGUAGE = "targetLanguage"
        const val KEY_AUTO_TRANSLATE = "autoTranslate"
        const val KEY_AUTO_DELAY = "autoTranslateDelay"
        const val KEY_HISTORY_LIMIT = "historyLimit"
        const val KEY_HINT_SEEN = "firstRunHintSeen"
    }
}
