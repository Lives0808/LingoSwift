package com.lives0808.lingoswift

import com.lives0808.lingoswift.data.AppLanguage
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AppLanguageTest {

    @Test
    fun detectsEnglishText() {
        assertEquals(
            AppLanguage.ENGLISH,
            AppLanguage.detect("Hello world, how are you doing today?"),
        )
    }

    @Test
    fun detectsChineseText() {
        assertEquals(
            AppLanguage.CHINESE,
            AppLanguage.detect("今天天气很好，我们去公园散步吧。"),
        )
    }

    @Test
    fun detectsChineseWhenHanDominatesMixedText() {
        assertEquals(
            AppLanguage.CHINESE,
            AppLanguage.detect("请把这句话翻译成 English 试试看"),
        )
    }

    @Test
    fun returnsNullForNonLetters() {
        assertNull(AppLanguage.detect("1234 ?! --- "))
        assertNull(AppLanguage.detect("   "))
    }

    @Test
    fun resolvesLanguageCodes() {
        assertEquals(AppLanguage.CHINESE, AppLanguage.fromCode("zh"))
        assertEquals(AppLanguage.ENGLISH, AppLanguage.fromCode("en"))
        assertNull(AppLanguage.fromCode("fr"))
        assertNull(AppLanguage.fromCode(null))
    }
}
