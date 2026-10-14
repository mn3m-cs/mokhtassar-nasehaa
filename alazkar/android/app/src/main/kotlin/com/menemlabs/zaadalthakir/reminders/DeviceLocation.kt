package com.menemlabs.zaadalthakir.reminders

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal

/** The approximate location, read once when the reader asks for it. */
object DeviceLocation {
    @SuppressLint("MissingPermission")
    fun read(context: Context, onResult: (Location?) -> Unit) {
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.PASSIVE_PROVIDER)
        }.filter { it in manager.allProviders && manager.isProviderEnabled(it) }
        val last = providers
            .mapNotNull { runCatching { manager.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
        if (last != null) {
            onResult(last)
            return
        }
        val live = providers.firstOrNull { it != LocationManager.PASSIVE_PROVIDER }
        if (live == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            onResult(null)
            return
        }
        try {
            manager.getCurrentLocation(live, CancellationSignal(), context.mainExecutor) { onResult(it) }
        } catch (e: SecurityException) {
            onResult(null)
        }
    }
}
