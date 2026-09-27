package com.lives0808.lingoswift.data

import android.app.Application
import android.content.Context
import android.speech.tts.TextToSpeech
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.mlkit.common.MlKitException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Locale

data class TranslatorUiState(
    val sourceText: String = "",
    val targetText: String = "",
    /** `null` means "detect the language automatically". */
    val sourceLanguage: AppLanguage? = AppLanguage.ENGLISH,
    val targetLanguage: AppLanguage = AppLanguage.CHINESE,
    val detectedLanguage: AppLanguage? = null,
    val isTranslating: Boolean = false,
    val isPreparingModel: Boolean = false,
    val error: String? = null,
    val autoTranslate: Boolean = true,
    val autoTranslateDelay: Float = 0.7f,
    val historyLimit: Int = 100,
    val history: List<HistoryItem> = emptyList(),
    val showFirstRunHint: Boolean = true,
) {
    val canTranslate: Boolean get() = sourceText.isNotBlank() && !isTranslating
}

class TranslatorViewModel(application: Application) : AndroidViewModel(application) {

    private val engine = TranslationEngine()
    private val store = HistoryStore(application)

    private val _state = MutableStateFlow(TranslatorUiState())
    val state: StateFlow<TranslatorUiState> = _state.asStateFlow()

    private var autoTranslateJob: Job? = null
    private var translationJob: Job? = null
    private var speaker: TextToSpeech? = null
    private var speakerReady = false

    init {
        _state.update {
            it.copy(
                sourceLanguage = store.sourceLanguageCode
                    ?.let { code -> AppLanguage.fromCode(code) }
                    ?: AppLanguage.ENGLISH,
                targetLanguage = AppLanguage.fromCode(store.targetLanguageCode) ?: AppLanguage.CHINESE,
                autoTranslate = store.autoTranslate,
                autoTranslateDelay = store.autoTranslateDelay,
                historyLimit = store.historyLimit,
                history = store.load(store.historyLimit),
                showFirstRunHint = !store.firstRunHintSeen,
            )
        }
    }

    // Text input ---------------------------------------------------------------

    fun onSourceTextChange(text: String) {
        _state.update { it.copy(sourceText = text) }
        scheduleAutoTranslate()
    }

    fun setSourceLanguage(language: AppLanguage?) {
        store.sourceLanguageCode = language?.code
        _state.update { it.copy(sourceLanguage = language, detectedLanguage = null) }
        scheduleAutoTranslate()
    }

    fun setTargetLanguage(language: AppLanguage) {
        store.targetLanguageCode = language.code
        _state.update { it.copy(targetLanguage = language) }
        scheduleAutoTranslate()
    }

    fun swapLanguages() {
        val current = _state.value
        val detected = current.sourceLanguage ?: AppLanguage.detect(current.sourceText) ?: AppLanguage.ENGLISH
        val newSource = current.targetLanguage
        val newTarget = detected

        if (current.targetText.isBlank()) {
            store.sourceLanguageCode = newSource.code
            store.targetLanguageCode = newTarget.code
            _state.update {
                it.copy(
                    sourceLanguage = newSource,
                    targetLanguage = newTarget,
                    detectedLanguage = null,
                )
            }
        } else {
            store.sourceLanguageCode = newSource.code
            store.targetLanguageCode = newTarget.code
            _state.update {
                it.copy(
                    sourceLanguage = newSource,
                    targetLanguage = newTarget,
                    sourceText = it.targetText,
                    targetText = "",
                    detectedLanguage = null,
                    error = null,
                )
            }
            if (_state.value.autoTranslate) translate()
        }
    }

    fun clear() {
        autoTranslateJob?.cancel()
        translationJob?.cancel()
        _state.update {
            it.copy(
                sourceText = "",
                targetText = "",
                detectedLanguage = null,
                error = null,
                isTranslating = false,
            )
        }
    }

    // Translation --------------------------------------------------------------

    fun translate() {
        val current = _state.value
        val text = current.sourceText.trim()
        if (text.isEmpty()) return

        val source = current.sourceLanguage
            ?: AppLanguage.detect(text)
            ?: AppLanguage.ENGLISH
        val target = current.targetLanguage

        if (source == target) {
            _state.update { it.copy(targetText = text, error = null, detectedLanguage = source) }
            return
        }

        translationJob?.cancel()
        translationJob = viewModelScope.launch {
            _state.update {
                it.copy(isTranslating = true, error = null, detectedLanguage = source)
            }
            try {
                val result = engine.translate(text, source, target)
                _state.update { it.copy(targetText = result, isTranslating = false) }
                val updated = store.add(
                    HistoryItem(
                        sourceText = text,
                        translatedText = result,
                        sourceLanguage = source,
                        targetLanguage = target,
                    ),
                    _state.value.historyLimit,
                )
                _state.update { it.copy(history = updated) }
            } catch (error: Throwable) {
                if (error is kotlinx.coroutines.CancellationException) throw error
                _state.update {
                    it.copy(targetText = "", isTranslating = false, error = describe(error))
                }
            }
        }
    }

