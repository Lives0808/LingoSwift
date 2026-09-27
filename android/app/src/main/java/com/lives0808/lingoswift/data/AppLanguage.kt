package com.lives0808.lingoswift.data

/**
 * The languages LingoSwift translates between.
 *
 * ML Kit ships a single Chinese model (`zh`), so there is one Chinese entry rather
 * than separate simplified/traditional variants.
 */
enum class AppLanguage(
    val code: String,
    val label: String,
    val speechTag: String,
) {
    ENGLISH("en", "English", "en-US"),
    CHINESE("zh", "简体中文", "zh-CN"),
    ;

    companion object {
        private val byCode = entries.associateBy { it.code }

        fun fromCode(code: String?): AppLanguage? = code?.let { byCode[it] }

        /**
         * Guesses whether [text] is English or Chinese. LingoSwift only has to resolve
         * this one ambiguity, so counting Han characters is accurate enough and needs
         * no extra model.
         */
        fun detect(text: String): AppLanguage? {
            val trimmed = text.trim()
            val letters = trimmed.count { it.isLetter() }
            if (letters == 0) return null
            val han = trimmed.count { isHan(it) }
            return if (han * 3 >= letters) CHINESE else ENGLISH
        }

        private fun isHan(char: Char): Boolean =
            char.code in 0x4E00..0x9FFF ||
                char.code in 0x3400..0x4DBF ||
                char.code in 0xF900..0xFAFF
    }
}
