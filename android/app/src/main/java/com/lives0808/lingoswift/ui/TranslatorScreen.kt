package com.lives0808.lingoswift.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.lives0808.lingoswift.R
import com.lives0808.lingoswift.data.AppLanguage
import com.lives0808.lingoswift.data.HistoryItem
import com.lives0808.lingoswift.data.TranslatorUiState
import com.lives0808.lingoswift.data.TranslatorViewModel
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TranslatorScreen(viewModel: TranslatorViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showHistory by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.app_name),
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                actions = {
                    IconButton(onClick = { showHistory = true }) {
                        Icon(Icons.Outlined.History, contentDescription = stringResource(R.string.history))
                    }
                    IconButton(onClick = { showSettings = true }) {
                        Icon(Icons.Outlined.Settings, contentDescription = stringResource(R.string.settings))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                ),
            )
        },
        bottomBar = {
            BottomBar(
                state = state,
                onTranslate = viewModel::translate,
                onAutoTranslateChange = viewModel::setAutoTranslate,
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            LanguageBar(
                state = state,
                onSource = viewModel::setSourceLanguage,
                onTarget = viewModel::setTargetLanguage,
                onSwap = viewModel::swapLanguages,
            )

            if (state.showFirstRunHint) {
                FirstRunHint(
                    isPreparing = state.isPreparingModel,
                    onDownload = viewModel::downloadModel,
                    onDismiss = viewModel::dismissFirstRunHint,
                )
            }

            SourceCard(
                state = state,
                onTextChange = viewModel::onSourceTextChange,
                onClear = viewModel::clear,
                onSpeak = { viewModel.speak(state.sourceText, state.sourceLanguage ?: state.detectedLanguage ?: AppLanguage.ENGLISH) },
            )

            ResultCard(
                state = state,
                onSpeak = { viewModel.speak(state.targetText, state.targetLanguage) },
            )

            state.error?.let { message ->
                ErrorCard(message)
            }

            Spacer(Modifier.size(4.dp))
        }
    }

    if (showHistory) {
        HistorySheet(
            history = state.history,
            onDismiss = { showHistory = false },
            onSelect = {
                viewModel.loadHistoryItem(it)
                showHistory = false
            },
            onDelete = viewModel::deleteHistoryItem,
            onClear = viewModel::clearHistory,
        )
    }

    if (showSettings) {
        SettingsSheet(
            autoTranslate = state.autoTranslate,
            autoTranslateDelay = state.autoTranslateDelay,
            historyLimit = state.historyLimit,
            onAutoTranslateChange = viewModel::setAutoTranslate,
            onDelayChange = viewModel::setAutoTranslateDelay,
            onHistoryLimitChange = viewModel::setHistoryLimit,
            onDismiss = { showSettings = false },
        )
    }
}

@Composable
private fun LanguageBar(
    state: TranslatorUiState,
    onSource: (AppLanguage?) -> Unit,
    onTarget: (AppLanguage) -> Unit,
    onSwap: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        LanguageChip(
            label = state.sourceLanguage?.label ?: stringResource(R.string.detect_language),
            current = state.sourceLanguage,
            includeAuto = true,
            onSelect = onSource,
        )

        IconButton(onClick = onSwap) {
            Icon(
                Icons.Outlined.SwapHoriz,
                contentDescription = stringResource(R.string.swap_languages),
            )
        }

        LanguageChip(
            label = state.targetLanguage.label,
            current = state.targetLanguage,
            includeAuto = false,
            onSelect = { language -> language?.let(onTarget) },
        )

        Spacer(Modifier.weight(1f))

        if (state.sourceLanguage == null && state.detectedLanguage != null && state.sourceText.isNotBlank()) {
            Text(
                text = stringResource(R.string.detected, state.detectedLanguage.label),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun LanguageChip(
    label: String,
    current: AppLanguage?,
    includeAuto: Boolean,
    onSelect: (AppLanguage?) -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }

    Box {
        AssistChip(
            onClick = { expanded = true },
            label = { Text(label) },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            if (includeAuto) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.detect_language)) },
                    trailingIcon = {
                        if (current == null) {
                            Icon(Icons.Outlined.Check, contentDescription = null)
                        }
                    },
                    onClick = {
                        expanded = false
                        onSelect(null)
                    },
                )
            }
            AppLanguage.entries.forEach { language ->
                DropdownMenuItem(
                    text = { Text(language.label) },
                    trailingIcon = {
                        if (current == language) {
                            Icon(Icons.Outlined.Check, contentDescription = null)
                        }
                    },
                    onClick = {
                        expanded = false
                        onSelect(language)
                    },
                )
            }
        }
    }
}