    /** Pre-downloads the model for the current pair so translations can be offline. */
    fun downloadModel() {
        val current = _state.value
        val source = current.sourceLanguage ?: AppLanguage.ENGLISH
        val target = current.targetLanguage
        if (source == target) return

        viewModelScope.launch {
            _state.update { it.copy(isPreparingModel = true, error = null) }
            try {
                engine.prepareModel(source, target)
                store.firstRunHintSeen = true
                _state.update { it.copy(isPreparingModel = false, showFirstRunHint = false) }
            } catch (error: Throwable) {
                if (error is kotlinx.coroutines.CancellationException) throw error
                _state.update { it.copy(isPreparingModel = false, error = describe(error)) }
            }
        }
    }

    fun dismissFirstRunHint() {
        store.firstRunHintSeen = true
        _state.update { it.copy(showFirstRunHint = false) }
    }

    private fun scheduleAutoTranslate() {
        autoTranslateJob?.cancel()
        val current = _state.value
        if (!current.autoTranslate) return

        autoTranslateJob = viewModelScope.launch {
            delay((current.autoTranslateDelay * 1000).toLong())
            translate()
        }
    }

    // History ------------------------------------------------------------------

    fun loadHistoryItem(item: HistoryItem) {
        autoTranslateJob?.cancel()
        store.sourceLanguageCode = item.sourceLanguage.code
        store.targetLanguageCode = item.targetLanguage.code
        _state.update {
            it.copy(
                sourceLanguage = item.sourceLanguage,
                targetLanguage = item.targetLanguage,
                sourceText = item.sourceText,
                targetText = item.translatedText,
                detectedLanguage = item.sourceLanguage,
                error = null,
            )
        }
    }

    fun deleteHistoryItem(item: HistoryItem) {
        _state.update { it.copy(history = store.delete(item.id, it.historyLimit)) }
    }

    fun clearHistory() {
        store.clear()
        _state.update { it.copy(history = emptyList()) }
    }

    // Settings -----------------------------------------------------------------

    fun setAutoTranslate(enabled: Boolean) {
        store.autoTranslate = enabled
        _state.update { it.copy(autoTranslate = enabled) }
        if (enabled) scheduleAutoTranslate() else autoTranslateJob?.cancel()
    }

    fun setAutoTranslateDelay(seconds: Float) {
        store.autoTranslateDelay = seconds
        _state.update { it.copy(autoTranslateDelay = seconds) }
    }

    fun setHistoryLimit(limit: Int) {
        val sanitized = limit.coerceIn(20, 1000)
        store.historyLimit = sanitized
        _state.update {
            it.copy(historyLimit = sanitized, history = store.load(sanitized))
        }
    }

    // Speech -------------------------------------------------------------------

    fun speak(text: String, language: AppLanguage) {
        if (text.isBlank()) return
        val context: Context = getApplication()
        val tts = speaker ?: TextToSpeech(context) { status ->
            speakerReady = status == TextToSpeech.SUCCESS
        }.also { speaker = it }
        if (!speakerReady) return

        runCatching { tts.language = Locale.forLanguageTag(language.speechTag) }
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lingoswift")
    }

    override fun onCleared() {
        super.onCleared()
        speaker?.shutdown()
        speaker = null
        engine.close()
    }

    // Errors -------------------------------------------------------------------

    private fun describe(error: Throwable): String {
        val code = (error as? MlKitException)?.errorCode
        return when (code) {
            MlKitException.NETWORK_ISSUE ->
                context.getString(com.lives0808.lingoswift.R.string.error_network)

            MlKitException.NOT_FOUND ->
                context.getString(com.lives0808.lingoswift.R.string.error_model_missing)

            MlKitException.NOT_ENOUGH_SPACE ->
                context.getString(com.lives0808.lingoswift.R.string.error_storage)

            else -> error.localizedMessage
                ?: context.getString(com.lives0808.lingoswift.R.string.error_unknown)
        }
    }

    private val context: Context get() = getApplication()
}
