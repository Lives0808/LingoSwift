package com.lives0808.lingoswift.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val BrandBlue = Color(0xFF4C6FFF)
private val BrandPurple = Color(0xFF8A3FFC)

private val LightColors = lightColorScheme(
    primary = BrandBlue,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDDE4FF),
    onPrimaryContainer = Color(0xFF00164E),
    secondary = BrandPurple,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFE9DDFF),
    onSecondaryContainer = Color(0xFF22005D),
    surfaceVariant = Color(0xFFE1E2EC),
    onSurfaceVariant = Color(0xFF44464F),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFB6C4FF),
    onPrimary = Color(0xFF00277E),
    primaryContainer = Color(0xFF0E3EA8),
    onPrimaryContainer = Color(0xFFDDE4FF),
    secondary = Color(0xFFCFBCFF),
    onSecondary = Color(0xFF3A0092),
    secondaryContainer = Color(0xFF52279B),
    onSecondaryContainer = Color(0xFFE9DDFF),
    surfaceVariant = Color(0xFF44464F),
    onSurfaceVariant = Color(0xFFC5C6D0),
)

@Composable
fun LingoSwiftTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColors
        else -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content,
    )
}
