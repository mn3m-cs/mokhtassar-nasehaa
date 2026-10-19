package com.menemlabs.zaadalthakir

import org.junit.Assert.assertEquals
import org.junit.Test

class CountDoneVibrationTest {
    @Test
    fun beforeAndroid8SendsAPlainDuration() {
        assertEquals(CountDoneRoute.PLAIN, CountDoneVibration.routeFor(25))
    }

    @Test
    fun android8To12GivesTheMediaUsageThroughAudioAttributes() {
        for (sdk in 26..32) {
            assertEquals("API $sdk", CountDoneRoute.AUDIO_ATTRIBUTES, CountDoneVibration.routeFor(sdk))
        }
    }

    @Test
    fun android13AndLaterKeepsVibrationAttributes() {
        for (sdk in listOf(33, 34, 35)) {
            assertEquals("API $sdk", CountDoneRoute.VIBRATION_ATTRIBUTES, CountDoneVibration.routeFor(sdk))
        }
    }
}
