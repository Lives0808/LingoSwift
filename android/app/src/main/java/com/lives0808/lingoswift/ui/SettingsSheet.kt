package com.lives0808.lingoswift.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.lives0808.lingoswift.BuildConfig
import com.lives0808.lingoswift.R
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    autoTranslate: Boolean,
    autoTranslateDelay: Float,
    historyLimit: Int,
    onAutoTranslateChange: (Boolean) -> Unit,
    onDelayChange: (Float) -> Unit,
    onHistoryLimitChange: (Int) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = stringResource(R.string.settings),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )

            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = stringResource(R.string.auto_translate_while_typing),
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.weight(1f),
                )
                Switch(checked = autoTranslate, onCheckedChange = onAutoTranslateChange)
            }

            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = stringResource(R.string.auto_translate_delay),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Spacer(Modifier.weight(1f))
                    Text(
                        text = String.format(Locale.US, "%.1f s", autoTranslateDelay),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Slider(
                    value = autoTranslateDelay,
                    onValueChange = onDelayChange,
                    valueRange = 0.2f..2.0f,
                    steps = 17,
                    enabled = autoTranslate,
                )
            }

            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = stringResource(R.string.history_limit),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Spacer(Modifier.weight(1f))
                    Text(
                        text = historyLimit.toString(),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Slider(
                    value = historyLimit.toFloat(),
                    onValueChange = { onHistoryLimitChange(it.toInt()) },
                    valueRange = 20f..500f,
                    steps = 23,
                )
            }

            HorizontalDivider()

            InfoRow(stringResource(R.string.engine_label), stringResource(R.string.engine_value))
            InfoRow(stringResource(R.string.version_label), BuildConfig.VERSION_NAME)
            InfoRow(stringResource(R.string.privacy_label), stringResource(R.string.privacy_value))

            Spacer(Modifier.width(1.dp))
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.weight(1f))
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}
