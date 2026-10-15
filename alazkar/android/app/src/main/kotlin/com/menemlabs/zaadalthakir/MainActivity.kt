package com.menemlabs.zaadalthakir


import io.flutter.embedding.android.FlutterActivity
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import com.menemlabs.zaadalthakir.reminders.ReminderNotifier
import com.menemlabs.zaadalthakir.reminders.ReminderScheduler
import com.menemlabs.zaadalthakir.reminders.ReminderStore
import com.menemlabs.zaadalthakir.reminders.DeviceLocation
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.KeyEvent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
     private lateinit var channel: MethodChannel
     private var activateVolumeDispatch:Boolean = false
    private var reminderChannel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var launchTitleId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "volume_button_channel")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "activate_volumeBtn") {
                activateVolumeDispatch = call.arguments as Boolean
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vibration_channel")
            .setMethodCallHandler { call, result ->
                if (call.method == "count_done") {
                    vibrateCountDone()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        launchTitleId = titleIdFrom(intent)
        reminderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "reminder_channel").also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        @Suppress("UNCHECKED_CAST")
                        val maps = call.arguments as List<Map<String, Any?>>
                        ReminderScheduler.replace(this, ReminderStore.fromMaps(maps))
                        result.success(null)
                    }
                    "notificationsAllowed" -> result.success(notificationsAllowed())
                    "requestNotificationPermission" -> requestNotificationPermission(result)
            "openAppSettings" -> {
                startActivity(
                    Intent(
                        android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        android.net.Uri.fromParts("package", packageName, null),
                    )
                )
                result.success(null)
            }
                    "requestLocation" -> requestLocation(result)
                    "takeLaunchTitleId" -> {
                        result.success(launchTitleId)
                        launchTitleId = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun vibrateCountDone() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return
        val pattern = longArrayOf(0, 90, 110, 90)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }




    /** False also when the reader muted the reminders' own channel. */
    private fun notificationsAllowed(): Boolean {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (!manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        val channel = manager.getNotificationChannel(ReminderNotifier.CHANNEL_ID) ?: return true
        return channel.importance != NotificationManager.IMPORTANCE_NONE
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(notificationsAllowed())
            return
        }
        // A second request while the dialog is up answers the first, so its
        // caller is not left waiting forever.
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    private fun requestLocation(result: MethodChannel.Result) {
        if (checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            readLocation(result)
            return
        }
        pendingLocationResult?.success(null)
        pendingLocationResult = result
        requestPermissions(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), REQUEST_LOCATION)
    }

    private fun readLocation(result: MethodChannel.Result) {
        DeviceLocation.read(this) { location ->
            result.success(location?.let { mapOf("latitude" to it.latitude, "longitude" to it.longitude) })
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        when (requestCode) {
            REQUEST_NOTIFICATIONS -> {
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            }
            REQUEST_LOCATION -> {
                val result = pendingLocationResult ?: return
                pendingLocationResult = null
                if (granted) readLocation(result) else result.success(null)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        titleIdFrom(intent)?.let { reminderChannel?.invokeMethod("openTitle", it) }
    }

    /**
     * The section a tapped notification asks for. Reopening the app from
     * Recents replays the notification's intent with the history flag; that
     * is not a new tap, so it opens nothing.
     */
    private fun titleIdFrom(intent: Intent?): Int? {
        if (intent == null) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        return intent.getIntExtra(ReminderNotifier.EXTRA_TITLE_ID, -1).takeIf { it > 0 }
    }

    companion object {
        private const val REQUEST_NOTIFICATIONS = 4101
        private const val REQUEST_LOCATION = 4102
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val action: Int = event.getAction()
        val keyCode: Int = event.getKeyCode()
        if (!activateVolumeDispatch){
           return super.dispatchKeyEvent(event)
        }
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                if (action == KeyEvent.ACTION_DOWN) {
                    channel.invokeMethod("volumeBtnPressed", "VOLUME_UP_DOWN")
                } else if (action == KeyEvent.ACTION_UP) {
                    channel.invokeMethod("volumeBtnPressed", "VOLUME_UP_UP")
                }
                true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (action == KeyEvent.ACTION_DOWN) {
                    channel.invokeMethod("volumeBtnPressed", "VOLUME_DOWN_DOWN")
                } else if (action == KeyEvent.ACTION_UP) {
                    channel.invokeMethod("volumeBtnPressed", "VOLUME_DOWN_UP")
                }
                true
            }

            else -> super.dispatchKeyEvent(event)
        }
    }
}