@Composable
private fun FirstRunHint(
    isPreparing: Boolean,
    onDownload: () -> Unit,
    onDismiss: () -> Unit,
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer,
        ),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = stringResource(R.string.first_run_title),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
            Text(
                text = stringResource(R.string.first_run_body),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSecondaryContainer,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Button(onClick = onDownload, enabled = !isPreparing) {
                    if (isPreparing) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp,
                            color = MaterialTheme.colorScheme.onPrimary,
                        )
                        Spacer(Modifier.width(8.dp))
                    } else {
                        Icon(Icons.Outlined.Download, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                    }
                    Text(
                        text = if (isPreparing) {
                            stringResource(R.string.downloading_model)
                        } else {
                            stringResource(R.string.download_model)
                        }
                    )
                }
                Spacer(Modifier.width(8.dp))
                TextButton(onClick = onDismiss, enabled = !isPreparing) {
                    Text(stringResource(R.string.not_now))
                }
            }
        }
    }
}

@Composable
private fun SourceCard(
    state: TranslatorUiState,
    onTextChange: (String) -> Unit,
    onClear: () -> Unit,
    onSpeak: () -> Unit,
) {
    Card {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.source),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = stringResource(R.string.characters, state.sourceText.length),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                IconButton(onClick = onSpeak, enabled = state.sourceText.isNotBlank()) {
                    Icon(Icons.AutoMirrored.Outlined.VolumeUp, contentDescription = stringResource(R.string.speak))
                }
                IconButton(
                    onClick = onClear,
                    enabled = state.sourceText.isNotBlank() || state.targetText.isNotBlank(),
                ) {
                    Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.clear))
                }
            }

            OutlinedTextField(
                value = state.sourceText,
                onValueChange = onTextChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 140.dp),
                placeholder = { Text(stringResource(R.string.source_placeholder)) },
                shape = MaterialTheme.shapes.medium,
            )
        }
    }
}

@Composable
private fun ResultCard(
    state: TranslatorUiState,
    onSpeak: () -> Unit,
) {
    val clipboard = LocalClipboardManager.current
    var copied by remember { mutableStateOf(false) }

    LaunchedEffect(copied) {
        if (copied) {
            delay(1500)
            copied = false
        }
    }

    Card {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.translation),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(Modifier.weight(1f))
                if (state.isTranslating) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp,
                    )
                    Spacer(Modifier.width(4.dp))
                }
                IconButton(onClick = onSpeak, enabled = state.targetText.isNotBlank()) {
                    Icon(Icons.AutoMirrored.Outlined.VolumeUp, contentDescription = stringResource(R.string.speak))
                }
                IconButton(
                    onClick = {
                        clipboard.setText(AnnotatedString(state.targetText))
                        copied = true
                    },
                    enabled = state.targetText.isNotBlank(),
                ) {
                    Icon(
                        imageVector = if (copied) Icons.Outlined.Check else Icons.Outlined.ContentCopy,
                        contentDescription = stringResource(R.string.copy),
                    )
                }
            }

            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 140.dp),
                shape = MaterialTheme.shapes.medium,
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f),
            ) {
                Text(
                    text = state.targetText.ifBlank {
                        if (state.isTranslating) {
                            stringResource(R.string.translating)
                        } else {
                            stringResource(R.string.translation_placeholder)
                        }
                    },
                    modifier = Modifier.padding(12.dp),
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (state.targetText.isBlank()) {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    } else {
                        MaterialTheme.colorScheme.onSurface
                    },
                )
            }
        }
    }
}

@Composable
private fun ErrorCard(message: String) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer,
        ),
    ) {
        Text(
            text = message,
            modifier = Modifier.padding(14.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onErrorContainer,
        )
    }
}

@Composable
private fun BottomBar(
    state: TranslatorUiState,
    onTranslate: () -> Unit,
    onAutoTranslateChange: (Boolean) -> Unit,
) {
    Surface(tonalElevation = 3.dp) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Switch(
                checked = state.autoTranslate,
                onCheckedChange = onAutoTranslateChange,
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = stringResource(R.string.auto_translate),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.selectable(
                    selected = state.autoTranslate,
                    onClick = { onAutoTranslateChange(!state.autoTranslate) },
                ),
            )

            Spacer(Modifier.weight(1f))

            Button(onClick = onTranslate, enabled = state.canTranslate) {
                Text(stringResource(R.string.translate))
            }
        }
    }
}
