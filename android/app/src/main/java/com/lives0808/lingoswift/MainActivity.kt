package com.lives0808.lingoswift

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.lives0808.lingoswift.ui.TranslatorScreen
import com.lives0808.lingoswift.ui.theme.LingoSwiftTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            LingoSwiftTheme {
                TranslatorScreen()
            }
        }
    }
}
