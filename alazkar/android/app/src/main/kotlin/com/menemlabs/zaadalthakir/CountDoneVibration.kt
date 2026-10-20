package com.menemlabs.zaadalthakir

/** How the end-of-count pulse is sent on each Android version. */
enum class CountDoneRoute {
    /** Before Android 8: a plain duration, which has no usage to follow. */
    PLAIN,

    /** Android 8 to 12: the media usage can only be given through AudioAttributes. */
    AUDIO_ATTRIBUTES,

    /** Android 13 and later: VibrationAttributes with the media usage. */
    VIBRATION_ATTRIBUTES,
}

object CountDoneVibration {
    fun routeFor(sdkInt: Int): CountDoneRoute = when {
        sdkInt >= 33 -> CountDoneRoute.VIBRATION_ATTRIBUTES
        sdkInt >= 26 -> CountDoneRoute.AUDIO_ATTRIBUTES
        else -> CountDoneRoute.PLAIN
    }
}
