package com.lives0808.lingoswift.data

import com.google.android.gms.tasks.Task
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Thin wrapper around ML Kit's on-device translation.
 *
 * Models are downloaded once per language pair (about 30 MB), after which
 * translation happens entirely on the phone with no network access.
 */
class TranslationEngine {

    private val clients = ConcurrentHashMap<String, Translator>()

    private fun translator(source: AppLanguage, target: AppLanguage): Translator =
        clients.getOrPut(key(source, target)) {
            Translation.getClient(
                TranslatorOptions.Builder()
                    .setSourceLanguage(source.code)
                    .setTargetLanguage(target.code)
                    .build()
            )
        }

    /** Downloads the model for the pair if it is not on the device yet. */
    suspend fun prepareModel(source: AppLanguage, target: AppLanguage) {
        translator(source, target)
            .downloadModelIfNeeded(DownloadConditions.Builder().build())
            .await()
    }

    suspend fun translate(text: String, source: AppLanguage, target: AppLanguage): String {
        val translator = translator(source, target)
        translator.downloadModelIfNeeded(DownloadConditions.Builder().build()).await()
        return translator.translate(text).await()
    }

    fun close() {
        clients.values.forEach { it.close() }
        clients.clear()
    }

    private fun key(source: AppLanguage, target: AppLanguage) = "${source.code}-${target.code}"
}

/** Awaits a Play services [Task] without pulling in the play-services-tasks artifact. */
internal suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { continuation ->
    addOnSuccessListener { result -> if (continuation.isActive) continuation.resume(result) }
    addOnFailureListener { error -> if (continuation.isActive) continuation.resumeWithException(error) }
    addOnCanceledListener { continuation.cancel() }
}
