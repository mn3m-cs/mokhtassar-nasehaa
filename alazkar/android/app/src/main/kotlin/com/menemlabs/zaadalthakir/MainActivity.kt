package com.menemlabs.zaadalthakir


import io.flutter.embedding.android.FlutterActivity
import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import com.menemlabs.zaadalthakir.reminders.ReminderNotifier
import com.menemlabs.zaadalthakir.reminders.ReminderScheduler
import com.menemlabs.zaadalthakir.reminders.ReminderStore
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
                        ReminderStore.save(this, ReminderStore.fromMaps(maps))
                        ReminderScheduler.scheduleNext(this)
                        result.success(null)
                    }
                    "notificationsAllowed" -> result.success(notificationsAllowed())
                    "requestNotificationPermission" -> requestNotificationPermission(result)
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




    private fun notificationsAllowed(): Boolean =
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(notificationsAllowed())
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        pendingPermissionResult?.success(
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        )
        pendingPermissionResult = null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        titleIdFrom(intent)?.let { reminderChannel?.invokeMethod("openTitle", it) }
    }

    private fun titleIdFrom(intent: Intent?): Int? =
        intent?.getIntExtra(ReminderNotifier.EXTRA_TITLE_ID, -1)?.takeIf { it > 0 }

    companion object {
        private const val REQUEST_NOTIFICATIONS = 4101
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
